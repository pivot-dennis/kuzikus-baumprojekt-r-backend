# Install required R packages for the backend
# Run this script once to install all dependencies

required_packages <- c(
  "plumber",      # API framework
  "jsonlite",     # JSON handling
  "glue",         # String interpolation
  "uuid",         # UUID generation
  "fs",           # File system operations
  "rmarkdown",    # PDF generation
  "base64enc",    # Base64 encoding/decoding
  "qrcode",       # QR code generation
  "knitr"         # R Markdown processing
)

# Function to install packages if not already installed
install_if_missing <- function(packages) {
  for (package in packages) {
    if (!require(package, character.only = TRUE, quietly = TRUE)) {
      cat("Installing package:", package, "\n")
      install.packages(package, repos = "https://cran.rstudio.com/")
    } else {
      cat("Package", package, "is already installed\n")
    }
  }
}

# Install all required packages
cat("Installing required R packages...\n")
install_if_missing(required_packages)

cat("All packages installed successfully!\n")
cat("You can now run the API with: Rscript api.R\n") 