from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Pothole
from .serializer import PotholeSerializer
from rest_framework import generics


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

