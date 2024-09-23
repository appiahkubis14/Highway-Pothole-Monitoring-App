from rest_framework import serializers
from .models import PotholeReport

class PotholeSerializer(serializers.ModelSerializer):
    class Meta:
        model = PotholeReport
        fields = ['id', 
                  'ai_description',
                  'alternate_description',
                  'image_url', 
                  'video_url', 
                  'location_lat', 
                  'location_lon',
                  'town_name',
                  'road_type',
                  'road_name',
                  'origin',
                  'destination',
                  'created_at']

    # Validation for latitude
    def validate_location_lat(self, value):
        if not (-90 <= value <= 90):
            raise serializers.ValidationError("Latitude must be between -90 and 90.")
        return value

    # Validation for longitude
    def validate_location_lon(self, value):
        if not (-180 <= value <= 180):
            raise serializers.ValidationError("Longitude must be between -180 and 180.")
        return value
