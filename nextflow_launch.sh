nextflow run nf-core/rnaseq -r 3.12.0 \
-c /home/francesco_lescai/playground.config \
-c /home/francesco_lescai/tutorial_rnaseq_genome.config \
--input gs://compgen-dbb-playground-datamain/data/reads/rnaseq_tutorial.csv \
--outdir gs://compgen-dbb-playground-datamain/class_testcode \
--genome GRCh38chr21 \
--aligner star_salmon \
--pseudo_aligner salmon \
--skip_biotype_qc \
--skip_stringtie \
--skip_bigwig \
--skip_umi_extract \
--skip_trimming \
--skip_fastqc \
--skip_markduplicates \
--skip_dupradar \
--skip_rseqc \
--skip_qualimap