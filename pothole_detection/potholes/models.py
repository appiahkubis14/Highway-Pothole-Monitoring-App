# models.py

from django.db import models

class Pothole(models.Model):
    ai_description = models.TextField(null=True, blank=True)  # AI-generated description
    alternate_description = models.TextField(null=True, blank=True)  # User's alternate description
    image = models.ImageField(upload_to='pothole_images/')  # Image upload
    video = models.FileField(upload_to='pothole_videos/', null=True, blank=True)  # Optional video
    location_lat = models.FloatField()  # Latitude
    location_lon = models.FloatField()  # Longitude
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Pothole at ({self.location_lat}, {self.location_lon},)"


