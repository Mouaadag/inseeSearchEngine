#' Explore a Specific INSEE Dataset
#'
#' @description
#' Explore the structure and contents of a specific INSEE dataset,
#' including available dimensions, unique values, and sample data.
#'
#' @param dataset_id Character string. The INSEE dataset identifier (e.g., "CHOMAGE-TRIM-NATIONAL").
#' @param show_sample Logical. Whether to display a sample of the data. Default is TRUE.
#'
#' @return Invisibly returns a data frame containing all IDBanks and their metadata
#'   for the specified dataset.
#'
#' @details
#' This function retrieves and displays:
#' \itemize{
#'   \item Total number of IDBanks in the dataset
#'   \item Available columns/dimensions
#'   \item Unique values for each dimension (up to 15 values shown)
#'   \item Optional data sample (first 10 rows)
#' }
#'
#' @examples
#' \dontrun{
#' # Explore unemployment dataset
#' idbanks <- explore_dataset("CHOMAGE-TRIM-NATIONAL")
#'
#' # Explore without showing sample
#' idbanks <- explore_dataset("IPC-2015", show_sample = FALSE)
#' }
#'
#' @export
#' @importFrom insee get_idbank_list
#' @importFrom glue glue
explore_dataset <- function(dataset_id, show_sample = TRUE) {
  cat(glue::glue("\n Exploring dataset: {dataset_id}\n"))
  cat(rep("=", 60), "\n\n", sep = "")

  # Retrieve IDBanks
  idbank_list <- tryCatch(
    {
      insee::get_idbank_list(dataset_id)
    },
    error = function(e) {
      cat(glue::glue(" Error: {e$message}\n"))
      return(NULL)
    }
  )

  if (is.null(idbank_list)) {
    return(invisible(NULL))
  }

  cat(glue::glue(" Total number of IDBanks: {nrow(idbank_list)}\n\n"))

  # Display available columns
  cat(" Available columns:\n")
  print(names(idbank_list))
  cat("\n")

  # Display dimensions and their values
  dimensions <- names(idbank_list)[
    !names(idbank_list) %in%
      c("idbank", "IDBANK", "TITLE_FR", "TITLE_EN", "UNIT", "UNIT_MULT")
  ]

  cat(" Dimensions and values:\n")
  for (dim in dimensions) {
    unique_vals <- unique(idbank_list[[dim]])
    cat(glue::glue("   - {dim} ({length(unique_vals)} values): "))
    if (length(unique_vals) <= 15) {
      cat(paste(unique_vals, collapse = ", "), "\n")
    } else {
      cat(paste(utils::head(unique_vals, 15), collapse = ", "), "...\n")
    }
  }
  cat("\n")

  # Display sample if requested
  if (show_sample) {
    cat(" Data sample (first 10 rows):\n")
    print(utils::head(idbank_list, 10))
  }

  invisible(idbank_list)
}


#' List Popular Keywords for INSEE Search
#'
#' @description
#' Display a table of commonly used keywords for searching INSEE datasets,
#' organized by category. Includes both French and English terms.
#'
#' @return Invisibly returns a tibble containing the keywords table.
#'
#' @details
#' Categories include:
#' \itemize{
#'   \item Employment & Unemployment
#'   \item Prices & Inflation
#'   \item Economy
#'   \item Trade
#'   \item Demographics
#'   \item Housing
#'   \item Income
#'   \item Business
#' }
#'
#' @examples
#' \dontrun{
#' # Display popular keywords
#' popular_keywords()
#' }
#'
#' @export
#' @importFrom tibble tribble
popular_keywords <- function() {
  cat("\n POPULAR KEYWORDS FOR INSEE SEARCH\n")
  cat(rep("=", 60), "\n\n", sep = "")

  keywords <- tibble::tribble(
    ~Category             , ~`French keywords`                   , ~`English keywords`               ,
    "Employment"          , "chomage, emploi, travail"           , "unemployment, employment, labor" ,
    "Prices & Inflation"  , "ipc, inflation, prix"               , "cpi, inflation, prices"          ,
    "Economy"             , "pib, croissance, production"        , "gdp, growth, production"         ,
    "Trade"               , "export, import, commerce"           , "export, import, trade"           ,
    "Demographics"        , "population, naissance, deces"       , "population, birth, death"        ,
    "Housing"             , "logement, construction, immobilier" , "housing, construction, property" ,
    "Income"              , "salaire, revenu, pauvrete"          , "wage, income, poverty"           ,
    "Business"            , "entreprise, societe, creation"      , "company, firm, creation"
  )

  print(keywords, n = Inf)

  cat("\n Usage: search_insee('chomage') or search_insee('CPI')\n\n")

  invisible(keywords)
}
