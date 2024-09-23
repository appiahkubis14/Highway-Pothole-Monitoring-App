from django.db import models

class PotholeReport(models.Model):
    ai_description = models.TextField()
    alternate_description = models.TextField()
    location_lat = models.FloatField(null=True, blank=True)
    location_lon = models.FloatField(null=True, blank=True)
    town_name = models.CharField(max_length=100)
    road_type = models.CharField(max_length=50)
    road_name = models.CharField(max_length=100)
    origin = models.CharField(max_length=100)
    destination = models.CharField(max_length=100)
    image_url = models.URLField(null=True, blank=True)
    video_url = models.URLField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Pothole Report: {self.town_name}, {self.road_name}"
