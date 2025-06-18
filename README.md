# Kuzikus R-Backend

Ein R-Backend für die Generierung von Baum-Zertifikaten als PDF-Dokumente.

## Features

- REST API mit Plumber
- PDF-Generierung mit RMarkdown
- Base64-Bildverarbeitung
- QR-Code-Generierung
- GPS-Koordinaten-Formatierung
- CORS-Unterstützung
- Fehlerbehandlung

## Installation

1. **R installieren** (falls noch nicht geschehen):

   - [R Download](https://cran.r-project.org/)

2. **Erforderliche Pakete installieren**:
   ```bash
   Rscript package.R
   ```

## Verwendung

### Backend starten

```bash
Rscript api.R
```

Das Backend läuft dann auf `http://localhost:8000`

### API-Endpunkte

#### POST /generate-certificate

Generiert ein Baum-Zertifikat als PDF.

**Request Body:**

```json
{
  "certificate": {
    "owner": "Dennis Schaible",
    "occasion": "Hochzeit",
    "expiryDate": "2026-06-17",
    "treeId": "VE-229",
    "photographer": "Friedrich",
    "createdAt": "2025-06-18T07:02:54.466Z"
  },
  "image": {
    "fileName": "metadata_test2.jpeg",
    "fileSize": 2109683,
    "fileType": "image/jpeg",
    "hasMetadata": true,
    "base64Data": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAgEASABIAAD..."
  },
  "metadata": {
    "dateTime": "2025-06-18T05:24:36.000Z",
    "make": "Apple",
    "model": "iPhone 14 Pro",
    "imageWidth": 4032,
    "imageHeight": 3024,
    "gpsLatitude": [9, 33, 12.08],
    "gpsLongitude": [100, 3, 0.53],
    "software": "18.5",
    "copyright": null
  },
  "generation": {
    "format": "pdf",
    "template": "tree-certificate",
    "includeQrCode": true,
    "includeMetadata": true,
    "includeLocation": true
  }
}
```

**Response:** PDF-Datei als Binary-Stream

#### GET /health

Health-Check-Endpunkt.

**Response:**

```json
{
  "status": "OK",
  "message": "R-Backend läuft"
}
```

## Next.js Frontend Integration

```typescript
// Beispiel für Next.js Frontend
const generateCertificate = async (data: CertificateData) => {
  try {
    const response = await fetch("http://localhost:8000/generate-certificate", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      throw new Error("PDF-Generierung fehlgeschlagen");
    }

    // PDF als Blob herunterladen
    const blob = await response.blob();
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "baum_zertifikat.pdf";
    a.click();
    window.URL.revokeObjectURL(url);
  } catch (error) {
    console.error("Fehler:", error);
  }
};
```

## Dateistruktur

```
kuzikus-r-backend/
├── api.R              # Haupt-API-Datei
├── package.R          # Paket-Installation
├── zertifikat.Rmd     # PDF-Template
├── generate.R         # Standalone-Generierung
├── input.json         # Beispiel-Eingabedaten
├── zertifikat.pdf     # Beispiel-Ausgabe
└── README.md          # Diese Datei
```

## Entwicklung

### Lokale Tests

```bash
# Pakete installieren
Rscript package.R

# API starten
Rscript api.R

# In einem anderen Terminal testen
curl -X GET http://localhost:8000/health
```

### Standalone-Generierung

```bash
# PDF mit lokalen Daten generieren
Rscript generate.R
```

## Fehlerbehebung

1. **Port bereits belegt**: Ändere den Port in `api.R` (Zeile 67)
2. **Pakete fehlen**: Führe `Rscript package.R` aus
3. **CORS-Fehler**: Das Backend unterstützt bereits CORS
4. **PDF-Generierung fehlgeschlagen**: Prüfe die R-Logs auf Fehlermeldungen

## Lizenz

Proprietär - Kuzikus
.
