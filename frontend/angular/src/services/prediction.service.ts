import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { delay, map } from 'rxjs/operators';

export interface PredictionResult {
  crop: string;
  confidence: number;
  confidence_level: 'High' | 'Medium' | 'Low';
  health: 'Good' | 'Monitor' | 'Risky';
  area_sqm: number;
  risk_factors: string[];
  recommendations: string[];
  timestamp: string;
}

@Injectable({
  providedIn: 'root'
})
export class PredictionService {
  private apiUrl = '/api/predict';

  constructor(private http: HttpClient) {}

  predictCrop(imageFile: File): Observable<PredictionResult> {
    const formData = new FormData();
    formData.append('file', imageFile);

    // Mock prediction - replace with real API when model is ready
    return this.getMockPrediction().pipe(delay(2000));
  }

  private getMockPrediction(): Observable<PredictionResult> {
    const crops: PredictionResult[] = [
      {
        crop: '🍅 Tomato',
        confidence: 0.92,
        confidence_level: 'High',
        health: 'Good',
        area_sqm: 2500,
        risk_factors: ['Low soil moisture', 'High pest activity in region'],
        recommendations: ['Increase irrigation by 20%', 'Apply preventive pest management spray'],
        timestamp: new Date().toISOString()
      },
      {
        crop: '🌾 Wheat',
        confidence: 0.88,
        confidence_level: 'High',
        health: 'Monitor',
        area_sqm: 3000,
        risk_factors: ['Temperature fluctuation', 'Irregular rainfall'],
        recommendations: ['Continue monitoring closely', 'Prepare irrigation backup plan'],
        timestamp: new Date().toISOString()
      },
      {
        crop: '🥕 Carrot',
        confidence: 0.85,
        confidence_level: 'Medium',
        health: 'Good',
        area_sqm: 1500,
        risk_factors: ['Root rot risk if overwatered'],
        recommendations: ['Ensure proper drainage', 'Monitor soil moisture regularly'],
        timestamp: new Date().toISOString()
      },
      {
        crop: '🧅 Onion',
        confidence: 0.90,
        confidence_level: 'High',
        health: 'Risky',
        area_sqm: 2000,
        risk_factors: ['Disease pressure high', 'Weather stress indicators'],
        recommendations: ['Apply fungicide immediately', 'Improve air circulation'],
        timestamp: new Date().toISOString()
      },
      {
        crop: '🌽 Corn',
        confidence: 0.87,
        confidence_level: 'High',
        health: 'Good',
        area_sqm: 3500,
        risk_factors: [],
        recommendations: ['Continue regular maintenance', 'Plan harvesting in 3-4 weeks'],
        timestamp: new Date().toISOString()
      }
    ];

    return of(crops[Math.floor(Math.random() * crops.length)]);
  }
}
