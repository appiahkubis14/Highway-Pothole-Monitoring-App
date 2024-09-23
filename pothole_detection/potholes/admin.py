from django.contrib import admin
from .models import PotholeReport

# Register your models here.
admin.site.register(PotholeReport)

# @admin.register(Pothole)
# class PotholeAdmin(admin.ModelAdmin):
#     list_display = ('name','ai_description' ,'latitude', 'longitude')
