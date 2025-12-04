import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AuthService, User } from '../../services/auth.service';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-unified-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="dashboard-container" *ngIf="currentUser">
      <!-- Farmer Dashboard -->
      <div *ngIf="currentUser.role === 'farmer'" class="dashboard farmer-dash">
        <div class="dash-header">
          <h1>🌾 Welcome, {{ currentUser.name }}!</h1>
          <p>Your Crop Intelligence Platform</p>
        </div>

        <!-- Quick Actions -->
        <div class="section">
          <h2>Quick Actions</h2>
          <div class="action-grid">
            <div class="action-card" (click)="showUploadForm = true">
              <div class="action-icon">📤</div>
              <h3>Upload Image</h3>
              <p>Get instant crop prediction</p>
            </div>
            <div class="action-card">
              <div class="action-icon">📊</div>
              <h3>My Crops</h3>
              <p>View all predictions</p>
            </div>
            <div class="action-card">
              <div class="action-icon">🤝</div>
              <h3>Find Services</h3>
              <p>Connect with partners</p>
            </div>
            <div class="action-card">
              <div class="action-icon">💰</div>
              <h3>Sell Direct</h3>
              <p>Reach customers online</p>
            </div>
          </div>
        </div>

        <!-- Upload Form -->
        <div *ngIf="showUploadForm" class="upload-form">
          <h3>Upload Satellite Image</h3>
          <input type="file" accept="image/*" #fileInput (change)="onImageSelected($event)">
          <button class="btn btn-primary" (click)="predictCrop()" [disabled]="!selectedFile">
            {{ predicting ? 'Predicting...' : 'Get Prediction' }}
          </button>
          <button class="btn btn-secondary" (click)="showUploadForm = false">Cancel</button>
        </div>

        <!-- Prediction Result -->
        <div *ngIf="predictionResult" class="prediction-result">
          <h3>🎯 Prediction Result</h3>
          <div class="result-card">
            <div class="crop-name">{{ predictionResult.crop }}</div>
            <div class="confidence" [class]="predictionResult.confidence > 0.9 ? 'high' : 'medium'">
              {{ (predictionResult.confidence * 100).toFixed(0) }}% Confident
            </div>
            <div class="health-status" [class]="predictionResult.health">
              Health: {{ predictionResult.health }}
            </div>
            <div class="area">Area: {{ predictionResult.area_sqm }} sq. meters</div>
            <div class="risks">
              <strong>Risk Factors:</strong>
              <ul>
                <li *ngFor="let risk of predictionResult.risk_factors">{{ risk }}</li>
              </ul>
            </div>
            <div class="recommendations">
              <strong>Recommendations:</strong>
              <ul>
                <li *ngFor="let rec of predictionResult.recommendations">{{ rec }}</li>
              </ul>
            </div>
          </div>
        </div>

        <!-- Recent Crops -->
        <div class="section">
          <h2>Recent Crops</h2>
          <div class="crops-list">
            <div class="crop-item">
              <span>🍅 Tomato</span>
              <span class="confidence high">92%</span>
            </div>
            <div class="crop-item">
              <span>🌾 Wheat</span>
              <span class="confidence medium">87%</span>
            </div>
            <div class="crop-item">
              <span>🥬 Spinach</span>
              <span class="confidence high">94%</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Service Partner Dashboard -->
      <div *ngIf="currentUser.role === 'partner'" class="dashboard partner-dash">
        <div class="dash-header">
          <h1>🤝 Market Intelligence</h1>
          <p>Find opportunities in your coverage area</p>
        </div>

        <div class="section">
          <h2>Farmers by Crop Type</h2>
          <div class="market-grid">
            <div class="market-card">
              <div class="crop-emoji">🍅</div>
              <h3>Tomato</h3>
              <p class="count">42 farmers</p>
              <button class="btn btn-small">View Leads</button>
            </div>
            <div class="market-card">
              <div class="crop-emoji">🌾</div>
              <h3>Wheat</h3>
              <p class="count">28 farmers</p>
              <button class="btn btn-small">View Leads</button>
            </div>
            <div class="market-card">
              <div class="crop-emoji">🌽</div>
              <h3>Cotton</h3>
              <p class="count">15 farmers</p>
              <button class="btn btn-small">View Leads</button>
            </div>
          </div>
        </div>

        <div class="section">
          <h2>Your Services</h2>
          <div class="services-list">
            <div class="service-item">
              <span>🧪 Fertilizer Supply</span>
              <span class="rating">⭐ 4.8/5</span>
            </div>
            <div class="service-item">
              <span>🪲 Pest Management</span>
              <span class="rating">⭐ 4.6/5</span>
            </div>
            <div class="service-item">
              <span>💧 Irrigation Setup</span>
              <span class="rating">⭐ 4.9/5</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Customer Dashboard -->
      <div *ngIf="currentUser.role === 'customer'" class="dashboard customer-dash">
        <div class="dash-header">
          <h1>🛒 Fresh Marketplace</h1>
          <p>Buy directly from verified farmers</p>
        </div>

        <div class="section">
          <h2>Featured Farmers</h2>
          <div class="farmers-grid">
            <div class="farmer-card">
              <div class="farmer-avatar">👨‍🌾</div>
              <h3>Yogesh's Farm</h3>
              <p class="location">📍 10 km away</p>
              <p class="rating">⭐⭐⭐⭐⭐ (4.8)</p>
              <div class="crops">
                <span class="crop-badge">🍅 Tomato</span>
                <span class="crop-badge">🥒 Cucumber</span>
              </div>
              <button class="btn btn-small">View Profile</button>
            </div>
            <div class="farmer-card">
              <div class="farmer-avatar">👩‍🌾</div>
              <h3>Ramesh's Fields</h3>
              <p class="location">📍 15 km away</p>
              <p class="rating">⭐⭐⭐⭐ (4.6)</p>
              <div class="crops">
                <span class="crop-badge">🌾 Wheat</span>
                <span class="crop-badge">🌽 Corn</span>
              </div>
              <button class="btn btn-small">View Profile</button>
            </div>
          </div>
        </div>
      </div>

      <!-- Call Center Dashboard -->
      <div *ngIf="currentUser.role === 'callcenter'" class="dashboard callcenter-dash">
        <div class="dash-header">
          <h1>📞 Support Dashboard</h1>
          <p>Manage user support tickets</p>
        </div>

        <div class="stats-row">
          <div class="stat-card">
            <div class="stat-number">12</div>
            <div class="stat-label">New Tickets</div>
          </div>
          <div class="stat-card">
            <div class="stat-number">45</div>
            <div class="stat-label">Today</div>
          </div>
          <div class="stat-card">
            <div class="stat-number">156</div>
            <div class="stat-label">This Week</div>
          </div>
        </div>

        <div class="section">
          <h2>High Priority Tickets</h2>
          <div class="tickets-list">
            <div class="ticket-item high">
              <span>New farmer: Can't upload image</span>
              <button class="btn btn-tiny">Resolve</button>
            </div>
            <div class="ticket-item high">
              <span>Partner: Not seeing market data</span>
              <button class="btn btn-tiny">Resolve</button>
            </div>
          </div>
        </div>
      </div>

      <!-- Tech Support Dashboard -->
      <div *ngIf="currentUser.role === 'techsupport'" class="dashboard techsupport-dash">
        <div class="dash-header">
          <h1>🔧 System Monitoring</h1>
          <p>Status: 🟢 All systems operational</p>
        </div>

        <div class="stats-row">
          <div class="stat-card">
            <div class="stat-number">142ms</div>
            <div class="stat-label">API Response</div>
          </div>
          <div class="stat-card">
            <div class="stat-number">2.3s</div>
            <div class="stat-label">Model Inference</div>
          </div>
          <div class="stat-card">
            <div class="stat-number">98%</div>
            <div class="stat-label">Uptime</div>
          </div>
        </div>

        <div class="section">
          <h2>Model Management</h2>
          <div class="buttons-row">
            <button class="btn btn-small">View Metrics</button>
            <button class="btn btn-small">Deploy New Version</button>
            <button class="btn btn-small">View Logs</button>
          </div>
        </div>
      </div>

      <!-- Admin Dashboard -->
      <div *ngIf="currentUser.role === 'admin'" class="dashboard admin-dash">
        <div class="dash-header">
          <h1>👨‍💼 Platform Management</h1>
          <p>Overview and control panel</p>
        </div>

        <div class="stats-row">
          <div class="stat-card">
            <div class="stat-number">1,234</div>
            <div class="stat-label">Total Users</div>
          </div>
          <div class="stat-card">
            <div class="stat-number">₹45.6L</div>
            <div class="stat-label">Total GMV</div>
          </div>
          <div class="stat-card">
            <div class="stat-number">₹22.8L</div>
            <div class="stat-label">Commissions</div>
          </div>
        </div>

        <div class="section">
          <h2>Quick Admin Tasks</h2>
          <div class="buttons-row">
            <button class="btn btn-small">Manage Users</button>
            <button class="btn btn-small">View Reports</button>
            <button class="btn btn-small">Approve KYC</button>
            <button class="btn btn-small">Configure Settings</button>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .dashboard-container {
      min-height: 100vh;
      background: #f8f9fa;
      padding: 20px;
    }

    .dashboard {
      max-width: 1200px;
      margin: 0 auto;
    }

    .dash-header {
      background: linear-gradient(135deg, #2e7d32 0%, #1b5e20 100%);
      color: white;
      padding: 30px;
      border-radius: 12px;
      margin-bottom: 30px;
    }

    .dash-header h1 { margin: 0 0 10px 0; font-size: 28px; }
    .dash-header p { margin: 0; opacity: 0.9; }

    .section {
      background: white;
      padding: 25px;
      border-radius: 12px;
      margin-bottom: 25px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.05);
    }

    .section h2 {
      margin: 0 0 20px 0;
      color: #333;
      font-size: 20px;
    }

    /* Farmer Dashboard */
    .action-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 15px;
    }

    .action-card {
      background: linear-gradient(135deg, #f0f9ff 0%, #e0f7fa 100%);
      padding: 20px;
      border-radius: 10px;
      cursor: pointer;
      transition: all 0.3s;
      border-left: 4px solid #2e7d32;
    }

    .action-card:hover {
      transform: translateY(-3px);
      box-shadow: 0 6px 12px rgba(46, 125, 50, 0.15);
    }

    .action-icon { font-size: 32px; margin-bottom: 10px; }
    .action-card h3 { margin: 10px 0 5px 0; color: #333; }
    .action-card p { margin: 0; color: #666; font-size: 12px; }

    .upload-form {
      background: #f5f5f5;
      padding: 20px;
      border-radius: 10px;
      margin-bottom: 20px;
    }

    .upload-form input {
      display: block;
      margin: 10px 0;
      padding: 10px;
      border: 1px solid #ddd;
      border-radius: 6px;
      width: 100%;
    }

    .prediction-result {
      background: #f0fdf4;
      padding: 20px;
      border-radius: 10px;
      border-left: 4px solid #2e7d32;
      margin-bottom: 20px;
    }

    .result-card {
      background: white;
      padding: 20px;
      border-radius: 8px;
    }

    .crop-name {
      font-size: 24px;
      font-weight: bold;
      color: #2e7d32;
      margin-bottom: 10px;
    }

    .confidence {
      display: inline-block;
      padding: 8px 12px;
      border-radius: 6px;
      margin-bottom: 10px;
    }

    .confidence.high { background: #d4edda; color: #155724; }
    .confidence.medium { background: #fff3cd; color: #856404; }

    .health-status {
      padding: 8px 12px;
      border-radius: 6px;
      margin-bottom: 10px;
      display: inline-block;
      margin-left: 10px;
    }

    .health-status.Good { background: #d4edda; color: #155724; }
    .health-status.Monitor { background: #fff3cd; color: #856404; }
    .health-status.Risky { background: #f8d7da; color: #721c24; }

    .area, .risks, .recommendations {
      margin-top: 10px;
      line-height: 1.6;
    }

    .crops-list, .services-list, .tickets-list {
      display: flex;
      flex-direction: column;
      gap: 10px;
    }

    .crop-item, .service-item, .ticket-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px;
      background: #f8f9fa;
      border-radius: 6px;
      border-left: 3px solid #2e7d32;
    }

    .confidence { display: inline-block; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
    .confidence.high { background: #d4edda; color: #155724; }
    .confidence.medium { background: #fff3cd; color: #856404; }

    .rating { color: #f59e0b; }

    /* Market & Farmer Cards */
    .market-grid, .farmers-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 20px;
    }

    .market-card, .farmer-card {
      background: #f8f9fa;
      padding: 20px;
      border-radius: 10px;
      text-align: center;
      border: 1px solid #e0e0e0;
    }

    .crop-emoji { font-size: 48px; margin-bottom: 10px; }
    .farmer-avatar { font-size: 48px; margin-bottom: 10px; }

    .market-card h3, .farmer-card h3 { margin: 10px 0 5px 0; color: #333; }
    .count { color: #666; font-weight: bold; }
    .location { color: #999; font-size: 12px; }
    .rating { color: #f59e0b; font-size: 14px; }

    .crops { display: flex; gap: 5px; flex-wrap: wrap; justify-content: center; margin: 10px 0; }
    .crop-badge { background: #e8f5e9; color: #2e7d32; padding: 4px 8px; border-radius: 4px; font-size: 12px; }

    /* Stats */
    .stats-row {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 20px;
      margin-bottom: 20px;
    }

    .stat-card {
      background: white;
      padding: 20px;
      border-radius: 10px;
      text-align: center;
      border-left: 4px solid #2e7d32;
      box-shadow: 0 2px 8px rgba(0,0,0,0.05);
    }

    .stat-number { font-size: 32px; font-weight: bold; color: #2e7d32; margin-bottom: 5px; }
    .stat-label { color: #666; font-size: 14px; }

    /* Buttons */
    .btn {
      padding: 10px 16px;
      border: none;
      border-radius: 6px;
      cursor: pointer;
      font-size: 14px;
      font-weight: 600;
      transition: all 0.3s;
    }

    .btn-primary { background: #2e7d32; color: white; }
    .btn-primary:hover { background: #1b5e20; }

    .btn-secondary { background: #f0f0f0; color: #333; }
    .btn-secondary:hover { background: #e0e0e0; }

    .btn-small { padding: 8px 12px; font-size: 12px; margin-right: 10px; }
    .btn-tiny { padding: 6px 10px; font-size: 11px; }

    .buttons-row { display: flex; flex-wrap: wrap; gap: 10px; }

    @media (max-width: 768px) {
      .action-grid, .market-grid, .farmers-grid, .stats-row {
        grid-template-columns: 1fr;
      }
    }
  `]
})
export class UnifiedDashboardComponent implements OnInit {
  currentUser: User | null = null;
  showUploadForm = false;
  selectedFile: File | null = null;
  predicting = false;
  predictionResult: any = null;

  constructor(
    private auth: AuthService,
    private translation: TranslationService
  ) {}

  ngOnInit() {
    this.auth.getCurrentUser().subscribe(user => {
      this.currentUser = user;
    });
  }

  t(key: string): string {
    return this.translation.translate(key);
  }

  onImageSelected(event: any) {
    this.selectedFile = event.target.files?.[0] || null;
  }

  predictCrop() {
    if (!this.selectedFile) return;

    this.predicting = true;

    // Mock prediction - simulate API call
    setTimeout(() => {
      const mockPredictions = [
        { crop: '🍅 Tomato', confidence: 0.92, health: 'Good', area_sqm: 2500, risk_factors: ['Low moisture', 'Pest detection area'], recommendations: ['Increase irrigation', 'Apply preventive spray'] },
        { crop: '🌾 Wheat', confidence: 0.88, health: 'Monitor', area_sqm: 3000, risk_factors: ['Temperature spike'], recommendations: ['Monitor closely', 'Adjust watering'] },
        { crop: '🌽 Corn', confidence: 0.85, health: 'Good', area_sqm: 2000, risk_factors: [], recommendations: ['Continue normal care'] }
      ];

      this.predictionResult = mockPredictions[Math.floor(Math.random() * mockPredictions.length)];
      this.predicting = false;
      this.showUploadForm = false;
    }, 2000);
  }
}
