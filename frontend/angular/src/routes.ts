import { Routes } from '@angular/router';
import { LandingComponent } from './components/landing/landing.component';
import { LoginComponent } from './components/login/login.component';
import { RoleSelectionComponent } from './components/role-selection/role-selection.component';
import { UnifiedDashboardComponent } from './components/unified-dashboard/unified-dashboard.component';
import { authGuard } from './services/auth.guard';

export const routes: Routes = [
  {
    path: '',
    component: LandingComponent
  },
  {
    path: 'login',
    component: LoginComponent
  },
  {
    path: 'role-selection',
    component: RoleSelectionComponent,
    canActivate: [authGuard]
  },
  {
    path: 'dashboard',
    component: UnifiedDashboardComponent,
    canActivate: [authGuard]
  },
  {
    path: '**',
    redirectTo: '/'
  }
];
