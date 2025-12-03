import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CropAIService } from '../services/crop-ai.service';

@Component({
  selector: 'app-predict',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="row">
      <div class="col-md-6">
        <div class="card">
          <div class="card-header bg-primary text-white">
            <h5 class="mb-0">🌾 Crop Prediction</h5>
          </div>
          <div class="card-body">
            <div class="form-group mb-3">
              <label for="imageUrl" class="form-label">Satellite Image URL</label>
              <input 
                type="url" 
                class="form-control" 
                id="imageUrl"
                [(ngModel)]="imageUrl"
                placeholder="https://example.com/satellite-image.tif"
              />
            </div>

            <div class="form-group mb-3">
              <label for="modelVersion" class="form-label">Model Version</label>
              <select 
                class="form-select" 
                id="modelVersion"
                [(ngModel)]="modelVersion"
              >
                <option value="latest">Latest</option>
                <option value="v1">v1</option>
                <option value="v2">v2</option>
              </select>
            </div>

            <button 
              class="btn btn-primary w-100"
              (click)="onPredict()"
              [disabled]="loading || !imageUrl"
            >
              <span *ngIf="loading" class="spinner-border spinner-border-sm me-2"></span>
              {{ loading ? 'Processing...' : 'Predict' }}
            </button>

            <div *ngIf="error" class="alert alert-danger mt-3">
              {{ error }}
            </div>
          </div>
        </div>
      </div>

      <div class="col-md-6" *ngIf="prediction">
        <div class="card">
          <div class="card-header bg-success text-white">
            <h5 class="mb-0">✓ Prediction Result</h5>
          </div>
          <div class="card-body">
            <div class="prediction-result">
              <p><strong>Crop Type:</strong> {{ prediction.crop_type }}</p>
              <p><strong>Confidence:</strong> {{ (prediction.confidence * 100).toFixed(2) }}%</p>
              <div class="progress mb-3">
                <div 
                  class="progress-bar"
                  [style.width.%]="prediction.confidence * 100"
                ></div>
              </div>
              <p><strong>Model:</strong> {{ prediction.model_version }}</p>
              <p><strong>Time:</strong> {{ prediction.timestamp | date:'medium' }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .prediction-result {
      padding: 20px;
      background-color: #f8f9fa;
      border-radius: 8px;
    }
    
    .form-group label {
      font-weight: 600;
      color: #333;
    }
    
    .card {
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      border: none;
    }
    
    .card-header {
      border-bottom: 2px solid #e9ecef;
    }
  `]
})
export class PredictComponent implements OnInit {
  imageUrl = '';
  modelVersion = 'latest';
  loading = false;
  error = '';
  prediction: any = null;

  constructor(private cropAIService: CropAIService) {}

  ngOnInit(): void {}

  onPredict(): void {
    if (!this.imageUrl) {
      this.error = 'Please enter an image URL';
      return;
    }

    this.loading = true;
    this.error = '';
    this.prediction = null;

    this.cropAIService.predict({
      image_url: this.imageUrl,
      model_version: this.modelVersion
    }).subscribe({
      next: (result) => {
        this.prediction = result;
        this.loading = false;
      },
      error: (err) => {
        this.error = err.error?.detail || 'Prediction failed. Please try again.';
        this.loading = false;
      }
    });
  }
}
