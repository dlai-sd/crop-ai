import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-landing',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './landing.component.html',
  styles: [`
    :root { --g: #D4AF37; --lg: #FFFEF0; --d: #333; --l: #666; --w: #fff; --gr: #f8f9fa; }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    .landing { font-family: Segoe UI, sans-serif; color: var(--d); }
    .header { background: var(--w); padding: 1rem 0; position: fixed; top: 0; width: 100%; z-index: 1000; box-shadow: 0 2px 8px rgba(0,0,0,.05); }
    .header-container { display: flex; justify-content: space-between; align-items: center; max-width: 1400px; margin: 0 auto; padding: 0 20px; }
    .logo-container { display: flex; align-items: center; gap: 10px; }
    .logo-img { width: 45px; height: 45px; border-radius: 8px; }
    .logo-text { font-size: 1.3rem; font-weight: 700; color: var(--g); }
    .nav-menu a { text-decoration: none; color: var(--d); font-weight: 500; }
    .nav-menu a:hover { color: var(--g); }
    .dropdown { position: relative; }
    .dropdown-content { display: none; position: absolute; background: var(--w); min-width: 200px; box-shadow: 0 8px 24px rgba(0,0,0,.1); border-radius: 8px; padding: .5rem 0; margin-top: .5rem; top: 100%; left: 0; }
    .dropdown:hover .dropdown-content { display: block; }
    .dropdown-content a { display: block; padding: .75rem 1.5rem; }
    .dropdown-content a:hover { background: var(--lg); }
    .header-controls { display: flex; align-items: center; gap: 1.2rem; }
    .language-select { padding: .6rem; border: 1px solid #e0e0e0; border-radius: 6px; background: var(--w); cursor: pointer; }
    .btn { padding: .7rem 1.8rem; border-radius: 6px; font-weight: 600; cursor: pointer; border: none; font-size: .95rem; transition: all .3s; }
    .btn-outline { background: transparent; border: 1px solid var(--g); color: var(--g); }
    .btn-primary { background: var(--g); color: var(--w); }
    .btn:hover { transform: translateY(-2px); }
    .hero { padding: 10rem 0 6rem; background: var(--w); margin-top: 60px; }
    .hero-container { display: flex; flex-direction: column; max-width: 1400px; margin: 0 auto; padding: 0 20px; }
    .hero h1 { font-size: 3.2rem; margin-bottom: 2rem; text-align: center; font-weight: 700; }
    .map-analytics-section { display: flex; gap: 2rem; margin-bottom: 2rem; height: 600px; }
    .map-container { flex: 0 0 65%; background: var(--w); display: flex; align-items: center; justify-content: center; position: relative; overflow: hidden; border-radius: 12px; border: 1px solid #e0e0e0; }
    .satellite-map-placeholder { text-align: center; color: var(--l); font-size: 1.2rem; }
    .crop-selection-overlay { position: absolute; top: 20px; left: 20px; z-index: 100; width: 350px; }
    .search-box { display: flex; width: 100%; box-shadow: 0 8px 24px rgba(0,0,0,.15); border-radius: 8px; overflow: hidden; }
    .search-box input { flex: 1; padding: 1rem 1.2rem; border: none; font-size: 1rem; background: var(--w); }
    .search-box input:focus { outline: none; }
    .search-box button { padding: 0 2rem; background: var(--g); color: var(--w); border: none; cursor: pointer; font-weight: 600; }
    .search-box button:hover { background: #C89A2E; }
    .analytics-panel { flex: 0 0 35%; background: var(--w); padding: 2rem; display: flex; flex-direction: column; border-radius: 12px; border: 1px solid #e0e0e0; }
    .risk-indicator { display: flex; align-items: center; margin-bottom: 1.5rem; padding: 1.2rem; border-radius: 10px; background: var(--lg); }
    .risk-icon { width: 48px; height: 48px; border-radius: 50%; background: linear-gradient(135deg, #ff9800, #f57c00); display: flex; align-items: center; justify-content: center; margin-right: 1.2rem; color: var(--w); font-weight: bold; font-size: 1.2rem; }
    .opportunity { padding: 1.5rem; border-radius: 10px; background: var(--lg); }
    .opportunity h4 { color: var(--g); margin-bottom: .8rem; }
    .user-toggle-container { display: flex; justify-content: center; margin-top: 2rem; }
    .user-toggle { display: flex; background: var(--gr); border-radius: 50px; padding: .4rem; max-width: 600px; width: 100%; }
    .toggle-option { flex: 1; text-align: center; padding: 1rem; border-radius: 50px; cursor: pointer; font-weight: 500; transition: all .3s; }
    .toggle-option.active { background: var(--g); color: var(--w); }
    .features { padding: 6rem 0; background: var(--w); }
    .section-subtitle { text-align: center; margin-bottom: 4rem; color: var(--l); font-size: 1.2rem; max-width: 700px; margin-left: auto; margin-right: auto; }
    .features-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 2rem; max-width: 1400px; margin: 0 auto; padding: 0 20px; }
    .feature-card { background: var(--w); padding: 3rem; border-radius: 12px; text-align: center; box-shadow: 0 5px 20px rgba(0,0,0,.05); transition: all .3s; }
    .feature-card:hover { transform: translateY(-10px); box-shadow: 0 15px 30px rgba(0,0,0,.1); }
    .feature-icon { font-size: 3.5rem; margin-bottom: 2rem; }
    .feature-card h3 { margin-bottom: 1.5rem; color: var(--g); font-size: 1.5rem; }
    .feature-card ul { list-style: none; text-align: left; }
    .feature-card li { margin-bottom: 1rem; color: var(--l); }
    .feature-card li:before { content: "•"; color: var(--g); margin-right: .5rem; }
    .about { padding: 6rem 0; background: var(--w); }
    .about-container { max-width: 1200px; margin: 0 auto; padding: 0 20px; }
    .about h2 { text-align: center; margin-bottom: 2rem; font-size: 2.5rem; color: var(--g); }
    .about-description { text-align: center; max-width: 800px; margin: 0 auto 4rem; font-size: 1.1rem; color: var(--l); line-height: 1.8; }
    .team-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 2.5rem; }
    .team-member { text-align: center; padding: 2rem; border-radius: 12px; }
    .team-member:hover { transform: translateY(-5px); }
    .member-image { width: 140px; height: 140px; border-radius: 50%; background: linear-gradient(135deg, #e0e0e0, #f5f5f5); margin: 0 auto 1.5rem; display: flex; align-items: center; justify-content: center; color: var(--l); font-size: 2.5rem; font-weight: 700; }
    .member-name { font-weight: 700; margin-bottom: .5rem; color: var(--g); font-size: 1.3rem; }
    .member-position { color: var(--l); margin-bottom: 1.2rem; font-weight: 500; }
    .footer { background: var(--d); color: var(--w); padding: 4rem 0 2rem; }
    .footer-container { max-width: 1200px; margin: 0 auto; padding: 0 20px; }
    .footer-content { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 3rem; margin-bottom: 3rem; }
    .footer-section h3 { margin-bottom: 1.8rem; color: var(--lg); font-size: 1.3rem; }
    .footer-section ul { list-style: none; }
    .footer-section li { margin-bottom: .8rem; }
    .footer-section a { color: #ccc; text-decoration: none; }
    .footer-section a:hover { color: var(--w); }
    .footer-section p { color: #ccc; margin-bottom: .8rem; }
    .footer-bottom { text-align: center; padding-top: 2.5rem; border-top: 1px solid #444; color: #ccc; }
    @media (max-width: 1024px) { .features-grid { grid-template-columns: repeat(2, 1fr); } .map-analytics-section { flex-direction: column; height: auto; } .map-container, .analytics-panel { flex: 0 0 100%; } .map-container { height: 400px; } }
    @media (max-width: 768px) { .header-container { flex-direction: column; gap: 1rem; } .nav-menu ul { flex-wrap: wrap; justify-content: center; gap: 1rem; } .hero h1 { font-size: 2.2rem; } .features-grid { grid-template-columns: 1fr; } .feature-card { padding: 2rem; } }
  `]
})
export class LandingComponent implements OnInit {
  private currentLanguage = 'en';

  constructor(private router: Router, private translationService: TranslationService) {
    this.translationService.getLanguage().subscribe(lang => {
      this.currentLanguage = lang;
    });
  }

  ngOnInit(): void {
    // Language subscription set in constructor
  }

  translate(key: string): string {
    const translations: { [key: string]: { [lang: string]: string } } = {
      'I Am': { en: 'I Am', hi: 'मैं हूँ', mr: 'मी आहे', gu: 'હું છું' },
      'Farmer': { en: 'Farmer', hi: 'किसान', mr: 'शेतकरी', gu: 'ખેડૂત' },
      'Partner': { en: 'Partner', hi: 'साथी', mr: 'भागीदार', gu: 'ભાગીદાર' },
      'Customer': { en: 'Customer', hi: 'ग्राहक', mr: 'ग्राहक', gu: 'ગ્રાહક' },
      'Our Offerings': { en: 'Our Offerings', hi: 'हमारे प्रस्ताव', mr: 'आमचे ऑफर', gu: 'આમારી ઓફરિંગ' },
      'For Farmers': { en: 'For Farmers', hi: 'किसानों के लिए', mr: 'शेतकऱ्यांसाठी', gu: 'ખેડૂતો માટે' },
      'For Partners': { en: 'For Partners', hi: 'साथियों के लिए', mr: 'भागीदारांसाठी', gu: 'ભાગીદારો માટે' },
      'For Customers': { en: 'For Customers', hi: 'ग्राहकों के लिए', mr: 'ग्राहकांसाठी', gu: 'ગ્રાહકો માટે' },
      'Blog': { en: 'Blog', hi: 'ब्लॉग', mr: 'ब्लॉग', gu: 'બ્લૉગ' },
      'About': { en: 'About', hi: 'के बारे में', mr: 'संबंधी', gu: 'વિશે' },
      'Contact': { en: 'Contact', hi: 'संपर्क', mr: 'संपर्क', gu: 'સંપર્ક' },
      'Login': { en: 'Login', hi: 'लॉगिन', mr: 'लॉगिन', gu: 'લૉગિન' },
      'Register': { en: 'Register', hi: 'रजिस्टर करें', mr: 'नोंदणी', gu: 'નોંધણી' },
      'Shall I plan this Crop?': { en: 'Shall I plan this Crop?', hi: 'क्या मुझे यह फसल लगानी चाहिए?', mr: 'मी हे पीक लावू?', gu: 'શું મારે આ પાક લગાવવો જોઈએ?' },
      'Select your crop': { en: 'Select your crop (e.g. Tomato, Peanut, Wheat)', hi: 'अपनी फसल चुनें', mr: 'आपली पीक निवडा', gu: 'તમારી પાક પસંદ કરો' },
      'Search': { en: 'Search', hi: 'खोज', mr: 'शोध', gu: 'શોધ' },
      'Satellite Map View': { en: 'Satellite Map View', hi: 'उपग्रह मानचित्र दृश्य', mr: 'उपग्रह नकाशा दृश्य', gu: 'ઉપગ્રહ નકશો દૃશ્ય' },
      'Current Crop Occupancy': { en: 'Current Crop Occupancy', hi: 'वर्तमान फसल दखल', mr: 'वर्तमान पीक व्यापन', gu: 'વર્તમાન પાક કબજો' },
      'Total Farm Land': { en: 'Total Farm Land', hi: 'कुल खेत भूमि', mr: 'एकूण शेत जमीन', gu: 'કુલ ખેતર જમીન' },
      'Opportunity Identified': { en: 'Opportunity Identified', hi: 'अवसर की पहचान की गई', mr: 'संधी ओळखली', gu: 'તક ઓળખાઇ' },
      'Weather message': { en: 'Weather is favorable for tomato crop for next 3-6 months', hi: 'आने वाले 3-6 महीने का मौसम टमाटर के लिए अनुकूल है', mr: 'पुढील 3-6 महिन्यांचे हवामान टोमॅटो पीकीसाठी अनुकूल', gu: 'આવતા 3-6 મહિનાનું હવામાન ટમેટો પાક માટે અનુકૂળ' },
      'I am a Farmer': { en: 'I am a Farmer', hi: 'मैं एक किसान हूँ', mr: 'मी एक शेतकरी आहे', gu: 'હું એક ખેડૂત છું' },
      'I am a Partner': { en: 'I am a Partner', hi: 'मैं एक साथी हूँ', mr: 'मी एक भागीदार आहे', gu: 'હું એક ભાગીદાર છું' },
      'I am a Customer': { en: 'I am a Customer', hi: 'मैं एक ग्राहक हूँ', mr: 'मी एक ग्राहक आहे', gu: 'હું એક ગ્રાહક છું' },
      'Platform subtitle': { en: 'Our comprehensive platform offers tailored solutions for every stakeholder', hi: 'हमारा मंच कृषि के प्रत्येक हितधारक के लिए समाधान प्रदान करता है', mr: 'आमचे प्लॅटफॉर्म कृषि के सभी भाग लेने वालों के लिए समाधान प्रदान करते हैं', gu: 'આમારો પ્લેટફર્મ આ દરેક હિતધારક માટે ઉકેલો પ્રદાન કરે છે' },
      'Empowering Farmers': { en: 'Empowering Farmers', hi: 'किसानों को सशक्त बनाना', mr: 'शेतकऱ्यांना सक्षम करणे', gu: 'ખેડૂતોને સશક્ત કરવા' },
      'Delighting Partners': { en: 'Delighting Partners', hi: 'भागीदारों को प्रसन्न करना', mr: 'भागीदारांना आनंदित करणे', gu: 'ભાગીદારોને આનંદિત કરવા' },
      'Liberating Customers': { en: 'Liberating Customers', hi: 'ग्राहकों को मुक्त करना', mr: 'ग्राहकांना मुक्त करणे', gu: 'ગ્રાહકોને મુક્ત કરવા' },
      'Manage Profile': { en: 'Manage Profile', hi: 'प्रोफ़ाइल प्रबंधित करें', mr: 'प्रोफाइल व्यवस्थापित करा', gu: 'પ્રોફાઇલ સંચાલન કરો' },
      'Actionable Insights': { en: 'Actionable Insights', hi: 'कार्ययोग्य अंतर्दृष्टि', mr: 'कार्यक्षम अंतर्दृष्टी', gu: 'કાર્યક્ષમ અંતર્દૃષ્ટિ' },
      'Request Service': { en: 'Request Service', hi: 'सेवा का अनुरोध करें', mr: 'सेवा विनंती करा', gu: 'સેવા વિનંતી કરો' },
      'Market Analytics': { en: 'Market Analytics', hi: 'बाजार विश्लेषण', mr: 'बाजार विश्लेषण', gu: 'બજાર વિશ્લેષણ' },
      'Lead Generation': { en: 'Lead Generation', hi: 'लीड जनरेशन', mr: 'लीड जनरेशन', gu: 'લીડ જનરેશન' },
      'Direct Purchase': { en: 'Direct Purchase', hi: 'सीधी खरीद', mr: 'थेट खरेदी', gu: 'સીધી ખરીદી' },
      'Doorstep Delivery': { en: 'Doorstep Delivery', hi: 'दरवाजे पर डिलीवरी', mr: 'घराच्या दारी डिलिव्हरी', gu: 'દરવાજે ડિલિવરી' },
      'About Us': { en: 'About Us', hi: 'हमारे बारे में', mr: 'आमच्या बद्दल', gu: 'અમારા વિશે' },
      'About description': { en: 'We are a multidisciplinary leadership team united by meaningful innovation.', hi: 'हम एक बहु-विषयक नेतृत्व दल हैं जो सार्थक नवाचार से जुड़े हैं।', mr: 'आम्ही एक बहु-शाखीय नेतृत्व संघ आहोत जो अर्थपूर्ण नवाचार से संयुक्त आहे.', gu: 'અમે એક બહુ-શાખીય નેતૃત્વ ટીમ છીએ જે અર્થપૂર્ણ નવાધર્મ સાથે જોડાયેલા છીએ.' },
      'Founder & Director': { en: 'Founder & Director', hi: 'संस्थापक और निदेशक', mr: 'संस्थापक आणि निर्देशक', gu: 'સંસ્થાપક અને નિર્દેશક' },
      'Head Sales & Marketing': { en: 'Head Sales & Marketing', hi: 'बिक्री और विपणन प्रमुख', mr: 'विक्रय आणि विपणन प्रमुख', gu: 'વિક્રય અને માર્કેટિંગ હેડ' },
      'Chief Information Officer': { en: 'Chief Information Officer', hi: 'मुख्य सूचना अधिकारी', mr: 'मुख्य माहिती अधिकारी', gu: 'મુખ્ય માહિતી અધિકારી' },
      'Quick Links': { en: 'Quick Links', hi: 'तेजी से लिंक', mr: 'द्रुत लिंक्स', gu: 'ઝડપી લિંક્સ' },
      'Services': { en: 'Services', hi: 'सेवाएं', mr: 'सेवा', gu: 'સેવાઓ' },
      'Contact Us': { en: 'Contact Us', hi: 'हमसे संपर्क करें', mr: 'आमच्याशी संपर्क साधा', gu: 'અમારો સંપર્ક કરો' },
      'Home': { en: 'Home', hi: 'होम', mr: 'घर', gu: 'હોમ' },
      'All rights reserved': { en: 'All rights reserved', hi: 'सर्वाधिकार सुरक्षित', mr: 'सर्व हक्क सुरक्षित', gu: 'બધા અધિકારો આરક્ષિત' }
    };

    const lang = this.currentLanguage;
    return translations[key]?.[lang] || translations[key]?.['en'] || key;
  }

  changeLanguage(event: any): void {
    const lang = event.target.value;
    this.currentLanguage = lang;
    this.translationService.setLanguage(lang);
  }

  selectRole(role: string): void {
    console.log('Selected role:', role);
  }

  goToLogin(): void {
    this.router.navigate(['/login']);
  }
}
