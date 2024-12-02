FROM ghcr.io/rocker-org/shiny-verse:4.4.2

RUN install2.r --error --skipmissing --deps TRUE --skipinstalled \
    DESeq2 \
	pheatmap \
	clusterProfiler \
	org.Hs.eg.db \
	AnnotationDbi \
	RColorBrewer \
	ggrepel \
	apeglm \
	cowplot