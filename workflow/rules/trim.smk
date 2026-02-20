"""Trimmomatic paired-end adapter/quality trimming."""


rule trimmomatic_pe:
    input:
        r1=lambda wc: get_fastq(wc, "R1"),
        r2=lambda wc: get_fastq(wc, "R2"),
    output:
        r1         ="results/trimmed/{sample}_R1_trimmed.fastq.gz",
        r2         ="results/trimmed/{sample}_R2_trimmed.fastq.gz",
        r1_unpaired="results/trimmed/{sample}_R1_unpaired.fastq.gz",
        r2_unpaired="results/trimmed/{sample}_R2_unpaired.fastq.gz",
    log:
        "logs/trim/{sample}.log",
    threads: 4
    resources:
        mem_mb=8000,
        walltime="02:00:00",
        queue="normal",
    params:
        adapter=config["trimming"]["adapter"],
        leading=config["trimming"]["leading"],
        trailing=config["trimming"]["trailing"],
        sw     =config["trimming"]["slidingwindow"],
        minlen =config["trimming"]["minlen"],
    conda:
        "../envs/qc.yaml"
    shell:
        """
        trimmomatic PE -threads {threads} \
            {input.r1} {input.r2} \
            {output.r1} {output.r1_unpaired} \
            {output.r2} {output.r2_unpaired} \
            ILLUMINACLIP:{params.adapter}:2:30:10:2:keepBothReads \
            LEADING:{params.leading} \
            TRAILING:{params.trailing} \
            SLIDINGWINDOW:{params.sw} \
            MINLEN:{params.minlen} \
            &> {log}
        """
