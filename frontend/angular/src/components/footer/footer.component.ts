import { Component } from '@angular/core';

@Component({
  selector: 'app-footer',
  standalone: true,
  template: `
    <footer class="bg-dark text-white text-center py-4 mt-5">
      <div class="container-fluid">
        <p class="mb-0">
          © 2025 crop-ai · Crop Identification using Satellite Imagery
        </p>
        <p class="small text-muted mt-2">
          Powered by Angular, Django, and FastAPI
        </p>
      </div>
    </footer>
  `,
  styles: [`
    footer {
      margin-top: auto;
    }
  `]
})
export class FooterComponent {}
