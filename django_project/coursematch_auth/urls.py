from . import views
from django.urls import path

# routed from /e/kostiukb/coursematchauth
urlpatterns = [
    path('loginuser/', views.login_user, name='coursematch_auth-login_user'),
    path('isauth/', views.get_auth, name='coursematch_auth-is_auth'),
    path('getuserinfo/', views.get_user_info, name='coursemath_auth-get_user_info'),
    path('registeruser/', views.register_user, name='coursematch_auth-register_user'),
    path('logoutuser/', views.logout_user, name='coursematch_auth-logout_user'),
]