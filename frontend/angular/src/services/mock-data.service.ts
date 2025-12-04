import { Injectable } from '@angular/core';

export interface Farmer {
  id: string;
  name: string;
  emoji: string;
  rating: number;
  distance: number;
  crops: { emoji: string; name: string }[];
}

export interface MarketData {
  crop: string;
  emoji: string;
  farmerCount: number;
}

export interface ServicePartnerService {
  name: string;
  emoji: string;
  rating: number;
}

@Injectable({
  providedIn: 'root'
})
export class MockDataService {
  getFarmersData(): Farmer[] {
    return [
      {
        id: '1',
        name: "Yogesh's Farm",
        emoji: '👨‍🌾',
        rating: 4.8,
        distance: 10,
        crops: [
          { emoji: '🍅', name: 'Tomato' },
          { emoji: '🥒', name: 'Cucumber' }
        ]
      },
      {
        id: '2',
        name: "Ramesh's Fields",
        emoji: '👩‍🌾',
        rating: 4.6,
        distance: 15,
        crops: [
          { emoji: '🌾', name: 'Wheat' },
          { emoji: '🌽', name: 'Corn' }
        ]
      },
      {
        id: '3',
        name: "Priya's Orchard",
        emoji: '👨‍🌾',
        rating: 4.9,
        distance: 8,
        crops: [
          { emoji: '🥕', name: 'Carrot' },
          { emoji: '🧅', name: 'Onion' }
        ]
      }
    ];
  }

  getMarketData(): MarketData[] {
    return [
      { crop: 'Tomato', emoji: '🍅', farmerCount: 42 },
      { crop: 'Wheat', emoji: '🌾', farmerCount: 28 },
      { crop: 'Cotton', emoji: '🌾', farmerCount: 15 },
      { crop: 'Corn', emoji: '🌽', farmerCount: 22 },
      { crop: 'Rice', emoji: '🍚', farmerCount: 35 }
    ];
  }

  getPartnerServices(): ServicePartnerService[] {
    return [
      { name: 'Fertilizer Supply', emoji: '🧪', rating: 4.8 },
      { name: 'Pest Management', emoji: '🪲', rating: 4.6 },
      { name: 'Irrigation Setup', emoji: '💧', rating: 4.9 }
    ];
  }

  getSupportTickets() {
    return [
      { id: 1, issue: 'New farmer: Can\'t upload image', priority: 'high', status: 'open' },
      { id: 2, issue: 'Partner: Not seeing market data', priority: 'high', status: 'open' },
      { id: 3, issue: 'Customer: Order not delivered', priority: 'medium', status: 'pending' }
    ];
  }

  getSystemMetrics() {
    return {
      apiResponse: 142,
      modelInference: 2.3,
      uptime: 98,
      lastChecked: new Date().toLocaleTimeString()
    };
  }

  getFinancialMetrics() {
    return {
      totalUsers: 1234,
      totalGMV: 4567890,
      totalCommissions: 2283945,
      activeTransactions: 156
    };
  }
}
