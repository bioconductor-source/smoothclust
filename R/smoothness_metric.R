#' Function for smoothness metric
#' 
#' Function for clustering smoothness evaluation metric
#' 
#' Function to calculate clustering smoothness evaluation metric, defined as the
#' average number of nearest neighbors per point that are from a different
#' cluster. This metric can be used to quantify and compare the relative
#' smoothness of the boundaries of clusters or spatial domains.
#' 
#' 
#' @param spatial_coords Numeric matrix containing spatial coordinates of
#'   points, formatted as nrow = number of points, ncol = 2 (assuming x and y
#'   dimensions). For example, `spatial_coords = spatialCoords(spe)` if using a
#'   \code{SpatialExperiment} object.
#' 
#' @param labels Numeric vector of cluster labels for each point. For example,
#'   `labels <- as.numeric(colData(spe)$label)` if using a
#'   \code{SpatialExperiment} object.
#' 
#' @param k Number of k nearest neighbors to use in calculation. Default = 6
#'   (from 10x Genomics Visium platform).
#' 
#' 
#' @return Returns a list containing (i) a vector of values at each point (i.e.
#'   the number of nearest neighbors that are from a different cluster at each
#'   point) and (ii) the average value across all points.
#' 
#' 
#' @importFrom spdep knearneigh
#' 
#' @export
#' 
#' @examples
#' library(STexampleData)
#' library(scran)
#' library(scater)
#' 
#' # load data
#' spe <- Visium_humanDLPFC()
#' # keep spots over tissue
#' spe <- spe[, colData(spe)$in_tissue == 1]
#' 
#' # run smoothclust
#' # using "knn" method for faster runtime in this example
#' # see vignette for example using default method
#' spe <- smoothclust(spe, method = "knn", k = 6)
#' 
#' # calculate logcounts
#' spe <- logNormCounts(spe, assay.type = "counts_smooth")
#' 
#' # preprocessing steps for clustering
#' # remove mitochondrial genes
#' is_mito <- grepl("(^mt-)", rowData(spe)$gene_name, ignore.case = TRUE)
#' spe <- spe[!is_mito, ]
#' # select top highly variable genes (HVGs)
#' dec <- modelGeneVar(spe)
#' top_hvgs <- getTopHVGs(dec, prop = 0.1)
#' spe <- spe[top_hvgs, ]
#' 
#' # dimensionality reduction
#' set.seed(123)
#' spe <- runPCA(spe)
#' 
#' # run k-means clustering
#' set.seed(123)
#' k <- 5
#' clus <- kmeans(reducedDim(spe, "PCA"), centers = k)$cluster
#' colLabels(spe) <- factor(clus)
#' 
#' # calculate smoothness metric
#' res <- smoothness_metric(spatialCoords(spe), as.numeric(colData(spe)$label))
#' 
#' # results
#' str(res)
#' head(res$n_discordant)
#' res$mean_discordant
#' 
smoothness_metric <- function(spatial_coords, labels, k = 6) {
  
  stopifnot(!is.null(spatial_coords), 
            is.numeric(spatial_coords), 
            is.matrix(spatial_coords), 
            ncol(spatial_coords) == 2)
  stopifnot(length(labels) == nrow(spatial_coords))
  stopifnot(is.numeric(k) && length(k) == 1)
  
  # calculate k nearest neighbors for each point
  neigh <- knearneigh(spatial_coords, k = k)$nn
  
  # calculate ordered columns of cluster labels
  neigh_labels <- matrix(NA, nrow = nrow(neigh), ncol = ncol(neigh))
  for (i in seq_len(ncol(neigh_labels))) {
    neigh_labels[, i] <- labels[neigh[, i]]
  }
  
  # calculate number of non-matching labels
  stopifnot(length(labels) == nrow(neigh_labels))
  vals <- rowSums(labels != neigh_labels)
  
  # return vector and average value
  list(n_discordant = vals, mean_discordant = mean(vals))
}
