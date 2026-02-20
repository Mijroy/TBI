# Install all R packages required for the TBI analysis pipeline.
# Run once interactively before knitting any Rmd.
#
# Bioconductor 3.19 targets R >= 4.4.

if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install(version = "3.19", ask = FALSE)

cran_pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2
  "here",         # project-relative paths
  "ggrepel",      # non-overlapping labels
  "patchwork",    # plot composition
  "RColorBrewer", # colour palettes
  "viridis",      # perceptually uniform colours
  "pheatmap",     # heatmaps
  "ggplotify",    # convert base/grid plots to ggplot
  "data.table",   # fast I/O
  "WGCNA",        # co-expression network analysis
  "flashClust",   # fast hierarchical clustering (used by WGCNA)
  "igraph",       # network analysis
  "yaml"          # read config.yaml in R
)

bioc_pkgs <- c(
  # Differential expression
  "DESeq2",
  "apeglm",           # LFC shrinkage
  "ashr",             # alternative LFC shrinkage

  # Visualisation
  "EnhancedVolcano",
  "ComplexHeatmap",

  # Pathway enrichment
  "clusterProfiler",
  "enrichplot",
  "ReactomePA",
  "org.Mm.eg.db",     # mouse gene annotation
  "AnnotationDbi",
  "fgsea",
  "msigdbr",          # MSigDB gene sets in R

  # Batch correction / normalisation
  "limma",
  "sva",              # ComBat
  "edgeR",            # CPM / filterByExpr

  # Variance partitioning
  "variancePartition"
)

install.packages(setdiff(cran_pkgs, rownames(installed.packages())))
BiocManager::install(setdiff(bioc_pkgs, rownames(installed.packages())), ask = FALSE)

message("All packages installed.")
sessionInfo()
