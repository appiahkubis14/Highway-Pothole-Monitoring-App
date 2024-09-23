from django.views import View
from django.core.files.storage import FileSystemStorage
from django.http import JsonResponse, HttpResponseBadRequest
from .models import PotholeReport
import json
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator


# Apply csrf_exempt to all methods of the view
@method_decorator(csrf_exempt, name='dispatch')
class UploadImageView(View):
    def post(self, request):
        if 'file' in request.FILES:
            file = request.FILES['file']
            fs = FileSystemStorage()
            try:
                # Save file to the images directory
                filename = fs.save(f'images/{file.name}', file)
                file_url = fs.url(filename)
                return JsonResponse({'url': file_url})
            except Exception as e:
                return HttpResponseBadRequest(f"File upload failed: {str(e)}")
        return HttpResponseBadRequest('Invalid request - no file uploaded')


@method_decorator(csrf_exempt, name='dispatch')
class UploadVideoView(View):
    def post(self, request):
        if 'file' in request.FILES:
            file = request.FILES['file']
            fs = FileSystemStorage()
            try:
                # Save file to the videos directory
                filename = fs.save(f'videos/{file.name}', file)
                file_url = fs.url(filename)
                return JsonResponse({'url': file_url})
            except Exception as e:
                return HttpResponseBadRequest(f"File upload failed: {str(e)}")
        return HttpResponseBadRequest('Invalid request - no file uploaded')


@method_decorator(csrf_exempt, name='dispatch')
class SubmitPotholeReportView(View):
    def post(self, request):
        request.path_info = request.path_info.strip()  # Remove any trailing spaces or newlines in the path

        try:
            # Parse JSON data from the request body
            data = json.loads(request.body.decode('utf-8'))
        except json.JSONDecodeError:
            return HttpResponseBadRequest('Invalid JSON')

        # Required fields
        ai_description = data.get('ai_description')
        town_name = data.get('town_name')
        road_type = data.get('road_type')

        # Validate required fields
        if not ai_description or not town_name or not road_type:
            return HttpResponseBadRequest('Missing required fields')

        # Optional fields
        alternate_description = data.get('alternate_description')
        location_lat = data.get('location_lat')
        location_lon = data.get('location_lon')
        road_name = data.get('road_name')
        origin = data.get('origin')
        destination = data.get('destination')
        image_url = data.get('image_url')
        video_url = data.get('video_url')

        try:
            # Create and save the pothole report
            pothole_report = PotholeReport.objects.create(
                ai_description=ai_description,
                alternate_description=alternate_description,
                location_lat=location_lat,
                location_lon=location_lon,
                town_name=town_name,
                road_type=road_type,
                road_name=road_name,
                origin=origin,
                destination=destination,
                image_url=image_url,
                video_url=video_url
            )

            return JsonResponse({'message': 'Pothole submitted successfully', 'id': pothole_report.id}, status=201)
        
        except Exception as e:
            return HttpResponseBadRequest(f"Error saving the pothole report: {str(e)}")

