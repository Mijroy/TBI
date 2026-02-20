"""STAR two-pass alignment to mm39 and samtools BAM indexing."""


rule star_align:
    input:
        r1   ="results/trimmed/{sample}_R1_trimmed.fastq.gz",
        r2   ="results/trimmed/{sample}_R2_trimmed.fastq.gz",
        index=config["genome"]["star_index"],
    output:
        bam         ="results/aligned/{sample}/Aligned.sortedByCoord.out.bam",
        log_final   ="results/aligned/{sample}/Log.final.out",
        log_progress="results/aligned/{sample}/Log.progress.out",
        sj          ="results/aligned/{sample}/SJ.out.tab",
    log:
        "logs/star/{sample}.log",
    threads: config["star"]["threads"]
    resources:
        mem_mb=42000,
        walltime="06:00:00",
        queue="normal",
    params:
        prefix     =lambda wc: f"results/aligned/{wc.sample}/",
        overhang   =config["star"]["overhang"],
        extra      =config["star"]["extra_flags"],
        genome_load=config["star"]["genome_load"],
    conda:
        "../envs/align.yaml"
    shell:
        """
        STAR \
            --runThreadN {threads} \
            --genomeDir {input.index} \
            --readFilesIn {input.r1} {input.r2} \
            --readFilesCommand zcat \
            --outFileNamePrefix {params.prefix} \
            --sjdbOverhang {params.overhang} \
            --genomeLoad {params.genome_load} \
            {params.extra} \
            &> {log}
        """


rule samtools_index:
    input:
        "results/aligned/{sample}/Aligned.sortedByCoord.out.bam",
    output:
        "results/aligned/{sample}/Aligned.sortedByCoord.out.bam.bai",
    log:
        "logs/samtools/{sample}.log",
    threads: 1
    resources:
        mem_mb=4000,
        walltime="00:30:00",
        queue="normal",
    conda:
        "../envs/align.yaml"
    shell:
        "samtools index {input} &> {log}"
