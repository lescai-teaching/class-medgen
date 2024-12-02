# Load necessary libraries
library(shiny)
library(DESeq2)
library(tidyverse)
library(pheatmap)
library(clusterProfiler)
library(org.Hs.eg.db)
library(AnnotationDbi)
library(RColorBrewer)
library(ggrepel)
library(apeglm)
library(cowplot)

# Define UI
ui <- fluidPage(
  titlePanel("Differential Expression Analysis and Enrichment"),
  sidebarLayout(
    sidebarPanel(
      fileInput("ddsFile", "Upload DESeqDataSet (.RData)", accept = ".RData"),
      numericInput("countThreshold", "Count Threshold for Filtering", value = 10, min = 0),
      numericInput("pvalCutoff", "Adjusted P-Value Cutoff", value = 0.05, min = 0, max = 1),
      numericInput("log2FCThreshold", "Log2 Fold Change Threshold", value = 1, min = 0),
      actionButton("analyze", "Analyze")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Top Genes", tableOutput("topGenesTable")),
        tabPanel("Heatmap", plotOutput("heatmapPlot")),
        tabPanel("PCA Plot", plotOutput("pcaPlot")),
        tabPanel("Volcano Plot", plotOutput("volcanoPlot")),
        tabPanel("Enrichment Analysis", plotOutput("enrichmentPlot"))
      )
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  observeEvent(input$analyze, {
    req(input$ddsFile)
    
    # Load DESeqDataSet
    load(input$ddsFile$datapath)
    req(exists("dds"))
    
    # Ensure proper metadata columns
    if (!all(c("sample", "Group1", "Group2") %in% colnames(colData(dds)))) {
      showNotification("The DESeqDataSet must contain 'sample', 'Group1' (condition), and 'Group2' (replica) columns in colData.", type = "error")
      return(NULL)
    }
    
    # Prepare metadata
    metadata <- DataFrame(
      sample = colData(dds)$sample,
      condition = factor(colData(dds)$Group1),
      replica = factor(colData(dds)$Group2)
    )
    rownames(metadata) <- colnames(dds)
    colData(dds) <- metadata
    
    # Set design formula
    design(dds) <- ~ condition
    
    # Prefiltering
    keep <- rowSums(counts(dds)) >= input$countThreshold
    dds <- dds[keep,]
    
    # Relevel to ensure 'control' is the reference
    dds$condition <- relevel(dds$condition, ref = "control")
    
    # Differential expression analysis
    dds <- DESeq(dds)
    res <- results(dds, alpha = input$pvalCutoff)
    res <- lfcShrink(dds, coef = 2, res = res)
    resOrdered <- res[order(res$pvalue),]
    
    # Annotate results with gene symbols
    resOrdered$gene <- rownames(resOrdered)
    gene_symbols <- mapIds(org.Hs.eg.db, keys = rownames(resOrdered), column = "SYMBOL", keytype = "ENSEMBL", multiVals = "first")
    resOrdered$gene_symbol <- gene_symbols[rownames(resOrdered)]
    
    # Output top 20 genes
    output$topGenesTable <- renderTable({
      head(as.data.frame(resOrdered), 20)
    })
    
    # Heatmap of top 20 genes
    output$heatmapPlot <- renderPlot({
      topGenes <- head(rownames(resOrdered), 20)
      # Apply variance stabilizing transformation
      vsd <- varianceStabilizingTransformation(dds, blind = TRUE)
      mat <- assay(vsd)[topGenes, ]
      mat <- mat - rowMeans(mat)
      annotation <- as.data.frame(colData(dds)[, "condition", drop = FALSE])
      pheatmap(mat, annotation_col = annotation, cluster_cols = FALSE, show_rownames = TRUE, 
               color = colorRampPalette(rev(brewer.pal(9, "Blues")))(255))
    })
    
    # PCA plot
    output$pcaPlot <- renderPlot({
      vsd <- varianceStabilizingTransformation(dds, blind = TRUE)
      plotPCA(vsd, intgroup = "condition")
    })
    
    # Volcano plot
    output$volcanoPlot <- renderPlot({
      res_tb <- as_tibble(resOrdered) %>%
        mutate(diffexpressed = case_when(
          log2FoldChange > input$log2FCThreshold & padj < input$pvalCutoff ~ 'upregulated',
          log2FoldChange < -input$log2FCThreshold & padj < input$pvalCutoff ~ 'downregulated',
          TRUE ~ 'not_de'
        ))
      res_tb$genelabels <- ""
      res_tb <- res_tb %>% arrange(padj)
      res_tb$genelabels[1:5] <- res_tb$gene_symbol[1:5]
      ggplot(data = res_tb, aes(x = log2FoldChange, y = -log10(padj), col = diffexpressed)) +
        geom_point(size = 2) +
        geom_text_repel(aes(label = genelabels), size = 4, max.overlaps = Inf) +
        ggtitle("Volcano Plot of Differential Expression") +
        geom_vline(xintercept = c(-input$log2FCThreshold, input$log2FCThreshold), col = "black", linetype = 'dashed', linewidth = 0.2) +
        geom_hline(yintercept = -log10(input$pvalCutoff), col = "black", linetype = 'dashed', linewidth = 0.2) +
        theme(plot.title = element_text(size = rel(1.25), hjust = 0.5),
              axis.title = element_text(size = rel(1))) +
        scale_color_manual(values = c("upregulated" = "red",
                                      "downregulated" = "blue",
                                      "not_de" = "grey")) +
        labs(color = 'DE genes') +
        xlim(-3, 5)
    })
    
    # Enrichment analysis
    output$enrichmentPlot <- renderPlot({
      # Store the res object inside another variable because the original res file will be required for other functions
      
      res_viz <- res
      
      # Add gene names as a new column to the results table
      
      res_viz$gene <- rownames(res)
      
      # Convert the results to a tibble for easier manipulation and relocate the gene column to the first position
      
      res_viz <- as_tibble(res_viz) %>% 
        relocate(gene, .before = baseMean)
      resSig <- subset(res_viz, padj < 0.05 & abs(log2FoldChange) > 1) 
      
      resSig <- as_tibble(resSig) %>% 
        relocate(gene, .before = baseMean) 
      
      # Order the significant genes by their adjusted p-value (padj) in ascending order
      
      resSig <- resSig[order(resSig$padj),] 
      
      # Prepare gene list
      # Extract the log2 fold change values from the results data frame
      
      gene_list <- res$log2FoldChange
      
      # Name the vector with the corresponding gene identifiers
      
      names(gene_list) <- res$gene
      
      # Sort the list in decreasing order (required for clusterProfiler)
      
      gene_list <- sort(gene_list, decreasing = TRUE)
      
      # Extract the significantly differentially expressed genes from the results data frame
      
      res_genes <- resSig$gene
      
      # Run GO enrichment analysis using the enrichGO function
      
      go_enrich <- enrichGO(
        gene = res_genes,                # Genes of interest
        universe = names(gene_list),     # Background gene set
        OrgDb = org.Hs.eg.db,            # Annotation database
        keyType = 'ENSEMBL',             # Key type for gene identifiers
        readable = TRUE,                 # Convert gene IDs to gene names
        ont = "ALL",                     # Ontology: can be "BP", "MF", "CC", or "ALL"
        pvalueCutoff = 0.05,             # P-value cutoff for significance
        qvalueCutoff = 0.10              # Q-value cutoff for significance
      )
      
      # Check if enrichment results are available
      if (is.null(go_enrich) || nrow(go_enrich) == 0) {
        showNotification("No enrichment terms found.", type = "warning")
        return(NULL)
      }
      
      # Create a bar plot of the top enriched GO terms
      
      barplot <- barplot(
        go_enrich, 
        title = "Enrichment analysis barplot",
        font.size = 14
      )
      
      # Create a dot plot of the top enriched GO terms
      
      dotplot <- dotplot(
        go_enrich,
        title = "Enrichment analysis dotplot",
        font.size = 14
      )
      
      # Combine the bar plot and dot plot into a single plot grid
      
      go_plot <- plot_grid(barplot, dotplot, nrow = 2)
      
      # Plot enrichment results
      plot(go_plot)
      
    })
  })
}

# Run the application
shinyApp(ui = ui, server = server)