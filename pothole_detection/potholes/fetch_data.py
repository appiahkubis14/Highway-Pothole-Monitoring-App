import requests

# Define the API URL (assuming you're running locally)
url = 'http://127.0.0.1:8000/api/fetch_potholes/'

# Send a GET request to the API
response = requests.get(url)

# Check if the request was successful
if response.status_code == 200:
    potholes = response.json()
    for pothole in potholes:
        print(f"AI Description: {pothole['ai_description']}")
        print(f"Alternate Description: {pothole['alternate_description']}")
        print(f"Latitude: {pothole['latitude']}, Longitude: {pothole['longitude']}")
        print("------------------------")
else:
    print(f"Failed to fetch data. Status code: {response.status_code}")
