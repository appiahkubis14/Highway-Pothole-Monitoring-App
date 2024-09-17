from django.contrib import admin
from .models import Pothole

# Register your models here.
admin.site.register(Pothole)

# @admin.register(Pothole)
# class PotholeAdmin(admin.ModelAdmin):
#     list_display = ('name','ai_description' ,'latitude', 'longitude')
