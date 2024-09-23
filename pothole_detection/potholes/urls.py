from django.urls import path
from .views import UploadImageView, UploadVideoView, SubmitPotholeReportView

urlpatterns = [
    path('potholes/', SubmitPotholeReportView.as_view(), name='submit_pothole'),  # No spaces in 'potholes/'
    path('upload/image', UploadImageView.as_view(), name='upload_image'),  # No spaces in 'upload/image'
    path('upload/video', UploadVideoView.as_view(), name='upload_video'),  # No spaces in 'upload/video'
]
