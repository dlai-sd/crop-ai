import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CropAIService } from '../../services/crop-ai.service';
import { BaseChartDirective } from 'ng2-charts';
import { ChartConfiguration } from 'chart.js';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, BaseChartDirective],
  template: `
    <div class="container-fluid">
      <h2 class="mb-4">📊 Dashboard</h2>

      <!-- Stats Row -->
      <div class="row mb-4">
        <div class="col-md-3">
          <div class="card stat-card">
            <div class="card-body">
              <h6 class="card-title">Total Predictions</h6>
              <h3>{{ health?.inference_count || 0 }}</h3>
            </div>
          </div>
        </div>
        <div class="col-md-3">
          <div class="card stat-card">
            <div class="card-body">
              <h6 class="card-title">Service Status</h6>
              <span [class]="'badge badge-' + (health?.status === 'healthy' ? 'success' : 'warning')">
                {{ health?.status | uppercase }}
              </span>
            </div>
          </div>
        </div>
        <div class="col-md-3">
          <div class="card stat-card">
            <div class="card-body">
              <h6 class="card-title">Uptime</h6>
              <h5>{{ formatUptime(health?.uptime_seconds || 0) }}</h5>
            </div>
          </div>
        </div>
        <div class="col-md-3">
          <div class="card stat-card">
            <div class="card-body">
              <h6 class="card-title">System Health</h6>
              <span class="badge badge-info">{{ metrics?.overall_status | uppercase }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Charts Row -->
      <div class="row">
        <div class="col-md-6">
          <div class="card">
            <div class="card-header">
              <h5 class="mb-0">🌱 Crop Distribution</h5>
            </div>
            <div class="card-body">
              <canvas 
                baseChart 
                [data]="cropChartData"
                [options]="cropChartOptions"
                type="doughnut"
              ></canvas>
            </div>
          </div>
        </div>

        <div class="col-md-6">
          <div class="card">
            <div class="card-header">
              <h5 class="mb-0">💻 System Resources</h5>
            </div>
            <div class="card-body">
              <canvas 
                baseChart 
                [data]="resourceChartData"
                [options]="resourceChartOptions"
                type="bar"
              ></canvas>
            </div>
          </div>
        </div>
      </div>

      <!-- Predictions History -->
      <div class="row mt-4">
        <div class="col-12">
          <div class="card">
            <div class="card-header">
              <h5 class="mb-0">📝 Recent Predictions</h5>
            </div>
            <div class="card-body">
              <div class="table-responsive">
                <table class="table table-hover">
                  <thead class="table-light">
                    <tr>
                      <th>Crop Type</th>
                      <th>Confidence</th>
                      <th>Model Version</th>
                      <th>Timestamp</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr *ngFor="let pred of predictions?.predictions | slice:0:10">
                      <td>
                        <span class="badge badge-primary">{{ pred.crop_type }}</span>
                      </td>
                      <td>
                        <span class="badge" [class]="getConfidenceClass(pred.confidence)">
                          {{ (pred.confidence * 100).toFixed(0) }}%
                        </span>
                      </td>
                      <td>{{ pred.model_version }}</td>
                      <td>{{ pred.timestamp | date:'short' }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .stat-card {
      border: none;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      transition: transform 0.2s;
    }

    .stat-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    }

    .card {
      border: none;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      margin-bottom: 20px;
    }

    .card-header {
      background-color: #f8f9fa;
      border-bottom: 2px solid #e9ecef;
      padding: 15px;
    }

    .badge-primary { background-color: #007bff; }
    .badge-success { background-color: #28a745; }
    .badge-warning { background-color: #ffc107; }
    .badge-info { background-color: #17a2b8; }
  `]
})
export class DashboardComponent implements OnInit {
  health: any;
  metrics: any;
  predictions: any;
  stats: any;

  cropChartData: any;
  cropChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    plugins: {
      legend: {
        position: 'bottom',
      }
    }
  };

  resourceChartData: any;
  resourceChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    scales: {
      y: {
        beginAtZero: true,
        max: 100
      }
    }
  };

  constructor(private cropAIService: CropAIService) {
    this.initializeCharts();
  }

  ngOnInit(): void {
    this.loadData();
  }

  loadData(): void {
    this.cropAIService.getHealth().subscribe({
      next: (data) => { this.health = data; },
      error: (err) => console.error('Health error:', err)
    });

    this.cropAIService.getMetrics().subscribe({
      next: (data) => { 
        this.metrics = data;
        this.updateResourceChart(data);
      },
      error: (err) => console.error('Metrics error:', err)
    });

    this.cropAIService.getPredictions(50).subscribe({
      next: (data) => { 
        this.predictions = data;
        this.updateCropChart(data);
      },
      error: (err) => console.error('Predictions error:', err)
    });

    this.cropAIService.getStats().subscribe({
      next: (data) => { this.stats = data; },
      error: (err) => console.error('Stats error:', err)
    });
  }

  private initializeCharts(): void {
    this.cropChartData = {
      labels: [],
      datasets: [{
        data: [],
        backgroundColor: ['#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0', '#9966FF'],
        borderWidth: 2,
        borderColor: '#fff'
      }]
    };

    this.resourceChartData = {
      labels: ['CPU %', 'Memory %'],
      datasets: [{
        label: 'Usage',
        data: [0, 0],
        backgroundColor: ['#FF6384', '#36A2EB'],
        borderWidth: 1,
        borderColor: '#999'
      }]
    };
  }

  private updateCropChart(predictions: any): void {
    const crops = predictions.predictions || [];
    const cropCount: { [key: string]: number } = {};
    
    crops.forEach((pred: any) => {
      cropCount[pred.crop_type] = (cropCount[pred.crop_type] || 0) + 1;
    });

    this.cropChartData = {
      labels: Object.keys(cropCount),
      datasets: [{
        data: Object.values(cropCount),
        backgroundColor: ['#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0', '#9966FF'],
        borderWidth: 2,
        borderColor: '#fff'
      }]
    };
  }

  private updateResourceChart(metrics: any): void {
    this.resourceChartData = {
      labels: ['CPU %', 'Memory %'],
      datasets: [{
        label: 'Usage',
        data: [
          metrics.system?.cpu_percent || 0,
          metrics.system?.memory_percent || 0
        ],
        backgroundColor: ['#FF6384', '#36A2EB'],
        borderWidth: 1,
        borderColor: '#999'
      }]
    };
  }

  formatUptime(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${hours}h ${minutes}m`;
  }

  getConfidenceClass(confidence: number): string {
    if (confidence >= 0.9) return 'badge-success';
    if (confidence >= 0.7) return 'badge-info';
    return 'badge-warning';
  }
}
