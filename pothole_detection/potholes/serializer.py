# serializers.py

from rest_framework import serializers
from .models import Pothole

class PotholeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Pothole
        fields = ['id', 'ai_description', 'alternate_description', 'image', 'video', 'location_lat', 'location_lon', 'created_at']
