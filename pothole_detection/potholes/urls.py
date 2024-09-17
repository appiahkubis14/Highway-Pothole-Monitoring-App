# urls.py

from django.urls import path
from .views import PotholeCreateView , PotholeListAPIView

urlpatterns = [
    path('potholes/', PotholeCreateView.as_view(), name='create_pothole'),
    path('fetch_potholes/', PotholeListAPIView.as_view(), name='pothole-list'),
]
