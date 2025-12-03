"""
URL routing for API app.
"""
from django.urls import path
from . import views

app_name = 'api'

urlpatterns = [
    path('health/', views.health, name='health'),
    path('ready/', views.ready, name='ready'),
    path('info/', views.info, name='info'),
    path('metrics/', views.metrics, name='metrics'),
    path('predict/', views.predict, name='predict'),
    path('predictions/', views.predictions, name='predictions'),
    path('stats/', views.stats, name='stats'),
]
