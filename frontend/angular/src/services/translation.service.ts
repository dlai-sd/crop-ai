import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class TranslationService {
  private currentLanguage$ = new BehaviorSubject<string>('en');

  private translations = {
    en: { 
      appTitle: 'CropAI', 
      login: 'Login', 
      selectRole: 'Select Your Role',
      farmer: 'Farmer',
      servicePartner: 'Service Partner', 
      customer: 'Customer',
      logout: 'Logout',
      loginWithGoogle: 'Login with Google',
      loginWithFacebook: 'Login with Facebook',
      email: 'Email',
      password: 'Password',
      aadhaarVerification: 'AADHAAR Verification Coming',
      phase2: 'Phase 2'
    },
    hi: { 
      appTitle: 'CropAI', 
      login: 'लॉगिन', 
      selectRole: 'अपनी भूमिका चुनें',
      farmer: 'किसान',
      servicePartner: 'सेवा भागीदार',
      customer: 'ग्राहक',
      logout: 'लॉग आउट',
      loginWithGoogle: 'Google से लॉगिन करें',
      loginWithFacebook: 'Facebook से लॉगिन करें',
      email: 'ईमेल',
      password: 'पासवर्ड',
      aadhaarVerification: 'AADHAAR सत्यापन जल्द आ रहा है',
      phase2: 'चरण 2'
    }
  };

  constructor() {
    const savedLang = localStorage.getItem('language') || 'en';
    this.currentLanguage$.next(savedLang);
  }

  getLanguage(): Observable<string> {
    return this.currentLanguage$.asObservable();
  }

  setLanguage(lang: string) {
    this.currentLanguage$.next(lang);
    localStorage.setItem('language', lang);
  }

  getCurrentLanguage(): string {
    return this.currentLanguage$.value;
  }

  translate(key: string): string {
    const lang = this.currentLanguage$.value;
    return (this.translations as any)[lang]?.[key] || (this.translations as any)['en']?.[key] || key;
  }
}
