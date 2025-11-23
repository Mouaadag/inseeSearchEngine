#' Search INSEE Datasets by Keyword
#'
#' @description
#' Search for INSEE datasets using keywords and extract their IDBanks.
#' Results are automatically saved to disk for future use.
#'
#' @param keyword Character string. The keyword to search for (e.g., "Chomage", "IPC", "PIB").
#'   Searches are case-insensitive and work in both French and English.
#' @param max_datasets Integer. Maximum number of datasets to return. Default is 20.
#' @param max_idbanks_per_dataset Integer. Maximum number of IDBanks to extract per dataset.
#'   Default is 100.
#' @param save_results Logical. Whether to save results to disk. Default is TRUE.
#' @param output_dir Character string. Directory where results will be saved.
#'   Default is "resultats_recherche".
#'
#' @return Invisibly returns a named list containing search results for each dataset.
#'   Each element contains:
#'   \itemize{
#'     \item dataset_id: The dataset identifier
#'     \item dataset_name: Human-readable dataset name
#'     \item n_idbanks: Number of IDBanks found
#'     \item dimensions: Available dimensions in the dataset
#'     \item idbanks: Data frame with all IDBanks and their metadata
#'   }
#'
#' @details
#' The function performs the following steps:
#' \enumerate{
#'   \item Searches all INSEE datasets for the keyword
#'   \item For each matching dataset, extracts available IDBanks
#'   \item Displays dimensions and their values
#'   \item Saves results as RDS (complete) and CSV (summary) files
#' }
#'
#' Results are saved in the output directory with timestamped filenames:
#' \itemize{
#'   \item \code{keyword_timestamp.rds} - Complete results
#'   \item \code{keyword_timestamp_summary.csv} - Summary table
#'   \item \code{keyword_dataset_id_timestamp.csv} - IDBanks per dataset
#' }
#'
#' @examples
#' \dontrun{
#' # Search for unemployment data
#' results <- search_insee("Chomage")
#'
#' # Search for CPI data with custom options
#' results <- search_insee("IPC", max_datasets = 5, max_idbanks_per_dataset = 50)
#'
#' # Search without saving
#' results <- search_insee("PIB", save_results = FALSE)
#' }
#'
#' @export
#' @importFrom insee get_dataset_list get_idbank_list
#' @importFrom glue glue
#' @importFrom dplyr filter
#' @importFrom purrr map_df map_int
#' @importFrom tibble tibble
#' @importFrom readr write_csv
search_insee <- function(
  keyword,
  max_datasets = 20,
  max_idbanks_per_dataset = 100,
  save_results = TRUE,
  output_dir = "resultats_recherche"
) {
  cat("\n")
  cat("+============================================================+\n")
  cat("|       INSEE SEARCH ENGINE - DATASETS & IDBANKS            |\n")
  cat("+============================================================+\n")
  cat(glue::glue("\nSearching for: '{keyword}'\n"))
  cat(rep("=", 60), "\n\n", sep = "")

  # Create output directory if needed
  if (save_results && !dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # STEP 1: SEARCH DATASETS
  cat(" STEP 1: Searching datasets...\n")

  dataset_list <- tryCatch(
    {
      insee::get_dataset_list()
    },
    error = function(e) {
      cat(" Error retrieving datasets:", e$message, "\n")
      return(NULL)
    }
  )

  if (is.null(dataset_list)) {
    cat("  Unable to retrieve dataset list\n")
    return(invisible(NULL))
  }

  # Identify search columns
  search_cols <- names(dataset_list)[sapply(dataset_list, is.character)]

  # Search by keyword
  matches <- rep(FALSE, nrow(dataset_list))
  for (col in search_cols) {
    matches <- matches | grepl(keyword, dataset_list[[col]], ignore.case = TRUE)
  }

  datasets_matched <- dataset_list[matches, ]

  if (nrow(datasets_matched) == 0) {
    cat(glue::glue("  No datasets found for '{keyword}'\n"))
    cat("\n Suggestions:\n")
    cat(
      "   - Try more general terms (e.g., 'employment' instead of 'unemployment')\n"
    )
    cat("   - Try in English (e.g., 'unemployment', 'CPI', 'GDP')\n")
    cat("   - Check spelling\n\n")
    return(invisible(NULL))
  }

  # Limit number of datasets
  if (nrow(datasets_matched) > max_datasets) {
    cat(glue::glue(
      "   -  {nrow(datasets_matched)} datasets found, showing first {max_datasets}\n"
    ))
    datasets_matched <- utils::head(datasets_matched, max_datasets)
  } else {
    cat(glue::glue("   -  {nrow(datasets_matched)} datasets found\n\n"))
  }

  # Display matched datasets
  cat(" MATCHING DATASETS:\n")
  cat(rep("-", 60), "\n", sep = "")

  for (i in seq_len(nrow(datasets_matched))) {
    dataset_id <- datasets_matched$id[i]
    dataset_name <- if ("Name" %in% names(datasets_matched)) {
      datasets_matched$Name[i]
    } else if ("name" %in% names(datasets_matched)) {
      datasets_matched$name[i]
    } else {
      dataset_id
    }

    cat(glue::glue("{i}. [{dataset_id}] {dataset_name}\n"))
  }
  cat("\n")

  # STEP 2: EXTRACT IDBANKS
  cat(" STEP 2: Extracting IDBanks...\n\n")

  all_results <- list()

  for (i in seq_len(nrow(datasets_matched))) {
    dataset_id <- datasets_matched$id[i]
    dataset_name <- if ("Name" %in% names(datasets_matched)) {
      datasets_matched$Name[i]
    } else {
      dataset_id
    }

    cat(glue::glue(
      "   [{i}/{nrow(datasets_matched)}] Processing: {dataset_id}...\n"
    ))

    idbank_list <- tryCatch(
      {
        insee::get_idbank_list(dataset_id)
      },
      error = function(e) {
        cat(glue::glue("        Error: {e$message}\n"))
        return(NULL)
      }
    )

    if (is.null(idbank_list) || nrow(idbank_list) == 0) {
      cat("      No IDBanks available\n\n")
      next
    }

    dimensions <- names(idbank_list)[
      !names(idbank_list) %in%
        c("idbank", "IDBANK", "TITLE_FR", "TITLE_EN", "UNIT", "UNIT_MULT")
    ]

    cat(glue::glue("      {nrow(idbank_list)} IDBanks found\n"))
    cat(glue::glue(
      "      Dimensions: {paste(dimensions, collapse = ', ')}\n"
    ))

    for (dim in utils::head(dimensions, 3)) {
      unique_vals <- unique(idbank_list[[dim]])
      if (length(unique_vals) <= 10) {
        cat(glue::glue(
          "         {dim}: {paste(utils::head(unique_vals, 10), collapse = ', ')}\n"
        ))
      } else {
        cat(glue::glue(
          "         {dim}: {length(unique_vals)} unique values\n"
        ))
      }
    }
    cat("\n")

    if (nrow(idbank_list) > max_idbanks_per_dataset) {
      idbank_list <- utils::head(idbank_list, max_idbanks_per_dataset)
    }

    all_results[[dataset_id]] <- list(
      dataset_id = dataset_id,
      dataset_name = dataset_name,
      n_idbanks = nrow(idbank_list),
      dimensions = dimensions,
      idbanks = idbank_list
    )
  }

  # STEP 3: SAVE RESULTS
  if (save_results && length(all_results) > 0) {
    cat(" STEP 3: Saving results...\n")

    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    filename_base <- gsub("[^[:alnum:]]", "_", keyword)

    rds_file <- file.path(
      output_dir,
      glue::glue("{filename_base}_{timestamp}.rds")
    )
    saveRDS(all_results, rds_file)
    cat(glue::glue("   Complete results: {rds_file}\n"))

    summary_df <- purrr::map_df(all_results, function(x) {
      tibble::tibble(
        dataset_id = x$dataset_id,
        dataset_name = x$dataset_name,
        n_idbanks = x$n_idbanks,
        dimensions = paste(x$dimensions, collapse = "; ")
      )
    })

    csv_file <- file.path(
      output_dir,
      glue::glue("{filename_base}_{timestamp}_summary.csv")
    )
    readr::write_csv(summary_df, csv_file)
    cat(glue::glue("    CSV summary: {csv_file}\n"))

    for (dataset_id in names(all_results)) {
      idbanks_file <- file.path(
        output_dir,
        glue::glue("{filename_base}_{dataset_id}_{timestamp}.csv")
      )
      readr::write_csv(all_results[[dataset_id]]$idbanks, idbanks_file)
      cat(glue::glue("    IDBanks {dataset_id} : {idbanks_file}\n"))
    }

    cat("\n")
  }

  # FINAL SUMMARY
  cat("\n")
  cat("+============================================================+\n")
  cat("|                      FINAL SUMMARY                         |\n")
  cat("+============================================================+\n\n")

  cat(glue::glue(" Search: '{keyword}'\n"))
  cat(glue::glue(" Datasets found: {nrow(datasets_matched)}\n"))
  cat(glue::glue(
    " Total IDBanks: {sum(purrr::map_int(all_results, ~.x$n_idbanks))}\n\n"
  ))

  cat(" To use these IDBanks in your projects:\n")
  cat("   1. Load RDS file: results <- readRDS('file.rds')\n")
  cat("   2. Access IDBanks: results$DATASET_ID$idbanks\n")
  cat("   3. Download data: get_insee_idbank(idbanks)\n\n")

  if (save_results && length(all_results) > 0) {
    cat(" Usage example:\n")
    first_dataset <- names(all_results)[1]
    cat(glue::glue("   results <- readRDS('{rds_file}')\n"))
    cat(glue::glue("   idbanks <- results${first_dataset}$idbanks$idbank\n"))
    cat(
      "   data <- insee::get_insee_idbank(idbanks, startPeriod = '2015-Q1')\n\n"
    )
  }

  invisible(all_results)
}
