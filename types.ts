// TypeScript definitions for the R-Backend API

export interface CertificateData {
  certificate: Certificate;
  image: ImageData;
  metadata: ImageMetadata;
  generation: GenerationOptions;
}

export interface Certificate {
  owner: string;
  occasion: string;
  expiryDate: string;
  treeId: string;
  photographer: string;
  createdAt: string;
}

export interface ImageData {
  fileName: string;
  fileSize: number;
  fileType: string;
  hasMetadata: boolean;
  base64Data: string;
}

export interface ImageMetadata {
  dateTime: string;
  make: string;
  model: string;
  imageWidth: number;
  imageHeight: number;
  gpsLatitude: [number, number, number];
  gpsLongitude: [number, number, number];
  software: string;
  copyright: string | null;
}

export interface GenerationOptions {
  format: "pdf";
  template: "tree-certificate";
  includeQrCode: boolean;
  includeMetadata: boolean;
  includeLocation: boolean;
}

export interface HealthResponse {
  status: "OK";
  message: string;
}

export interface ErrorResponse {
  error: string;
}

// API client functions
export class CertificateAPI {
  private baseUrl: string;

  constructor(baseUrl: string = "http://localhost:8000") {
    this.baseUrl = baseUrl;
  }

  async generateCertificate(data: CertificateData): Promise<Blob> {
    const response = await fetch(`${this.baseUrl}/generate-certificate`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      const errorData: ErrorResponse = await response.json();
      throw new Error(errorData.error || "PDF-Generierung fehlgeschlagen");
    }

    return response.blob();
  }

  async checkHealth(): Promise<HealthResponse> {
    const response = await fetch(`${this.baseUrl}/health`);

    if (!response.ok) {
      throw new Error("Health-Check fehlgeschlagen");
    }

    return response.json();
  }

  async downloadCertificate(
    data: CertificateData,
    filename?: string
  ): Promise<void> {
    try {
      const blob = await this.generateCertificate(data);
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = filename || `baum_zertifikat_${data.certificate.treeId}.pdf`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      window.URL.revokeObjectURL(url);
    } catch (error) {
      console.error("Fehler beim Herunterladen des Zertifikats:", error);
      throw error;
    }
  }
}

// Example usage:
/*
const api = new CertificateAPI();

// Health check
try {
  const health = await api.checkHealth();
  console.log('Backend Status:', health.status);
} catch (error) {
  console.error('Backend nicht erreichbar:', error);
}

// Generate and download certificate
const certificateData: CertificateData = {
  certificate: {
    owner: "Dennis Schaible",
    occasion: "Hochzeit",
    expiryDate: "2026-06-17",
    treeId: "VE-229",
    photographer: "Friedrich",
    createdAt: new Date().toISOString()
  },
  image: {
    fileName: "test.jpg",
    fileSize: 1234567,
    fileType: "image/jpeg",
    hasMetadata: true,
    base64Data: "data:image/jpeg;base64,/9j/4AAQSkZJRgABAgEASABIAAD..."
  },
  metadata: {
    dateTime: "2025-06-18T05:24:36.000Z",
    make: "Apple",
    model: "iPhone 14 Pro",
    imageWidth: 4032,
    imageHeight: 3024,
    gpsLatitude: [9, 33, 12.08],
    gpsLongitude: [100, 3, 0.53],
    software: "18.5",
    copyright: null
  },
  generation: {
    format: "pdf",
    template: "tree-certificate",
    includeQrCode: true,
    includeMetadata: true,
    includeLocation: true
  }
};

try {
  await api.downloadCertificate(certificateData);
  console.log('Zertifikat erfolgreich heruntergeladen');
} catch (error) {
  console.error('Fehler bei der Zertifikatsgenerierung:', error);
}
*/
