#!/usr/bin/env python3
"""
Build config/samples.tsv by scanning a directory of FASTQ files.

Supported naming conventions:
    {sample_id}_R1.fastq.gz  /  {sample_id}_R2.fastq.gz
    {sample_id}_R1_001.fastq.gz  /  {sample_id}_R2_001.fastq.gz
    {sample_id}_1.fastq.gz  /  {sample_id}_2.fastq.gz

Usage:
    python scripts/build_sample_sheet.py \\
        --fastq-dir /path/to/raw_fastq \\
        --output config/samples.tsv

After running, manually fill in the metadata columns:
    animal_id, batch, treatment, region, pmi, sex, genotype

Column reference:
    sample_id  : unique sample identifier
    animal_id  : shared between Ips/Con pairs from the same animal
    batch      : B1 | B2
    treatment  : SHAM | TBI | TBI.EGT
    region     : Ips (ipsilateral) | Con (contralateral)
    pmi        : 8h | 24h  (time of sacrifice post-injury)
    sex        : Female | Male
    genotype   : WT | KO
"""

import argparse
import re
import sys
from pathlib import Path

import pandas as pd


PATTERNS = [
    # (r1_regex, r2_regex)
    (re.compile(r"^(.+?)_R1(?:_\d+)?\.fastq\.gz$"),
     re.compile(r"^(.+?)_R2(?:_\d+)?\.fastq\.gz$")),
    (re.compile(r"^(.+?)_1\.fastq\.gz$"),
     re.compile(r"^(.+?)_2\.fastq\.gz$")),
]


def scan_fastq_dir(fastq_dir: Path) -> pd.DataFrame:
    r1_files: dict[str, str] = {}
    r2_files: dict[str, str] = {}

    for f in sorted(fastq_dir.glob("*.fastq.gz")):
        matched = False
        for r1_pat, r2_pat in PATTERNS:
            m1 = r1_pat.match(f.name)
            m2 = r2_pat.match(f.name)
            if m1:
                r1_files[m1.group(1)] = str(f.resolve())
                matched = True
                break
            elif m2:
                r2_files[m2.group(1)] = str(f.resolve())
                matched = True
                break
        if not matched:
            print(f"WARNING: unrecognised filename pattern: {f.name}", file=sys.stderr)

    rows = []
    for sample_id in sorted(r1_files):
        if sample_id not in r2_files:
            print(f"WARNING: no R2 found for {sample_id}", file=sys.stderr)
            continue
        rows.append({
            "sample_id": sample_id,
            "animal_id": "",
            "batch":     "",
            "treatment": "",
            "region":    "",
            "pmi":       "",
            "sex":       "",
            "genotype":  "",
            "fastq_r1":  r1_files[sample_id],
            "fastq_r2":  r2_files[sample_id],
        })

    for sample_id in sorted(r2_files):
        if sample_id not in r1_files:
            print(f"WARNING: no R1 found for {sample_id}", file=sys.stderr)

    return pd.DataFrame(rows)


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--fastq-dir", required=True, type=Path,
        help="Directory containing paired-end .fastq.gz files",
    )
    parser.add_argument(
        "--output", default="config/samples.tsv", type=Path,
        help="Output TSV path (default: config/samples.tsv)",
    )
    args = parser.parse_args()

    if not args.fastq_dir.is_dir():
        sys.exit(f"ERROR: {args.fastq_dir} is not a directory")

    df = scan_fastq_dir(args.fastq_dir)

    if df.empty:
        sys.exit("ERROR: no paired FASTQ files found")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(args.output, sep="\t", index=False)

    print(f"Wrote {len(df)} samples → {args.output}")
    print("Next: fill in animal_id, batch, treatment, region, pmi, sex, genotype")


if __name__ == "__main__":
    main()
