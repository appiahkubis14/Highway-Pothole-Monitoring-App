# urls.py

from django.urls import path
from .views import *

urlpatterns = [
    path('potholes/', PotholeCreateView.as_view(), name='create_pothole'),
    path('fetch_potholes/', PotholeListAPIView.as_view(), name='pothole-list'),
    path('upload/image/', upload_image, name='upload_image'),
    path('upload/video/', upload_video, name='upload_video'),
    path('potholes/', submit_pothole_report, name='submit_pothole'),

]
