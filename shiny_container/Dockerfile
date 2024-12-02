FROM ghcr.io/rocker-org/shiny-verse:4.4.2

RUN install2.r --error --skipmissing --deps TRUE --skipinstalled \
	pheatmap \
	RColorBrewer \
	ggrepel \
	BiocManager \
	cowplot

RUN Rscript -e "BiocManager::install(c('DESeq2', 'org.Hs.eg.db', 'AnnotationDbi', 'apeglm'), dependencies=TRUE)"

## install what's needed for clusterProfiler

RUN apt-get update
RUN apt-get install -y libglpk40
RUN Rscript -e 'install.packages("igraph", type = "source")'
RUN Rscript -e 'BiocManager::install("clusterProfiler")'