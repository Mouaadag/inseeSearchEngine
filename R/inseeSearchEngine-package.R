#' @keywords internal
"_PACKAGE"

#' inseeSearchEngine: Search and Explore INSEE Datasets
#'
#' @description
#' A powerful search engine for exploring French National Institute of Statistics (INSEE)
#' datasets. Search datasets by keywords, explore available dimensions, filter IDBanks,
#' and download data for analysis.
#'
#' @section Main Functions:
#' \describe{
#'   \item{\code{\link{search_insee}}}{Search for datasets by keyword}
#'   \item{\code{\link{explore_dataset}}}{Explore a specific dataset in detail}
#'   \item{\code{\link{popular_keywords}}}{Display popular search keywords}
#' }
#'
#' @section Quick Start:
#' ```
#' library(inseeSearchEngine)
#'
#' # Search for unemployment data
#' results <- search_insee("Chomage")
#'
#' # Explore a dataset
#' explore_dataset("CHOMAGE-TRIM-NATIONAL")
#'
#' # See popular keywords
#' popular_keywords()
#' ```
#'
#' @section Note on Function Naming:
#' This package contains a function called \code{search_insee()} which has
#' the same name as a function in the \code{insee} package. To avoid confusion,
#' always use the fully qualified name:
#' ```
#' inseeSearchEngine::search_insee("keyword")
#' ```
#' or call the package functions after loading:
#' ```
#' library(inseeSearchEngine)
#' search_insee("keyword")  # Uses inseeSearchEngine version
#' ```
#'
#' @docType package
#' @name inseeSearchEngine-package
#' @aliases inseeSearchEngine
NULL
