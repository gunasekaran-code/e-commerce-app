from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import User, Product, Cart, CartItem
from .serializers import UserSerializer, ProductSerializer
import logging

logger = logging.getLogger(__name__)

# GET all users
@api_view(['GET'])
def get_users(request):
    # ... rest of your code stays the same
    users = User.objects.all()
    serializer = UserSerializer(users, many=True)
    return Response(serializer.data)

# GET single user
@api_view(['GET'])
def get_user(request, pk):
    try:
        user = User.objects.get(pk=pk)
        serializer = UserSerializer(user)
        return Response(serializer.data)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

# POST - Create user (Register)
@api_view(['POST'])
def create_user(request):
    serializer = UserSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# PUT - Update full user
@api_view(['PUT'])
def update_user(request, pk):
    try:
        user = User.objects.get(pk=pk)
        serializer = UserSerializer(user, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

# PATCH - Partial update
@api_view(['PATCH'])
def partial_update_user(request, pk):
    try:
        user = User.objects.get(pk=pk)
        serializer = UserSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

# DELETE user
@api_view(['DELETE'])
def delete_user(request, pk):
    try:
        user = User.objects.get(pk=pk)
        user.delete()
        return Response({'message': 'User deleted successfully'}, status=status.HTTP_204_NO_CONTENT)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
def login_user(request):
    print("=== LOGIN VIEW CALLED ===")  # ← add this
    email = request.data.get('email', '').strip()
    password = request.data.get('password', '').strip()

    print(f"DEBUG email: '{email}'")
    print(f"DEBUG password: '{password}'")

    try:
        user = User.objects.get(email__iexact=email)
    except User.DoesNotExist:
        return Response(
            {'error': 'Email not registered. Please register first.'},
            status=status.HTTP_401_UNAUTHORIZED
        )

    if user.password != password:
        return Response(
            {'error': 'Incorrect password. Please try again.'},
            status=status.HTTP_401_UNAUTHORIZED
        )

    serializer = UserSerializer(user)
    return Response({
        'message': 'Login successful',
        'user': serializer.data,
        'is_admin': user.is_admin
    }, status=status.HTTP_200_OK)


# ============= PRODUCT VIEWS =============

@api_view(['GET'])
def get_products(request):
    """Get all active products (del_flag=False)"""
    products = Product.objects.filter(del_flag=False)
    
    # Optional filtering
    category = request.GET.get('category')
    if category:
        products = products.filter(category=category)
    
    serializer = ProductSerializer(products, many=True)
    return Response(serializer.data)


@api_view(['GET'])
def get_all_products_admin(request):
    """Admin: Get ALL products including soft-deleted ones"""
    products = Product.objects.all()
    serializer = ProductSerializer(products, many=True)
    return Response(serializer.data)


@api_view(['GET'])
def get_product_detail(request, pk):
    """Get single product details"""
    try:
        product = Product.objects.get(pk=pk, del_flag=False)
        serializer = ProductSerializer(product)
        return Response(serializer.data)
    except Product.DoesNotExist:
        return Response(
            {'error': 'Product not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['POST'])
def create_product(request):
    """Admin: Create new product"""
    if request.method == 'POST':
        # Handle both regular POST and multipart form data
        data = request.data.copy()
        
        # Handle file upload
        if 'image' in request.FILES:
            image_file = request.FILES['image']
            # Save the image file and get the URL
            # For now, we'll save it to media directory
            import os
            from django.conf import settings
            from django.core.files.storage import default_storage
            
            # Create filename
            ext = os.path.splitext(image_file.name)[1]
            filename = f"products/{data.get('name', 'product').replace(' ', '_')}_{data.get('sku_id', 'no_sku')}{ext}"
            
            # Save file
            file_path = default_storage.save(filename, image_file)
            image_url = default_storage.url(file_path)
            if not image_url.startswith('http'):
                image_url = request.build_absolute_uri(image_url)
            data['image_url'] = image_url
        
        serializer = ProductSerializer(data=data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['PUT'])
def update_product(request, pk):
    """Admin: Update product"""
    try:
        product = Product.objects.get(pk=pk)
        
        # Handle both regular PUT and multipart form data
        data = request.data.copy()
        
        # Handle file upload
        if 'image' in request.FILES:
            image_file = request.FILES['image']
            # Save the image file and get the URL
            import os
            from django.conf import settings
            from django.core.files.storage import default_storage
            
            # Create filename
            ext = os.path.splitext(image_file.name)[1]
            filename = f"products/{data.get('name', product.name).replace(' ', '_')}_{data.get('sku_id', 'no_sku')}{ext}"
            
            # Save file
            file_path = default_storage.save(filename, image_file)
            image_url = default_storage.url(file_path)
            if not image_url.startswith('http'):
                image_url = request.build_absolute_uri(image_url)
            data['image_url'] = image_url
        
        serializer = ProductSerializer(product, data=data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except Product.DoesNotExist:
        return Response(
            {'error': 'Product not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['DELETE'])
def soft_delete_product(request, pk):
    """Admin: Soft delete product (set del_flag=True)"""
    try:
        product = Product.objects.get(pk=pk)
        product.del_flag = True
        product.save()
        return Response(
            {'message': 'Product soft deleted successfully'}, 
            status=status.HTTP_200_OK
        )
    except Product.DoesNotExist:
        return Response(
            {'error': 'Product not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['POST'])
def restore_product(request, pk):
    """Admin: Restore soft-deleted product"""
    try:
        product = Product.objects.get(pk=pk)
        product.del_flag = False
        product.save()
        return Response(
            {'message': 'Product restored successfully'}, 
            status=status.HTTP_200_OK
        )
    except Product.DoesNotExist:
        return Response(
            {'error': 'Product not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['DELETE'])
def hard_delete_product(request, pk):
    """Admin: Permanently delete product"""
    try:
        product = Product.objects.get(pk=pk)
        product.delete()
        return Response(
            {'message': 'Product permanently deleted'}, 
            status=status.HTTP_204_NO_CONTENT
        )
    except Product.DoesNotExist:
        return Response(
            {'error': 'Product not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )
    
@api_view(['POST'])
def add_to_cart(request):
    logger.info(f"Request data: {request.data}")
    
    user_id = request.data.get('user_id')
    product_id = request.data.get('product_id')
    quantity = request.data.get('quantity', 1)
    
    logger.info(f"user_id: {user_id}, product_id: {product_id}, quantity: {quantity}")
    
    try:
        user = User.objects.get(id=user_id)
        product = Product.objects.get(id=product_id)
        logger.info(f"Found user: {user.id}, product: {product.id}")
        
        cart, created = Cart.objects.get_or_create(user=user)
        logger.info(f"Cart: {cart.id}, created: {created}")
        
        # FIXED: Removed products_sku_id - just use product ForeignKey
        item, created = CartItem.objects.get_or_create(
            cart=cart,
            product=product,
            defaults={'quantity': quantity}
        )
        
        if not created:
            item.quantity += quantity
            item.save()
            logger.info(f"Updated item quantity to: {item.quantity}")
        else:
            logger.info("New cart item created")
        
        logger.info("Product added to cart successfully")
        return Response({"message": "Product added to cart successfully"})
    
    except User.DoesNotExist:
        logger.error(f"User not found: {user_id}")
        return Response({"error": "User not found"}, status=404)
    except Product.DoesNotExist:
        logger.error(f"Product not found: {product_id}")
        return Response({"error": "Product not found"}, status=404)
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return Response({"error": str(e)}, status=500)


@api_view(['GET'])
def get_cart(request, user_id):

    cart = Cart.objects.filter(user_id=user_id).first()

    if not cart:
        return Response([])

    items = CartItem.objects.filter(cart=cart)

    data = []

    for item in items:
        data.append({
            "id": item.id,
            "product_name": item.product.name,
            "price": item.product.price,
            "quantity": item.quantity,
            "image": item.product.image_url
        })

    return Response(data)



@api_view(['POST'])
def google_auth(request):
    """
    Authenticate user with Google ID token
    """
    token = request.data.get('token')
    
    if not token:
        return Response(
            {'error': 'Token is required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        # Verify Google token
        idinfo = id_token.verify_oauth2_token(
            token,
            requests.Request(),
            settings.GOOGLE_OAUTH_CLIENT_ID
        )
        
        # Get user info from token
        email = idinfo['email']
        first_name = idinfo.get('given_name', '')
        last_name = idinfo.get('family_name', '')
        
        # Get or create user
        user, created = User.objects.get_or_create(
            email=email,
            defaults={
                'username': email,
                'first_name': first_name,
                'last_name': last_name,
            }
        )
        
        # Create or get auth token
        auth_token, _ = Token.objects.get_or_create(user=user)
        
        return Response({
            'token': auth_token.key,
            'user': {
                'id': user.id,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'is_new': created,
            }
        }, status=status.HTTP_200_OK)
        
    except ValueError as e:
        # Invalid token
        return Response(
            {'error': 'Invalid token'},
            status=status.HTTP_401_UNAUTHORIZED
        )
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )