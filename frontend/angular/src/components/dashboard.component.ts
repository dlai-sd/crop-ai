import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CropAIService } from '../services/crop-ai.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule],
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

      <!-- System Info Row -->
      <div class="row mb-4">
        <div class="col-md-6">
          <div class="card">
            <div class="card-header">
              <h5 class="mb-0">💻 System Resources</h5>
            </div>
            <div class="card-body">
              <div class="mb-3">
                <label>CPU Usage: {{ metrics?.system?.cpu_percent || 0 | number:'1.1-1' }}%</label>
                <div class="progress">
                  <div 
                    class="progress-bar" 
                    [style.width.%]="metrics?.system?.cpu_percent || 0"
                  ></div>
                </div>
              </div>
              <div>
                <label>Memory Usage: {{ metrics?.system?.memory_percent || 0 | number:'1.1-1' }}%</label>
                <div class="progress">
                  <div 
                    class="progress-bar bg-warning" 
                    [style.width.%]="metrics?.system?.memory_percent || 0"
                  ></div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-md-6">
          <div class="card">
            <div class="card-header">
              <h5 class="mb-0">🔧 Service Info</h5>
            </div>
            <div class="card-body">
              <p><strong>Model Ready:</strong> 
                <span [class]="'badge badge-' + (metrics?.model?.initialized ? 'success' : 'danger')">
                  {{ metrics?.model?.initialized ? 'Yes' : 'No' }}
                </span>
              </p>
              <p><strong>CPU OK:</strong> 
                <span [class]="'badge badge-' + (metrics?.system?.cpu_ok ? 'success' : 'danger')">
                  {{ metrics?.system?.cpu_ok ? 'Yes' : 'No' }}
                </span>
              </p>
              <p><strong>Memory OK:</strong> 
                <span [class]="'badge badge-' + (metrics?.system?.memory_ok ? 'success' : 'danger')">
                  {{ metrics?.system?.memory_ok ? 'Yes' : 'No' }}
                </span>
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Predictions History -->
      <div class="row">
        <div class="col-12">
          <div class="card">
            <div class="card-header">
              <h5 class="mb-0">📝 Recent Predictions</h5>
            </div>
            <div class="card-body">
              <div *ngIf="!predictions?.predictions || predictions.predictions.length === 0" class="alert alert-info">
                No predictions yet
              </div>
              <div class="table-responsive" *ngIf="predictions?.predictions && predictions.predictions.length > 0">
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
                    <tr *ngFor="let pred of predictions.predictions | slice:0:10; let item = $implicit">
                      <td>
                        <span class="badge badge-primary">{{ item['crop_type'] }}</span>
                      </td>
                      <td>
                        <span class="badge" [class]="getConfidenceClass(item['confidence'])">
                          {{ (item['confidence'] * 100).toFixed(0) }}%
                        </span>
                      </td>
                      <td>{{ item['model_version'] }}</td>
                      <td>{{ item['timestamp'] | date:'short' }}</td>
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
    .badge-danger { background-color: #dc3545; }
    .badge-info { background-color: #17a2b8; }
  `]
})
export class DashboardComponent implements OnInit {
  health: any = {};
  metrics: any = {};
  predictions: any = { predictions: [] };
  stats: any = {};

  constructor(private cropAIService: CropAIService) {}

  ngOnInit(): void {
    this.loadData();
    // Refresh every 10 seconds
    setInterval(() => this.loadData(), 10000);
  }

  loadData(): void {
    this.cropAIService.getHealth().subscribe({
      next: (data: any) => { this.health = data; },
      error: (err: any) => console.error('Health error:', err)
    });

    this.cropAIService.getMetrics().subscribe({
      next: (data: any) => { this.metrics = data; },
      error: (err: any) => console.error('Metrics error:', err)
    });

    this.cropAIService.getPredictions(50).subscribe({
      next: (data: any) => { this.predictions = data; },
      error: (err: any) => console.error('Predictions error:', err)
    });

    this.cropAIService.getStats().subscribe({
      next: (data: any) => { this.stats = data; },
      error: (err: any) => console.error('Stats error:', err)
    });
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
