"""
API views for proxying crop-ai backend requests.
"""
import logging

import requests
from django.conf import settings
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.exceptions import APIException
from rest_framework.response import Response

logger = logging.getLogger(__name__)

BACKEND_API = settings.CROP_AI_API_URL
TIMEOUT = settings.CROP_AI_API_TIMEOUT


class BackendAPIException(APIException):
    """Exception for backend API errors."""
    status_code = 503
    default_detail = 'Backend service unavailable'


def _make_backend_request(method, endpoint, data=None):
    """Make request to backend API with error handling."""
    url = f"{BACKEND_API}{endpoint}"
    try:
        if method.upper() == 'GET':
            response = requests.get(url, timeout=TIMEOUT)
        elif method.upper() == 'POST':
            response = requests.post(url, json=data, timeout=TIMEOUT)
        else:
            raise ValueError(f"Unsupported method: {method}")

        response.raise_for_status()
        return response.json()
    except requests.exceptions.Timeout:
        logger.error(f"Timeout connecting to {url}")
        raise BackendAPIException(detail="Backend request timeout")
    except requests.exceptions.ConnectionError:
        logger.error(f"Connection error to {url}")
        raise BackendAPIException(detail="Cannot connect to backend")
    except requests.exceptions.HTTPError as e:
        logger.error(f"HTTP error from backend: {e}")
        raise BackendAPIException(
            detail=f"Backend error: {e.response.status_code}"
        )
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise BackendAPIException(detail=str(e))


@api_view(['GET'])
def health(request):
    """Get backend health status."""
    data = _make_backend_request('GET', '/health')
    return Response(data)


@api_view(['GET'])
def ready(request):
    """Get backend readiness status."""
    data = _make_backend_request('GET', '/ready')
    return Response(data)


@api_view(['GET'])
def info(request):
    """Get backend service info."""
    data = _make_backend_request('GET', '/info')
    return Response(data)


@api_view(['GET'])
def metrics(request):
    """Get backend metrics."""
    data = _make_backend_request('GET', '/metrics')
    return Response(data)


@api_view(['POST'])
def predict(request):
    """Make a prediction through backend."""
    required_fields = ['image_url']
    if not all(field in request.data for field in required_fields):
        return Response(
            {'error': f'Missing required fields: {required_fields}'},
            status=status.HTTP_400_BAD_REQUEST
        )

    payload = {
        'image_url': request.data.get('image_url'),
        'model_version': request.data.get('model_version', 'latest'),
    }

    data = _make_backend_request('POST', '/predict', data=payload)
    return Response(data)


@api_view(['GET'])
def predictions(request):
    """Get recent predictions."""
    limit = request.query_params.get('limit', 50)
    endpoint = f'/predictions?limit={limit}'
    data = _make_backend_request('GET', endpoint)
    return Response(data)


@api_view(['GET'])
def stats(request):
    """Get prediction statistics."""
    data = _make_backend_request('GET', '/stats')
    return Response(data)
