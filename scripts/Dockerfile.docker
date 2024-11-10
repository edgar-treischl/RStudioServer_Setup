# Use the official R image from Docker Hub
FROM rocker/r-ver:4.2.2

# Install system dependencies required for PDF generation (LaTeX, etc.)
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libxml2-dev \
    libssl-dev \
    texlive \
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-latex-extra \
    pandoc \
    wget \
    unzip

# Install R packages for R Markdown, knitr, and TinyTeX
RUN R -e "install.packages(c('rmarkdown', 'knitr', 'tinytex'))"

# Set the working directory inside the container
WORKDIR /workspace

# Copy the entire local directory into the container (ensure your Rmd file is included)
COPY . /workspace/

# Force TinyTeX installation (no large TeX distribution installed)
RUN R -e "tinytex::install_tinytex(force = TRUE)"

# Run the RMarkdown rendering command when the container starts (adjust file path if needed)
CMD ["Rscript", "-e", "rmarkdown::render('/workspace/your_report.Rmd', output_format='pdf_document')"]
