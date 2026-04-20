from django.urls import path
from . import views

urlpatterns = [

    # User routes (Registration, Login, CRUD)
    path('users/', views.get_users, name='get_users'),
    path('users/<int:pk>/', views.get_user, name='get_user'),
    path('users/create/', views.create_user, name='create_user'),
    path('users/update/<int:pk>/', views.update_user, name='update_user'),
    path('users/partial/<int:pk>/', views.partial_update_user, name='partial_update_user'),
    path('users/delete/<int:pk>/', views.delete_user, name='delete_user'),
    path('login/', views.login_user, name='login_user'),

    # Product routes (User)
    path('products/', views.get_products, name='get_products'),
    path('products/<int:pk>/', views.get_product_detail, name='get_product_detail'),
    
    # Product routes (Admin)
    path('admin/products/', views.get_all_products_admin, name='get_all_products_admin'),
    path('admin/products/create/', views.create_product, name='create_product'),
    path('admin/products/update/<int:pk>/', views.update_product, name='update_product'),
    path('admin/products/soft-delete/<int:pk>/', views.soft_delete_product, name='soft_delete_product'),
    path('admin/products/restore/<int:pk>/', views.restore_product, name='restore_product'),
    path('admin/products/hard-delete/<int:pk>/', views.hard_delete_product, name='hard_delete_product'),

    path('cart/add/', views.add_to_cart, name='add_to_cart'),
    path('cart/<int:user_id>/', views.get_cart, name='get_cart'),
    path('cart/update/', views.update_cart_item, name='update_cart_item'),
    path('cart/remove/', views.remove_from_cart, name='remove_from_cart'),

    # Wishlist routes
    path('wishlist/<int:user_id>/', views.get_wishlist, name='get_wishlist'),
    path('wishlist/add/', views.add_to_wishlist, name='add_to_wishlist'),
    path('wishlist/remove/', views.remove_from_wishlist, name='remove_from_wishlist'),
    path('wishlist/check/<int:user_id>/<int:product_id>/', views.is_product_in_wishlist, name='is_product_in_wishlist'),

    # path('api/auth/google/', views.google_auth, name='google-auth'),
    path('auth/google/', views.google_auth, name='google-auth'),
]