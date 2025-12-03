import { Routes } from '@angular/router';
import { PredictComponent } from './components/predict.component';
import { DashboardComponent } from './components/dashboard.component';

export const routes: Routes = [
  {
    path: '',
    component: PredictComponent
  },
  {
    path: 'predict',
    component: PredictComponent
  },
  {
    path: 'dashboard',
    component: DashboardComponent
  },
  {
    path: '**',
    redirectTo: ''
  }
];
