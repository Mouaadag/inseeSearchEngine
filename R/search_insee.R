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
#'   \item {keyword}_{timestamp}.rds - Complete results
#'   \item {keyword}_{timestamp}_summary.csv - Summary table
#'   \item {keyword}_{dataset_id}_{timestamp}.csv - IDBanks per dataset
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
  cat("╔════════════════════════════════════════════════════════════╗\n")
  cat("║       MOTEUR DE RECHERCHE INSEE - DATASETS & IDBANKS      ║\n")
  cat("╚════════════════════════════════════════════════════════════╝\n")
  cat(glue::glue("\nRecherche pour : '{keyword}'\n"))
  cat(rep("=", 60), "\n\n", sep = "")

  # Créer le dossier de sortie si besoin
  if (save_results && !dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # ÉTAPE 1 : RECHERCHER LES DATASETS
  cat(" ÉTAPE 1 : Recherche des datasets...\n")

  dataset_list <- tryCatch(
    {
      insee::get_dataset_list()
    },
    error = function(e) {
      cat(" Erreur lors de la récupération des datasets :", e$message, "\n")
      return(NULL)
    }
  )

  if (is.null(dataset_list)) {
    cat("  Impossible de récupérer la liste des datasets\n")
    return(invisible(NULL))
  }

  # Identifier les colonnes de recherche
  search_cols <- names(dataset_list)[sapply(dataset_list, is.character)]

  # Recherche par mot-clé
  matches <- rep(FALSE, nrow(dataset_list))
  for (col in search_cols) {
    matches <- matches | grepl(keyword, dataset_list[[col]], ignore.case = TRUE)
  }

  datasets_matched <- dataset_list[matches, ]

  if (nrow(datasets_matched) == 0) {
    cat(glue::glue("  Aucun dataset trouvé pour '{keyword}'\n"))
    cat("\n Suggestions :\n")
    cat(
      "   - Essayez des termes plus généraux (ex: 'emploi' au lieu de 'chômage')\n"
    )
    cat("   - Essayez en anglais (ex: 'unemployment', 'CPI', 'GDP')\n")
    cat("   - Vérifiez l'orthographe\n\n")
    return(invisible(NULL))
  }

  # Limiter le nombre de datasets
  if (nrow(datasets_matched) > max_datasets) {
    cat(glue::glue(
      "   -  {nrow(datasets_matched)} datasets trouvés, affichage des {max_datasets} premiers\n"
    ))
    datasets_matched <- head(datasets_matched, max_datasets)
  } else {
    cat(glue::glue("   -  {nrow(datasets_matched)} datasets trouvés\n\n"))
  }

  # Afficher les datasets trouvés
  cat(" DATASETS CORRESPONDANTS :\n")
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

  # ÉTAPE 2 : EXTRAIRE LES IDBANKS
  cat(" ÉTAPE 2 : Extraction des IDBanks...\n\n")

  all_results <- list()

  for (i in seq_len(nrow(datasets_matched))) {
    dataset_id <- datasets_matched$id[i]
    dataset_name <- if ("Name" %in% names(datasets_matched)) {
      datasets_matched$Name[i]
    } else {
      dataset_id
    }

    cat(glue::glue(
      "   [{i}/{nrow(datasets_matched)}] Traitement : {dataset_id}...\n"
    ))

    idbank_list <- tryCatch(
      {
        insee::get_idbank_list(dataset_id)
      },
      error = function(e) {
        cat(glue::glue("        Erreur : {e$message}\n"))
        return(NULL)
      }
    )

    if (is.null(idbank_list) || nrow(idbank_list) == 0) {
      cat("      Aucun IDBANK disponible\n\n")
      next
    }

    dimensions <- names(idbank_list)[
      !names(idbank_list) %in%
        c("idbank", "IDBANK", "TITLE_FR", "TITLE_EN", "UNIT", "UNIT_MULT")
    ]

    cat(glue::glue("      {nrow(idbank_list)} IDBanks trouvés\n"))
    cat(glue::glue(
      "      Dimensions : {paste(dimensions, collapse = ', ')}\n"
    ))

    for (dim in head(dimensions, 3)) {
      unique_vals <- unique(idbank_list[[dim]])
      if (length(unique_vals) <= 10) {
        cat(glue::glue(
          "         {dim}: {paste(head(unique_vals, 10), collapse = ', ')}\n"
        ))
      } else {
        cat(glue::glue(
          "         {dim}: {length(unique_vals)} valeurs uniques\n"
        ))
      }
    }
    cat("\n")

    if (nrow(idbank_list) > max_idbanks_per_dataset) {
      idbank_list <- head(idbank_list, max_idbanks_per_dataset)
    }

    all_results[[dataset_id]] <- list(
      dataset_id = dataset_id,
      dataset_name = dataset_name,
      n_idbanks = nrow(idbank_list),
      dimensions = dimensions,
      idbanks = idbank_list
    )
  }

  # ÉTAPE 3 : SAUVEGARDER LES RÉSULTATS
  if (save_results && length(all_results) > 0) {
    cat(" ÉTAPE 3 : Sauvegarde des résultats...\n")

    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    filename_base <- gsub("[^[:alnum:]]", "_", keyword)

    rds_file <- file.path(
      output_dir,
      glue::glue("{filename_base}_{timestamp}.rds")
    )
    saveRDS(all_results, rds_file)
    cat(glue::glue("   Résultats complets : {rds_file}\n"))

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
    cat(glue::glue("    Résumé CSV : {csv_file}\n"))

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

  # RÉSUMÉ FINAL
  cat("\n")
  cat("╔════════════════════════════════════════════════════════════╗\n")
  cat("║                      RÉSUMÉ FINAL                          ║\n")
  cat("╚════════════════════════════════════════════════════════════╝\n\n")

  cat(glue::glue(" Recherche : '{keyword}'\n"))
  cat(glue::glue(" Datasets trouvés : {nrow(datasets_matched)}\n"))
  cat(glue::glue(
    " Total IDBanks : {sum(purrr::map_int(all_results, ~.x$n_idbanks))}\n\n"
  ))

  cat(" Pour utiliser ces IDBanks dans vos projets :\n")
  cat("   1. Chargez le fichier RDS : results <- readRDS('fichier.rds')\n")
  cat("   2. Accédez aux IDBanks : results$DATASET_ID$idbanks\n")
  cat("   3. Téléchargez les données : get_insee_idbank(idbanks)\n\n")

  if (save_results && length(all_results) > 0) {
    cat(" Exemple d'utilisation :\n")
    first_dataset <- names(all_results)[1]
    cat(glue::glue("   results <- readRDS('{rds_file}')\n"))
    cat(glue::glue("   idbanks <- results${first_dataset}$idbanks$idbank\n"))
    cat(
      "   data <- insee::get_insee_idbank(idbanks, startPeriod = '2015-Q1')\n\n"
    )
  }

  invisible(all_results)
}
