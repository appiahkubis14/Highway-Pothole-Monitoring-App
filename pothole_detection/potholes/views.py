from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Pothole
from .serializer import PotholeSerializer
from rest_framework import generics
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt


class PotholeListAPIView(generics.ListAPIView):
    queryset = Pothole.objects.all()
    serializer_class = PotholeSerializer


class PotholeCreateView(APIView):

    def post(self, request, *args, **kwargs):
        data = request.data
        # Create a new pothole record
        serializer = PotholeSerializer(data=data)
        
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)



@csrf_exempt
def upload_image(request):
    if request.method == 'POST':
        file = request.FILES['file']
        # Save the file to a directory or use a cloud service like S3.
        # Let's assume we save it locally and return a URL
        file_url = f'/media/{file.name}'
        return JsonResponse({'url': file_url})
    return JsonResponse({'error': 'Invalid method'}, status=405)


@csrf_exempt
def upload_video(request):
    if request.method == 'POST':
        file = request.FILES['file']
        # Save video and return the URL
        file_url = f'/media/{file.name}'
        return JsonResponse({'url': file_url})
    return JsonResponse({'error': 'Invalid method'}, status=405)


@csrf_exempt
def submit_pothole_report(request):
    if request.method == 'POST':
        # Parse the form data from the request body
        description = request.POST.get('ai_description')
        alt_description = request.POST.get('alternate_description')
        lat = request.POST.get('location_lat')
        lon = request.POST.get('location_lon')
        image_url = request.POST.get('image_url')
        video_url = request.POST.get('video_url')

        # Save the data to the database or process it as needed
        # For now, just return a success message
        return JsonResponse({'message': 'Pothole submitted successfully'}, status=201)

    return JsonResponse({'error': 'Invalid method'}, status=405)
