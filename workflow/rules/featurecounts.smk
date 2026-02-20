"""featureCounts gene-level quantification across all samples."""


rule featurecounts:
    input:
        bams=expand(
            "results/aligned/{sample}/Aligned.sortedByCoord.out.bam",
            sample=SAMPLES,
        ),
        bai=expand(
            "results/aligned/{sample}/Aligned.sortedByCoord.out.bam.bai",
            sample=SAMPLES,
        ),
        gtf=config["genome"]["gtf"],
    output:
        counts ="results/counts/all_samples_counts.txt",
        summary="results/counts/all_samples_counts.txt.summary",
    log:
        "logs/featurecounts/featurecounts.log",
    threads: config["featurecounts"]["threads"]
    resources:
        mem_mb=16000,
        walltime="04:00:00",
        queue="normal",
    params:
        strand  =config["featurecounts"]["strandedness"],
        min_mqs =config["featurecounts"]["min_mapping_quality"],
        feature =config["featurecounts"]["feature_type"],
        attr    =config["featurecounts"]["attribute_type"],
    conda:
        "../envs/counts.yaml"
    shell:
        """
        featureCounts \
            -T {threads} \
            -a {input.gtf} \
            -o {output.counts} \
            -s {params.strand} \
            -Q {params.min_mqs} \
            -t {params.feature} \
            -g {params.attr} \
            -p --countReadPairs \
            -B -C \
            --largestOverlap \
            --ignoreDup \
            {input.bams} \
            &> {log}
        """
