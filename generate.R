# generate.R
library(rmarkdown)
library(jsonlite)

# JSON-Daten einlesen
data <- fromJSON("input.json", simplifyVector = FALSE)

# RMarkdown rendern
render("zertifikat.Rmd",
  output_file = "zertifikat.pdf",
  params = list(
    certificate = data$certificate,
    imageBase64 = data$image$base64Data,
    metadata = data$metadata,
    includeQrCode = data$generation$includeQrCode
  )
)
