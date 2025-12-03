"""
WSGI config for crop_ai_frontend project.
"""
import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'crop_ai_frontend.settings')

application = get_wsgi_application()
