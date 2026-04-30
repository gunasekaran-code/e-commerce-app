from rest_framework import serializers
from .models import (
    Category,
    Order,
    OrderItem,
    Product,
    ProductImage,
    User,
    Wishlist,
    WishlistItem,
)

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'full_name', 'email', 'phone', 'image_url', 'password', 'is_admin', 'created_at']
        extra_kwargs = {
            'password': {'write_only': True}
        }


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'display_name', 'description', 'is_active', 'created_at', 'updated_at']


class ProductImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage
        fields = ['id', 'image_url', 'order']

class ProductSerializer(serializers.ModelSerializer):
    images = ProductImageSerializer(many=True, read_only=True)
    category_name = serializers.SerializerMethodField()
    category_display_name = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at', 'created_by']

    def get_category_name(self, obj):
        try:
            return obj.category.name
        except Exception:
            return None

    def get_category_display_name(self, obj):
        try:
            return obj.category.display_name
        except Exception:
            return None

    def to_representation(self, instance):
        """Custom representation to include is_in_stock"""
        representation = super().to_representation(instance)
        representation['is_in_stock'] = instance.is_in_stock
        return representation


class OrderItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderItem
        fields = ['id', 'product', 'product_name', 'product_price', 'quantity', 'created_at']


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)

    class Meta:
        model = Order
        fields = [
            'id',
            'user',
            'total_amount',
            'total_items',
            'status',
            'first_name',
            'last_name',
            'address_line_1',
            'address_line_2',
            'city',
            'state',
            'postal_code',
            'country',
            'payment_method',
            'items',
            'created_at',
            'updated_at',
        ]


class WishlistItemSerializer(serializers.ModelSerializer):
    product = ProductSerializer(read_only=True)

    class Meta:
        model = WishlistItem
        fields = ['id', 'product', 'created_at']


class WishlistSerializer(serializers.ModelSerializer):
    items = WishlistItemSerializer(many=True, read_only=True)

    class Meta:
        model = Wishlist
        fields = ['id', 'user', 'items', 'created_at', 'updated_at']
