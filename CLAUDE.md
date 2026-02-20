# CLAUDE.md

This file provides guidance for AI assistants (Claude and others) working in this repository.

---

## Project Overview

**Repository:** Mijroy/TBI
**Project:** Bulk RNA-seq analysis of Traumatic Brain Injury in mouse brain
**Data:** 164 mouse samples, 2 sequencing batches, paired-end FASTQ

### Experimental design

| Variable | Levels |
|---|---|
| Treatment | SHAM (surgery control), TBI (injury), TBI.EGT (injury + drug) |
| Brain region | Ips (ipsilateral — injured hemisphere), Con (contralateral) |
| PMI | 8h, 24h post-injury sacrifice time point |
| Sex | Female, Male |
| Genotype | WT (wild-type), KO (gene knockout) |
| Batch | B1, B2 |

Ips/Con pairs from the same animal share an `animal_id`.

---

## Repository Structure

```
TBI/
├── config/
│   ├── config.yaml          # All pipeline parameters and reference paths
│   └── samples.tsv          # Sample metadata sheet (164 samples)
├── workflow/
│   ├── Snakefile            # Top-level Snakemake entry point
│   ├── rules/
│   │   ├── fastqc.smk       # FastQC + MultiQC rules
│   │   ├── trim.smk         # Trimmomatic PE trimming
│   │   ├── align.smk        # STAR two-pass alignment + samtools index
│   │   └── featurecounts.smk# featureCounts gene quantification
│   ├── envs/
│   │   ├── qc.yaml          # Conda: fastqc, multiqc, trimmomatic
│   │   ├── align.yaml       # Conda: STAR, samtools, RSeQC
│   │   └── counts.yaml      # Conda: subread (featureCounts)
│   └── profiles/
│       └── pbs/
│           ├── config.yaml  # Snakemake PBS/SGE cluster profile
│           └── pbs_status.py# Job status checker
├── scripts/
│   ├── build_sample_sheet.py# Scan FASTQ dir → config/samples.tsv skeleton
│   ├── star_genome_index.sh # One-time STAR mm39 genome index build
│   └── aggregate_counts.R   # featureCounts → count_matrix.rds + metadata.rds
├── analysis/
│   ├── 00_setup.R           # R package installation
│   ├── 01_sample_qc.Rmd     # Depth, alignment rate, outlier detection
│   ├── 02_pca_batch.Rmd     # PCA, variance partitioning, batch correction
│   ├── 03_deseq2_main.Rmd   # Seven primary DESeq2 contrasts
│   ├── 04_deseq2_interactions.Rmd  # Treatment × Sex/Genotype/Region/PMI
│   ├── 05_pathway_enrichment.Rmd  # GO/KEGG/Reactome ORA + MSigDB GSEA
│   └── 06_network.Rmd       # WGCNA co-expression network
├── results/                 # .gitignored — all pipeline outputs go here
├── logs/                    # .gitignored — Snakemake / PBS logs
├── .gitignore
└── CLAUDE.md
```

---

## Technology Stack

| Layer | Tool | Version |
|---|---|---|
| Language (pipeline) | Python | ≥ 3.10 |
| Workflow manager | Snakemake | ≥ 7.x |
| Compute | PBS/SGE cluster | — |
| Environments | Conda | — |
| Reference genome | mm39 (GRCm39) | GENCODE vM35 |
| QC | FastQC, MultiQC | 0.12.1, 1.21 |
| Trimming | Trimmomatic PE | 0.39 |
| Alignment | STAR (two-pass) | 2.7.11a |
| Quantification | featureCounts | 2.0.6 (Subread) |
| Statistics (R) | DESeq2, limma, WGCNA | Bioconductor 3.19 |
| Pathway enrichment | clusterProfiler, fgsea, ReactomePA | — |
| Visualisation | ggplot2, ComplexHeatmap, EnhancedVolcano | — |

---

## Development Setup

### Prerequisites

- Conda / Mamba installed
- Access to PBS/SGE cluster with `qsub` and `qstat`
- Reference genome files (see below)

### Reference data

Download once and set paths in `config/config.yaml`:

```bash
# mm39 primary assembly + GENCODE vM35 annotation
wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M35/GRCm39.primary_assembly.genome.fa.gz
wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M35/gencode.vM35.annotation.gtf.gz
gunzip *.gz

# Build STAR index (run once, ~1 hour, 64 GB RAM)
bash scripts/star_genome_index.sh
```

### Sample sheet

```bash
# 1. Scan FASTQ directory to create samples.tsv skeleton
python scripts/build_sample_sheet.py --fastq-dir /path/to/fastq

# 2. Manually fill in metadata columns:
#    animal_id, batch, treatment, region, pmi, sex, genotype
nano config/samples.tsv
```

### Run the upstream pipeline

```bash
# Dry run
snakemake -n --profile workflow/profiles/pbs

# Full run (PBS cluster, 50 parallel jobs)
snakemake --profile workflow/profiles/pbs --jobs 50 --use-conda

# Aggregate featureCounts into R-ready objects
Rscript scripts/aggregate_counts.R
```

### Run the R analysis

Knit each notebook in order from the project root:

```bash
Rscript -e "rmarkdown::render('analysis/01_sample_qc.Rmd')"
Rscript -e "rmarkdown::render('analysis/02_pca_batch.Rmd')"
Rscript -e "rmarkdown::render('analysis/03_deseq2_main.Rmd')"
Rscript -e "rmarkdown::render('analysis/04_deseq2_interactions.Rmd')"
Rscript -e "rmarkdown::render('analysis/05_pathway_enrichment.Rmd')"
Rscript -e "rmarkdown::render('analysis/06_network.Rmd')"
```

---

## Analysis Decisions

### Strandedness
Run `RSeQC infer_experiment.py` on 2–3 BAMs before setting
`featurecounts.strandedness` in `config/config.yaml`:
- `0` = unstranded
- `1` = forward (e.g. ligation-based kits)
- `2` = reverse (TruSeq stranded, most common)

### Batch correction
Batch is included as a covariate in all DESeq2 models (`~ batch + ...`).
The `limma::removeBatchEffect` correction in `02_pca_batch.Rmd` is for
**visualisation only** — do not use the corrected matrix as DESeq2 input.

### Paired samples
Ips/Con pairs from the same animal share `animal_id`. For region comparisons,
consider a paired design: `~ batch + animal_id + region`. Update
`04_deseq2_interactions.Rmd` if animal pairing should be modelled explicitly.

### Multiple testing
All p-values are BH-adjusted (FDR). Default thresholds: FDR < 0.05 and
|log2FC| ≥ 1. Adjust `FDR` and `LFC` constants at the top of each Rmd.

---

## Scientific Questions by Analysis Step

### 01 — Sample QC
- Which samples have <10 M mapped reads or <80% alignment rate?
- Are technical outliers correlated with batch?

### 02 — PCA & Batch
- Does batch account for a dominant principal component?
- After correction, do treatment/region groups separate?

### 03 — DESeq2 Main
- **TBI vs SHAM:** What transcriptional programme is activated by TBI?
- **EGT vs TBI:** Does the drug suppress injury-induced expression?
- **EGT vs SHAM:** Does EGT restore the transcriptome to the uninjured state?
- **Ips vs Con:** How does the injured hemisphere differ from the uninjured side?
- **PMI 24h vs 8h:** Is the sacrifice time point a confound?
- **Male vs Female:** Are there sex-specific TBI responses?
- **KO vs WT:** How does the knockout gene modify basal and injury-induced expression?

### 04 — Interaction Models
- **Treatment × Sex:** Do males and females respond differently to TBI/EGT?
- **Treatment × Genotype:** Does KO modify the injury or drug response?
- **Treatment × Region:** Is the drug effect regionally asymmetric?
- **Treatment × PMI:** Does PMI confound the treatment effect?

### 05 — Pathway Enrichment
- What signalling pathways (neuroinflammation, apoptosis, synaptic function) drive TBI?
- What does EGT target at the pathway level?
- Do sex-specific DEGs implicate hormonal or immune pathways?

### 06 — Network
- What co-expression modules associate with TBI severity or treatment?
- Who are the hub genes — candidate biomarkers or targets?
- Do modules reflect distinct brain cell types?

---

## Common Commands

| Purpose | Command |
|---|---|
| Build sample sheet | `python scripts/build_sample_sheet.py --fastq-dir /path/to/fastq` |
| Dry-run pipeline | `snakemake -n --profile workflow/profiles/pbs` |
| Run pipeline | `snakemake --profile workflow/profiles/pbs --jobs 50 --use-conda` |
| Aggregate counts | `Rscript scripts/aggregate_counts.R` |
| Knit a notebook | `Rscript -e "rmarkdown::render('analysis/03_deseq2_main.Rmd')"` |
| Check cluster jobs | `qstat -u $USER` |

---

## Git Workflow

### Branch naming
- Feature branches: `feature/<short-description>`
- Bug fixes: `fix/<short-description>`
- AI-assisted work: `claude/<session-slug>`

### Commit messages
Use the imperative mood, subject line ≤ 72 characters:
```
Add Treatment×Sex interaction model to 04_deseq2_interactions.Rmd
Fix strandedness parameter in featurecounts.smk
Update WGCNA soft power selection for n=164 samples
```

---

## Code Conventions

- All file paths use `here::here()` in R or relative paths anchored to project root in Python.
- R analysis notebooks save all outputs to `results/analysis/<step>/`.
- DEG result CSVs always include columns: `gene_id`, `baseMean`, `log2FoldChange`, `lfcSE`, `stat`, `pvalue`, `padj`.
- Factor levels follow canonical order: treatment = c("SHAM", "TBI", "TBI.EGT"), region = c("Con", "Ips"), pmi = c("8h", "24h"), sex = c("Female", "Male"), genotype = c("WT", "KO").
- Never overwrite `results/counts/count_matrix.rds` — regenerate by re-running `scripts/aggregate_counts.R`.

---

## AI Assistant Guidelines

1. **Read before writing** — always read existing files before modifying them.
2. **Match existing style** — mirror the formatting, naming, and patterns already present.
3. **Minimal changes** — only modify what is directly required by the task; avoid opportunistic refactoring.
4. **No unnecessary files** — do not create documentation, README files, or helper utilities unless explicitly requested.
5. **No secrets** — never commit `.env` files, API keys, tokens, or passwords.
6. **Test after changes** — for R scripts, verify syntax with `Rscript --no-save --no-restore -e "source('file.R')"`. For Snakemake, run `snakemake -n` to check the DAG.
7. **Descriptive commits** — write commit messages that explain *why*, not just *what*.
8. **Update this file** — when the project structure, stack, or conventions change materially, update the relevant section of this `CLAUDE.md`.

---

## Security Notes

- Never commit raw FASTQ paths or HPC paths that reveal internal infrastructure.
- Keep all cluster credentials and SSH keys out of version control.
- The `results/` and `data/` directories are `.gitignore`d; do not force-add them.

---

*Last updated: 2026-02-20 — initial pipeline scaffold for 164-sample TBI RNA-seq study.*
