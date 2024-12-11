FROM ghcr.io/rocker-org/shiny-verse:4.4.2

RUN install2.r --error --skipmissing --deps TRUE --skipinstalled \
	pheatmap \
	RColorBrewer \
	ggrepel \
	BiocManager \
	cowplot

RUN Rscript -e "BiocManager::install(c('DESeq2', 'AnnotationDbi', 'apeglm'), dependencies=TRUE)"

## install what's needed for clusterProfiler

RUN apt-get update
RUN apt-get install -y libglpk40
RUN Rscript -e 'install.packages("igraph", type = "source")'
RUN Rscript -e 'BiocManager::install("clusterProfiler")'

## install version specific packages

RUN mkdir -p /opt/r-packages
RUN apt-get install -y wget
WORKDIR /opt/r-packages
RUN wget https://www.bioconductor.org/packages/3.12/data/annotation/src/contrib/org.Hs.eg.db_3.12.0.tar.gz
RUN wget https://bioconductor.org/packages/3.12/data/annotation/src/contrib/DO.db_2.9.tar.gz
RUN Rscript -e 'install.packages("/opt/r-packages/DO.db_2.9.tar.gz", repos = NULL)'
RUN Rscript -e 'install.packages("/opt/r-packages/org.Hs.eg.db_3.12.0.tar.gz", repos = NULL)'
RUN rm -rf /opt/r-packages