# strip_newline_middleware.py

class StripNewlineMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Strip any newlines or extra spaces from the request path
        request.path_info = request.path_info.strip()
        return self.get_response(request)
