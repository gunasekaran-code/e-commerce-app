import os
import random
import logging
from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.db import IntegrityError
from django.db.models import Q
from django.db.utils import OperationalError, ProgrammingError
from .models import User, Product, Cart, CartItem, Wishlist, WishlistItem, Category
from .serializers import UserSerializer, ProductSerializer, WishlistSerializer, WishlistItemSerializer, CategorySerializer
from django.contrib.auth.hashers import make_password, check_password

logger = logging.getLogger(__name__)


def _schema_error_response(resource_name):
    return Response(
        {
            'error': f'{resource_name} database is not ready on the server. '
                     'Commit migrations, redeploy, and run `python manage.py migrate` on Render.'
        },
        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
    )


def _normalize_category_value(value):
    return value.strip().lower().replace('_', ' ').replace('-', ' ')

# ================= CATEGORY APIs =================

@api_view(['GET'])
def get_categories(request):
    try:
        categories = Category.objects.filter(is_active=True)
        serializer = CategorySerializer(categories, many=True)
        return Response(serializer.data)
    except (OperationalError, ProgrammingError):
        logger.exception("Category table is unavailable. Run migrations on the deployed server.")
        return _schema_error_response('Category')
    except Exception:
        logger.exception("Unexpected error while fetching categories")
        return Response(
            {'error': 'Unexpected server error while fetching categories.'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

@api_view(['POST'])
def create_category(request):
    try:
        serializer = CategorySerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except IntegrityError:
        return Response(
            {'error': 'A category with this name already exists.'},
            status=status.HTTP_400_BAD_REQUEST,
        )
    except (OperationalError, ProgrammingError):
        logger.exception("Category table is unavailable. Run migrations on the deployed server.")
        return _schema_error_response('Category')
    except Exception:
        logger.exception("Unexpected error while creating category")
        return Response(
            {'error': 'Unexpected server error while creating category.'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

@api_view(['PUT'])
def update_category(request, pk):
    try:
        category = Category.objects.get(pk=pk)
        serializer = CategorySerializer(category, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except Category.DoesNotExist:
        return Response({'error': 'Category not found'}, status=status.HTTP_404_NOT_FOUND)
    except (OperationalError, ProgrammingError):
        logger.exception("Category table is unavailable. Run migrations on the deployed server.")
        return _schema_error_response('Category')
    except Exception:
        logger.exception("Unexpected error while updating category")
        return Response(
            {'error': 'Unexpected server error while updating category.'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

@api_view(['DELETE'])
def delete_category(request, pk):
    try:
        category = Category.objects.get(pk=pk)
        category.is_active = False  # Soft delete
        category.save()
        return Response({'message': 'Category deactivated successfully'})
    except Category.DoesNotExist:
        return Response({'error': 'Category not found'}, status=status.HTTP_404_NOT_FOUND)
    except (OperationalError, ProgrammingError):
        logger.exception("Category table is unavailable. Run migrations on the deployed server.")
        return _schema_error_response('Category')
    except Exception:
        logger.exception("Unexpected error while deleting category")
        return Response(
            {'error': 'Unexpected server error while deleting category.'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

# ================= USER APIs =================
@api_view(['GET'])
def get_users(request):
    # ... rest of your code stays the same
    users = User.objects.all()
    serializer = UserSerializer(users, many=True, context={'request': request})
    return Response(serializer.data)

# GET single user
@api_view(['GET'])
def get_user(request, pk):
    try:
        user = User.objects.get(pk=pk)
        serializer = UserSerializer(user, context={'request': request})
        return Response(serializer.data)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

# POST - Create user (Register)
@api_view(['POST'])
def create_user(request):
    data = request.data.copy()
    password = data.get('password')
    if password:
        data['password'] = make_password(password)

    serializer = UserSerializer(data=data, context={'request': request})
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

def _attach_user_image_to_data(data, request):
    image_file = request.FILES.get('image') or request.FILES.get('image_url')
    if not image_file:
        return data

    ext = os.path.splitext(image_file.name)[1] or '.jpg'
    filename = f"{random.randint(100000, 999999)}{ext}"
    uploaded_file = SimpleUploadedFile(filename, image_file.read(), content_type=image_file.content_type)

    data['image_url'] = uploaded_file
    return data

# PUT - Update full user
@api_view(['PUT'])
def update_user(request, pk):
    try:
        user = User.objects.get(pk=pk)
        data = request.data.copy()
        data = _attach_user_image_to_data(data, request)

        if data.get('password'):
            data['password'] = make_password(data['password'])

        serializer = UserSerializer(user, data=data, partial=True, context={'request': request})
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
        data = request.data.copy()
        data = _attach_user_image_to_data(data, request)

        if data.get('password'):
            data['password'] = make_password(data['password'])

        serializer = UserSerializer(user, data=data, partial=True, context={'request': request})
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

    password_matches = check_password(password, user.password)
    if not password_matches:
        if user.password == password:
            # Legacy plain-text password support: migrate to hashed password on first login.
            user.password = make_password(password)
            user.save(update_fields=['password'])
            password_matches = True

    if not password_matches:
        return Response(
            {'error': 'Incorrect password. Please try again.'},
            status=status.HTTP_401_UNAUTHORIZED
        )

    serializer = UserSerializer(user, context={'request': request})
    admin_flag = user.is_admin or user.email.strip().lower() == 'admin@gmail.com'

    return Response({
        'message': 'Login successful',
        'user': serializer.data,
        'is_admin': admin_flag
    }, status=status.HTTP_200_OK)


# ============= PRODUCT VIEWS =============

@api_view(['GET'])
def get_products(request):
    """Get all active products (del_flag=False)"""
    try:
        products = Product.objects.filter(del_flag=False).select_related('category')

        category = request.GET.get('category')
        if category:
            category = category.strip()
            if category.lower() == 'all':
                pass
            elif category.isdigit():
                products = products.filter(category_id=int(category))
            else:
                category_obj = Category.objects.filter(
                    Q(name__iexact=category) | Q(display_name__iexact=category)
                ).first()
                if not category_obj:
                    normalized_category = _normalize_category_value(category)
                    for candidate in Category.objects.filter(is_active=True):
                        if (
                            _normalize_category_value(candidate.name) == normalized_category or
                            _normalize_category_value(candidate.display_name) == normalized_category
                        ):
                            category_obj = candidate
                            break
                if category_obj:
                    products = products.filter(category_id=category_obj.id)
                else:
                    products = products.none()

        serializer = ProductSerializer(products, many=True, context={'request': request})
        return Response(serializer.data)
    except (OperationalError, ProgrammingError):
        logger.exception("Product/category schema is unavailable. Run migrations on the deployed server.")
        return _schema_error_response('Product')
    except Exception:
        logger.exception("Unexpected error while fetching products")
        return Response(
            {'error': 'Unexpected server error while fetching products.'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(['GET'])
def get_all_products_admin(request):
    """Admin: Get ALL products including soft-deleted ones"""
    try:
        products = Product.objects.all().select_related('category')
        serializer = ProductSerializer(products, many=True, context={'request': request})
        return Response(serializer.data)
    except (OperationalError, ProgrammingError):
        logger.exception("Product/category schema is unavailable. Run migrations on the deployed server.")
        return _schema_error_response('Product')
    except Exception:
        logger.exception("Unexpected error while fetching admin products")
        return Response(
            {'error': 'Unexpected server error while fetching admin products.'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(['GET'])
def get_product_detail(request, pk):
    """Get single product details"""
    try:
        product = Product.objects.get(pk=pk, del_flag=False)
        serializer = ProductSerializer(product, context={'request': request})
        return Response(serializer.data)
    except Product.DoesNotExist:
        return Response(
            {'error': 'Product not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )
    except (OperationalError, ProgrammingError):
        logger.exception("Product/category schema is unavailable. Run migrations on the deployed server.")
        return _schema_error_response('Product')
    except Exception:
        logger.exception("Unexpected error while fetching product detail")
        return Response(
            {'error': 'Unexpected server error while fetching product detail.'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(['POST'])
def create_product(request):
    """Admin: Create new product"""
    try:
        if request.method == 'POST':
            data = request.data.copy()

            if 'image' in request.FILES:
                image_file = request.FILES['image']
                ext = os.path.splitext(image_file.name)[1] or '.jpg'
                filename = f"{random.randint(100000, 999999)}{ext}"
                data['image_url'] = SimpleUploadedFile(
                    filename,
                    image_file.read(),
                    content_type=image_file.content_type,
                )

            serializer = ProductSerializer(data=data, context={'request': request})
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except (OperationalError, ProgrammingError):
        logger.exception("Product/category schema is unavailable. Run migrations on the deployed server.")
        return _schema_error_response('Product')
    except Exception:
        logger.exception("Unexpected error while creating product")
        return Response(
            {'error': 'Unexpected server error while creating product.'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


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
            ext = os.path.splitext(image_file.name)[1] or '.jpg'
            filename = f"{random.randint(100000, 999999)}{ext}"
            data['image_url'] = SimpleUploadedFile(
                filename,
                image_file.read(),
                content_type=image_file.content_type,
            )

        if data.get('remove_image') in ['true', 'True', True]:
            data['image_url'] = None
        
        serializer = ProductSerializer(product, data=data, partial=True, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except Product.DoesNotExist:
        return Response(
            {'error': 'Product not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )
    except (OperationalError, ProgrammingError):
        logger.exception("Product/category schema is unavailable. Run migrations on the deployed server.")
        return _schema_error_response('Product')
    except Exception:
        logger.exception("Unexpected error while updating product")
        return Response(
            {'error': 'Unexpected server error while updating product.'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
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
    except (OperationalError, ProgrammingError):
        logger.exception("Product/category schema is unavailable. Run migrations on the deployed server.")
        return _schema_error_response('Product')


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
    except (OperationalError, ProgrammingError):
        logger.exception("Product/category schema is unavailable. Run migrations on the deployed server.")
        return _schema_error_response('Product')


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
    except (OperationalError, ProgrammingError):
        logger.exception("Product/category schema is unavailable. Run migrations on the deployed server.")
        return _schema_error_response('Product')
    
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
        image_url = None
        if item.product.image_url:
            try:
                image_url = request.build_absolute_uri(item.product.image_url.url)
            except Exception:
                image_url = str(item.product.image_url)

        data.append({
            "id": item.id,
            "product_id": item.product.id,
            "product_name": item.product.name,
            "price": item.product.price,
            "quantity": item.quantity,
            "image": image_url,
        })

    return Response(data)


@api_view(['PUT', 'PATCH'])
def update_cart_item(request):
    """Update quantity of a cart item"""
    try:
        user_id = request.data.get('user_id')
        product_id = request.data.get('product_id')
        quantity = request.data.get('quantity')
        
        if not all([user_id, product_id, quantity]):
            return Response(
                {'error': 'user_id, product_id, and quantity are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if quantity < 1:
            return Response(
                {'error': 'Quantity must be at least 1'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user = User.objects.get(id=user_id)
        cart = Cart.objects.get(user=user)
        item = CartItem.objects.get(cart=cart, product_id=product_id)
        
        item.quantity = quantity
        item.save()
        
        return Response({
            'message': 'Cart item updated successfully',
            'quantity': item.quantity
        }, status=status.HTTP_200_OK)
        
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    except Cart.DoesNotExist:
        return Response({'error': 'Cart not found'}, status=status.HTTP_404_NOT_FOUND)
    except CartItem.DoesNotExist:
        return Response({'error': 'Product not in cart'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"Error updating cart item: {str(e)}")
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST', 'DELETE'])
def remove_from_cart(request):
    """Remove a product from the cart"""
    try:
        user_id = request.data.get('user_id')
        product_id = request.data.get('product_id')
        
        if not user_id or not product_id:
            return Response(
                {'error': 'user_id and product_id are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user = User.objects.get(id=user_id)
        cart = Cart.objects.get(user=user)
        item = CartItem.objects.get(cart=cart, product_id=product_id)
        
        product_name = item.product.name
        item.delete()
        
        return Response({
            'message': f'{product_name} removed from cart',
            'success': True
        }, status=status.HTTP_200_OK)
        
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    except Cart.DoesNotExist:
        return Response({'error': 'Cart not found'}, status=status.HTTP_404_NOT_FOUND)
    except CartItem.DoesNotExist:
        return Response({'error': 'Product not in cart'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"Error removing from cart: {str(e)}")
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)



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


# ============= WISHLIST VIEWS =============

@api_view(['GET'])
def get_wishlist(request, user_id):
    """Get all items in user's wishlist"""
    try:
        wishlist, created = Wishlist.objects.get_or_create(user_id=user_id)
        items = WishlistItem.objects.filter(wishlist=wishlist).select_related('product__category')
        
        data = []
        for item in items:
            product = item.product
            category_value = None
            try:
                category_value = product.category.display_name or product.category.name
            except Exception:
                category_value = None

            image_url = None
            if product.image_url:
                try:
                    image_url = request.build_absolute_uri(product.image_url.url)
                except Exception:
                    image_url = str(product.image_url)

            data.append({
                'id': item.id,
                'product_id': product.id,
                'product_name': product.name,
                'price': product.price,
                'image': image_url,
                'rating': product.rating,
                'category': category_value,
                'created_at': item.created_at,
            })

        return Response(data)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"Error fetching wishlist: {str(e)}")
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def add_to_wishlist(request):
    """Add product to user's wishlist"""
    try:
        user_id = request.data.get('user_id')
        product_id = request.data.get('product_id')
        
        if not user_id or not product_id:
            return Response(
                {'error': 'user_id and product_id are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user = User.objects.get(id=user_id)
        product = Product.objects.get(id=product_id)
        
        wishlist, created = Wishlist.objects.get_or_create(user=user)
        
        item, created = WishlistItem.objects.get_or_create(
            wishlist=wishlist,
            product=product
        )
        
        if created:
            message = 'Product added to wishlist'
        else:
            message = 'Product already in wishlist'
        
        return Response({
            'message': message,
            'is_in_wishlist': True
        }, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)
        
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    except Product.DoesNotExist:
        return Response({'error': 'Product not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"Error adding to wishlist: {str(e)}")
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def remove_from_wishlist(request):
    """Remove product from user's wishlist"""
    try:
        user_id = request.data.get('user_id')
        product_id = request.data.get('product_id')
        
        if not user_id or not product_id:
            return Response(
                {'error': 'user_id and product_id are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user = User.objects.get(id=user_id)
        product = Product.objects.get(id=product_id)
        
        wishlist = Wishlist.objects.get(user=user)
        item = WishlistItem.objects.get(wishlist=wishlist, product=product)
        item.delete()
        
        return Response({
            'message': 'Product removed from wishlist',
            'is_in_wishlist': False
        }, status=status.HTTP_200_OK)
        
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    except Product.DoesNotExist:
        return Response({'error': 'Product not found'}, status=status.HTTP_404_NOT_FOUND)
    except Wishlist.DoesNotExist:
        return Response({'error': 'Wishlist not found'}, status=status.HTTP_404_NOT_FOUND)
    except WishlistItem.DoesNotExist:
        return Response({
            'message': 'Product not in wishlist',
            'is_in_wishlist': False
        }, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error removing from wishlist: {str(e)}")
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def is_product_in_wishlist(request, user_id, product_id):
    """Check if product is in user's wishlist"""
    try:
        user = User.objects.get(id=user_id)
        product = Product.objects.get(id=product_id)
        
        wishlist = Wishlist.objects.filter(user=user).first()
        
        if not wishlist:
            return Response({'is_in_wishlist': False})
        
        is_in_wishlist = WishlistItem.objects.filter(
            wishlist=wishlist,
            product=product
        ).exists()
        
        return Response({'is_in_wishlist': is_in_wishlist})
        
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    except Product.DoesNotExist:
        return Response({'error': 'Product not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"Error checking wishlist: {str(e)}")
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
