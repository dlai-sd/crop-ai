import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface PredictionRequest {
  image_url: string;
  model_version?: string;
}

export interface PredictionResponse {
  crop_type: string;
  confidence: number;
  model_version: string;
  timestamp: string;
}

export interface PredictionsHistory {
  count: number;
  predictions: Array<{
    image_url: string;
    crop_type: string;
    confidence: number;
    model_version: string;
    timestamp: string;
  }>;
}

export interface Stats {
  stats: any;
  timestamp: string;
}

export interface HealthStatus {
  status: string;
  service: string;
  uptime_seconds: number;
  inference_count: number;
  timestamp: string;
}

@Injectable({
  providedIn: 'root'
})
export class CropAIService {
  private apiUrl = '/api';

  constructor(private http: HttpClient) {}

  predict(request: PredictionRequest): Observable<PredictionResponse> {
    return this.http.post<PredictionResponse>(`${this.apiUrl}/predict/`, request);
  }

  getPredictions(limit: number = 50): Observable<PredictionsHistory> {
    return this.http.get<PredictionsHistory>(`${this.apiUrl}/predictions/?limit=${limit}`);
  }

  getStats(): Observable<Stats> {
    return this.http.get<Stats>(`${this.apiUrl}/stats/`);
  }

  getHealth(): Observable<HealthStatus> {
    return this.http.get<HealthStatus>(`${this.apiUrl}/health/`);
  }

  getInfo(): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/info/`);
  }

  getMetrics(): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/metrics/`);
  }
}
