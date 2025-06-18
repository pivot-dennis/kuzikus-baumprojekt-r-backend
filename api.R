library(plumber)
library(jsonlite)
library(glue)
library(uuid)
library(fs)
library(rmarkdown)
library(base64enc)
library(qrcode)
library(knitr)

# Plumber API definieren
pr <- Plumber$new()

# CORS-Filter hinzufügen
pr$filter("cors", function(req, res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization")
  if (req$REQUEST_METHOD == "OPTIONS") {
    res$status <- 200
    return(list())
  } else {
    forward()
  }
})

# Hilfsfunktion für GPS-Koordinaten
formatGPS <- function(coords) {
  if (length(coords) == 3) {
    degrees <- coords[1]
    minutes <- coords[2]
    seconds <- coords[3]
    return(sprintf("%d° %d' %.2f\"", degrees, minutes, seconds))
  }
  return("Nicht verfügbar")
}

# /generate-certificate Endpoint (POST)
pr$handle("POST", "/generate-certificate", function(req, res){
  tryCatch({
    # JSON-Daten parsen
    body <- fromJSON(req$postBody, simplifyVector = FALSE)
    
    # Validierung der erforderlichen Felder
    if (is.null(body$certificate) || is.null(body$image) || is.null(body$generation)) {
      res$status <- 400
      return(list(error = "Fehlende erforderliche Felder"))
    }
    
    # Eindeutige ID generieren
    id <- UUIDgenerate()
    
    # Temporäre Dateien erstellen
    temp_rmd <- sprintf("temp_certificate_%s.Rmd", id)
    temp_pdf <- sprintf("certificate_%s.pdf", id)
    
    cat("Generating RMarkdown template...\n")
    
    # RMarkdown-Inhalt generieren
    rmd_content <- glue::glue(
'---
title: "Baum-Zertifikat"
output: pdf_document
geometry: margin=2cm
fontsize: 11pt
params:
  certificate: null
  imageBase64: null
  metadata: null
  generation: null
---

```{{r setup, include=FALSE}}
knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE)
library(base64enc)
library(qrcode)
library(knitr)

# Parameter extrahieren
certificate <- params$certificate
imageBase64 <- params$imageBase64
metadata <- params$metadata
generation <- params$generation

# QR-Code generieren falls gewünscht
qr_code_data <- NULL
if (generation$includeQrCode) {{
  tryCatch({{
    # Prüfen ob qrcode Paket verfügbar ist
    if (!require(qrcode, quietly = TRUE)) {{
      cat("qrcode package not available, skipping QR code generation\\n")
    }} else {{
      qr_data <- paste0(
        "Baum-ID: ", certificate$treeId, "\\n",
        "Besitzer: ", certificate$owner, "\\n",
        "Anlass: ", certificate$occasion, "\\n",
        "Gültig bis: ", certificate$expiryDate
      )
      # Verwende die korrekte Funktion aus dem qrcode Paket
      qr_code_data <- qr_code(qr_data)
    }}
  }}, error = function(e) {{
    cat("Fehler bei QR-Code-Generierung:", e$message, "\\n")
  }})
}}
```

# Baum-Zertifikat

## Zertifikatsdaten

**Besitzer:** `r certificate$owner`  
**Anlass:** `r certificate$occasion`  
**Baum-ID:** `r certificate$treeId`  
**Gültig bis:** `r certificate$expiryDate`  
**Fotograf:** `r certificate$photographer`  
**Erstellt am:** `r as.Date(certificate$createdAt)`

```{{r image, echo=FALSE}}
# Bild einbetten falls vorhanden
if (!is.null(imageBase64) && nchar(imageBase64) > 0) {{
  tryCatch({{
    # Base64-Daten extrahieren (ohne data:image/... prefix)
    base64_data <- sub("^data:image/[^;]+;base64,", "", imageBase64)
    
    # Temporäre Bilddatei erstellen
    temp_img <- tempfile(fileext = ".jpg")
    writeBin(base64enc::base64decode(base64_data), temp_img)
    
    # Bild einbetten
    include_graphics(temp_img, dpi = 300)
    
    # Temporäre Datei löschen
    unlink(temp_img)
  }}, error = function(e) {{
    cat("Fehler beim Bild einbetten:", e$message, "\\n")
  }})
}}
```

```{{r metadata, echo=FALSE}}
# Metadaten anzeigen falls gewünscht
if (generation$includeMetadata && !is.null(metadata)) {{
  cat("## Bildmetadaten\\n\\n")
  cat("**Aufnahmedatum:** ", as.POSIXct(metadata$dateTime, format="%Y-%m-%dT%H:%M:%S"), "\\n")
  cat("**Kamera:** ", metadata$make, " ", metadata$model, "\\n")
  cat("**Auflösung:** ", metadata$imageWidth, " x ", metadata$imageHeight, " Pixel\\n")
  cat("**Software:** ", metadata$software, "\\n")
  
  if (generation$includeLocation && !is.null(metadata$gpsLatitude) && !is.null(metadata$gpsLongitude)) {{
    lat_str <- metadata$gpsLatitude[1] + metadata$gpsLatitude[2]/60 + metadata$gpsLatitude[3]/3600
    lon_str <- metadata$gpsLongitude[1] + metadata$gpsLongitude[2]/60 + metadata$gpsLongitude[3]/3600
    cat("**Standort:** ", lat_str, " / ", lon_str, "\\n")
  }}
}}
```

```{{r qrcode, echo=FALSE}}
# QR-Code anzeigen falls gewünscht
if (generation$includeQrCode && !is.null(qr_code_data)) {{
  cat("## QR-Code\\n\\n")
  plot(qr_code_data, col = c("white", "black"), 
       main = "Scan für Zertifikatsdetails", 
       cex.main = 0.8)
}}
```

---
*Dieses Zertifikat wurde automatisch generiert und ist gültig bis zum angegebenen Datum.*
'
    )
    
    # RMarkdown-Datei schreiben
    writeLines(rmd_content, temp_rmd)
    cat("RMarkdown template written to:", temp_rmd, "\n")
    
    # PDF generieren mit detailliertem Logging
    cat("Starting PDF generation...\n")
    render_result <- tryCatch({
      rmarkdown::render(
        temp_rmd, 
        output_file = temp_pdf, 
        quiet = FALSE,  # Zeige Logs
        params = list(
          certificate = body$certificate,
          imageBase64 = body$image$base64Data,
          metadata = body$metadata,
          generation = body$generation
        )
      )
    }, error = function(e) {
      cat("Error during PDF rendering:", e$message, "\n")
      stop(e)
    })
    
    cat("PDF generation completed. File:", temp_pdf, "\n")
    
    # Prüfen ob PDF existiert
    if (!file.exists(temp_pdf)) {
      stop("PDF file was not created")
    }
    
    # PDF-Daten lesen
    pdf_data <- readBin(temp_pdf, what = "raw", n = file.info(temp_pdf)$size)
    cat("PDF data read, size:", length(pdf_data), "bytes\n")
    
    # Temporäre Dateien löschen
    file_delete(temp_rmd)
    file_delete(temp_pdf)
    cat("Temporary files cleaned up\n")
    
    # Response senden
    res$setHeader("Content-Type", "application/pdf")
    res$setHeader("Content-Disposition", sprintf("attachment; filename=\"baum_zertifikat_%s.pdf\"", id))
    return(pdf_data)
    
  }, error = function(e) {
    # Fehlerbehandlung
    cat("Error in generate-certificate endpoint:", e$message, "\n")
    res$status <- 500
    return(list(error = paste("Fehler bei der PDF-Generierung:", e$message)))
  })
})

# Health Check Endpoint
pr$handle("GET", "/health", function(req, res) {
  return(list(status = "OK", message = "R-Backend läuft"))
})

# API starten
cat("Starting R-Backend API on port 8000...\n")
pr$run(host = "0.0.0.0", port = 8000)
