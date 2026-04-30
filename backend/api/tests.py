from django.test import TestCase
from rest_framework.test import APIClient

from .models import Cart, CartItem, Category, Order, Product, User


class CheckoutStockTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create(
            full_name='Test User',
            email='test@example.com',
            password='secret',
        )
        self.category = Category.objects.create(
            name='fitness',
            display_name='Fitness',
        )
        self.product = Product.objects.create(
            name='Yoga Mat',
            description='Test product',
            price='100.00',
            category=self.category,
            stock=5,
        )
        self.shipping_address = {
            'first_name': 'Test',
            'last_name': 'User',
            'address_line_1': '12 Main Street',
            'address_line_2': 'Floor 2',
            'city': 'Chennai',
            'state': 'Tamil Nadu',
            'postal_code': '600001',
            'country': 'India',
        }

    def test_checkout_reduces_stock_and_marks_product_out_of_stock(self):
        cart = Cart.objects.create(user=self.user)
        CartItem.objects.create(cart=cart, product=self.product, quantity=5)

        response = self.client.post(
            '/api/cart/checkout/',
            {
                'user_id': self.user.id,
                'product_ids': [self.product.id],
                'shipping_address': self.shipping_address,
                'payment_method': 'cod',
            },
            format='json',
        )

        self.assertEqual(response.status_code, 201)

        self.product.refresh_from_db()
        self.assertEqual(self.product.stock, 0)
        self.assertFalse(self.product.is_in_stock)
        self.assertFalse(CartItem.objects.filter(cart=cart).exists())

        order = Order.objects.get(user=self.user)
        self.assertEqual(order.total_items, 5)
        self.assertEqual(str(order.total_amount), '500.00')
        self.assertEqual(order.first_name, 'Test')
        self.assertEqual(order.payment_method, 'cod')
        self.assertEqual(order.items.count(), 1)
        self.assertEqual(order.items.first().quantity, 5)

    def test_add_to_cart_cannot_exceed_available_stock(self):
        response = self.client.post(
            '/api/cart/add/',
            {
                'user_id': self.user.id,
                'product_id': self.product.id,
                'quantity': 6,
            },
            format='json',
        )

        self.assertEqual(response.status_code, 400)
        self.assertIn('Only 5 item(s) available in stock', response.data['error'])

    def test_checkout_only_selected_products_and_keeps_other_cart_items(self):
        second_product = Product.objects.create(
            name='Skipping Rope',
            description='Another test product',
            price='50.00',
            category=self.category,
            stock=3,
        )
        cart = Cart.objects.create(user=self.user)
        CartItem.objects.create(cart=cart, product=self.product, quantity=2)
        CartItem.objects.create(cart=cart, product=second_product, quantity=1)

        response = self.client.post(
            '/api/cart/checkout/',
            {
                'user_id': self.user.id,
                'product_ids': [self.product.id],
                'shipping_address': self.shipping_address,
                'payment_method': 'upi',
            },
            format='json',
        )

        self.assertEqual(response.status_code, 201)

        self.product.refresh_from_db()
        second_product.refresh_from_db()
        self.assertEqual(self.product.stock, 3)
        self.assertEqual(second_product.stock, 3)
        self.assertFalse(CartItem.objects.filter(cart=cart, product=self.product).exists())
        self.assertTrue(CartItem.objects.filter(cart=cart, product=second_product).exists())
