"""FastQC and MultiQC rules for raw and trimmed reads."""


rule fastqc_raw:
    input:
        r1=lambda wc: get_fastq(wc, "R1"),
        r2=lambda wc: get_fastq(wc, "R2"),
    output:
        html_r1="results/fastqc/raw/{sample}_R1_fastqc.html",
        zip_r1 ="results/fastqc/raw/{sample}_R1_fastqc.zip",
        html_r2="results/fastqc/raw/{sample}_R2_fastqc.html",
        zip_r2 ="results/fastqc/raw/{sample}_R2_fastqc.zip",
    log:
        "logs/fastqc/raw/{sample}.log",
    threads: 2
    resources:
        mem_mb=4000,
        walltime="01:00:00",
        queue="normal",
    conda:
        "../envs/qc.yaml"
    shell:
        "fastqc -t {threads} -o results/fastqc/raw/ {input.r1} {input.r2} &> {log}"


rule fastqc_trimmed:
    input:
        r1="results/trimmed/{sample}_R1_trimmed.fastq.gz",
        r2="results/trimmed/{sample}_R2_trimmed.fastq.gz",
    output:
        html_r1="results/fastqc/trimmed/{sample}_R1_fastqc.html",
        zip_r1 ="results/fastqc/trimmed/{sample}_R1_fastqc.zip",
        html_r2="results/fastqc/trimmed/{sample}_R2_fastqc.html",
        zip_r2 ="results/fastqc/trimmed/{sample}_R2_fastqc.zip",
    log:
        "logs/fastqc/trimmed/{sample}.log",
    threads: 2
    resources:
        mem_mb=4000,
        walltime="01:00:00",
        queue="normal",
    conda:
        "../envs/qc.yaml"
    shell:
        "fastqc -t {threads} -o results/fastqc/trimmed/ {input.r1} {input.r2} &> {log}"


rule multiqc_raw:
    input:
        expand("results/fastqc/raw/{sample}_{read}_fastqc.zip",
               sample=SAMPLES, read=["R1", "R2"]),
    output:
        "results/multiqc/raw/multiqc_report.html",
    log:
        "logs/multiqc/raw.log",
    threads: 1
    resources:
        mem_mb=8000,
        walltime="01:00:00",
        queue="normal",
    conda:
        "../envs/qc.yaml"
    shell:
        "multiqc results/fastqc/raw/ -o results/multiqc/raw/ --force &> {log}"


rule multiqc_trimmed:
    input:
        expand("results/fastqc/trimmed/{sample}_{read}_fastqc.zip",
               sample=SAMPLES, read=["R1", "R2"]),
    output:
        "results/multiqc/trimmed/multiqc_report.html",
    log:
        "logs/multiqc/trimmed.log",
    threads: 1
    resources:
        mem_mb=8000,
        walltime="01:00:00",
        queue="normal",
    conda:
        "../envs/qc.yaml"
    shell:
        "multiqc results/fastqc/trimmed/ -o results/multiqc/trimmed/ --force &> {log}"


rule multiqc_aligned:
    input:
        expand("results/aligned/{sample}/Log.final.out", sample=SAMPLES),
    output:
        "results/multiqc/aligned/multiqc_report.html",
    log:
        "logs/multiqc/aligned.log",
    threads: 1
    resources:
        mem_mb=8000,
        walltime="01:00:00",
        queue="normal",
    conda:
        "../envs/qc.yaml"
    shell:
        "multiqc results/aligned/ -o results/multiqc/aligned/ --force &> {log}"
