#!/usr/bin/env bash
# Build STAR genome index for mm39 (GRCm39) with GENCODE vM35 annotation.
# Run once before the main pipeline. Submittable as a PBS job.
#
# PBS directives — uncomment to submit with: qsub scripts/star_genome_index.sh
# #PBS -N star_genome_index
# #PBS -l ncpus=16
# #PBS -l mem=64gb
# #PBS -l walltime=04:00:00
# #PBS -q normal
# #PBS -j oe

set -euo pipefail

# ── Edit these paths ──────────────────────────────────────────────────────────
GENOME_FASTA="/path/to/refs/mm39/GRCm39.primary_assembly.genome.fa"
GTF="/path/to/refs/mm39/gencode.vM35.annotation.gtf"
INDEX_DIR="/path/to/refs/mm39/star_index_150bp"
# ─────────────────────────────────────────────────────────────────────────────

THREADS="${PBS_NCPUS:-16}"
OVERHANG=149   # read_length - 1  (adjust if reads are not 150 bp)

# GENCODE GTF contains transcript-level entries; filter to gene+exon for speed
FILTERED_GTF="${GTF%.gtf}.filtered.gtf"
if [[ ! -f "${FILTERED_GTF}" ]]; then
    echo "Filtering GTF to gene/exon features..."
    grep -v "^#" "${GTF}" | awk '$3=="gene" || $3=="exon"' > "${FILTERED_GTF}"
fi

mkdir -p "${INDEX_DIR}"

echo "Building STAR index (threads=${THREADS}, overhang=${OVERHANG})..."
STAR \
    --runMode genomeGenerate \
    --runThreadN "${THREADS}" \
    --genomeDir "${INDEX_DIR}" \
    --genomeFastaFiles "${GENOME_FASTA}" \
    --sjdbGTFfile "${GTF}" \
    --sjdbOverhang "${OVERHANG}" \
    --genomeSAindexNbases 14

echo "STAR genome index built at: ${INDEX_DIR}"
