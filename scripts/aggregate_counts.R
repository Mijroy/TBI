#!/usr/bin/env Rscript
# Reshape the all-in-one featureCounts output into R-ready objects.
#
# Input:
#   results/counts/all_samples_counts.txt  — featureCounts output
#   config/samples.tsv                     — sample metadata
#
# Output:
#   results/counts/count_matrix.rds   — integer matrix (genes × samples)
#   results/counts/metadata.rds       — data.frame aligned to matrix columns

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
})

counts_file  <- "results/counts/all_samples_counts.txt"
samples_file <- "config/samples.tsv"
out_matrix   <- "results/counts/count_matrix.rds"
out_meta     <- "results/counts/metadata.rds"

dir.create(dirname(out_matrix), recursive = TRUE, showWarnings = FALSE)

# ── Read featureCounts output ──────────────────────────────────────────────────
# Row 1 is a comment (# Program:featureCounts ...) — skip = 1
fc <- fread(counts_file, skip = 1, sep = "\t", data.table = FALSE)

# Columns 1–6: Geneid Chr Start End Strand Length
# Columns 7+:  one per BAM file (full path)
count_cols <- seq(7, ncol(fc))
gene_ids   <- fc$Geneid
counts_raw <- as.matrix(fc[, count_cols])

# Derive sample IDs from BAM path: results/aligned/{sample}/Aligned...bam
sample_ids <- basename(dirname(colnames(counts_raw)))
colnames(counts_raw) <- sample_ids
rownames(counts_raw) <- gene_ids

message(sprintf("Count matrix: %d genes × %d samples", nrow(counts_raw), ncol(counts_raw)))

# ── Read and align metadata ────────────────────────────────────────────────────
meta <- read.delim(samples_file, comment.char = "#", stringsAsFactors = FALSE)

missing <- setdiff(colnames(counts_raw), meta$sample_id)
if (length(missing) > 0) {
  stop("Samples in count matrix not found in metadata: ",
       paste(missing, collapse = ", "))
}

extra <- setdiff(meta$sample_id, colnames(counts_raw))
if (length(extra) > 0) {
  message("Metadata samples not in count matrix (will be dropped): ",
          paste(extra, collapse = ", "))
  meta <- meta[meta$sample_id %in% colnames(counts_raw), ]
}

meta <- meta[match(colnames(counts_raw), meta$sample_id), ]
stopifnot(identical(meta$sample_id, colnames(counts_raw)))

# Factor-encode experimental variables
meta$batch     <- factor(meta$batch)
meta$treatment <- factor(meta$treatment, levels = c("SHAM", "TBI", "TBI.EGT"))
meta$region    <- factor(meta$region,    levels = c("Con", "Ips"))
meta$pmi       <- factor(meta$pmi,       levels = c("8h", "24h"))
meta$sex       <- factor(meta$sex,       levels = c("Female", "Male"))
meta$genotype  <- factor(meta$genotype,  levels = c("WT", "KO"))

# ── Save ───────────────────────────────────────────────────────────────────────
saveRDS(counts_raw, out_matrix)
saveRDS(meta,       out_meta)

message("Saved: ", out_matrix)
message("Saved: ", out_meta)
