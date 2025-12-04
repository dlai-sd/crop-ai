import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

export interface User {
  id: string;
  name: string;
  email: string;
  role: 'farmer' | 'partner' | 'customer' | 'callcenter' | 'techsupport' | 'admin';
  avatar?: string;
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private currentUser$ = new BehaviorSubject<User | null>(null);
  private isAuthenticated$ = new BehaviorSubject<boolean>(false);

  constructor() {
    const savedUser = localStorage.getItem('currentUser');
    if (savedUser) {
      const user = JSON.parse(savedUser);
      this.currentUser$.next(user);
      this.isAuthenticated$.next(true);
    }
  }

  getCurrentUser(): Observable<User | null> {
    return this.currentUser$.asObservable();
  }

  isAuthenticated(): Observable<boolean> {
    return this.isAuthenticated$.asObservable();
  }

  login(user: User) {
    this.currentUser$.next(user);
    this.isAuthenticated$.next(true);
    localStorage.setItem('currentUser', JSON.stringify(user));
  }

  logout() {
    this.currentUser$.next(null);
    this.isAuthenticated$.next(false);
    localStorage.removeItem('currentUser');
  }

  // Mock SSO logins
  loginWithGoogle(email: string, name: string) {
    const user: User = {
      id: 'google_' + Math.random().toString(36).substr(2, 9),
      email,
      name,
      role: 'farmer'
    };
    this.login(user);
    return user;
  }

  loginWithFacebook(email: string, name: string) {
    const user: User = {
      id: 'facebook_' + Math.random().toString(36).substr(2, 9),
      email,
      name,
      role: 'farmer'
    };
    this.login(user);
    return user;
  }

  setUserRole(role: User['role']) {
    const user = this.currentUser$.value;
    if (user) {
      user.role = role;
      this.currentUser$.next({ ...user });
      localStorage.setItem('currentUser', JSON.stringify(user));
    }
  }
}
