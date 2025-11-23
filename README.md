# inseeSearchEngine 🔍

<!-- badges: start -->

[![R build status](https://github.com/yourusername/inseeSearchEngine/workflows/R-CMD-check/badge.svg)](https://github.com/yourusername/inseeSearchEngine/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

<!-- badges: end -->

An R package for searching and exploring French National Institute of Statistics (INSEE) datasets. Search datasets by keywords, explore available dimensions, filter IDBanks, and download data for analysis.

## Features

- **Keyword Search**: Find INSEE datasets using French or English keywords
- **Dataset Exploration**: View dimensions, variables, and metadata
- **Auto-Save Results**: Automatically save search results as RDS and CSV
- **User-Friendly**: Beautiful console output with emojis and formatting
- **Fast**: Efficiently search through hundreds of datasets
-  **Bilingual**: Works with both French and English search terms

## Installation

```r
# Install from GitHub
# install.packages("devtools")
devtools::install_github("Mouaadag/inseeSearchEngine")
```

### Dependencies

The package requires:

- `insee` - Access to INSEE API
- `tidyverse` packages (`dplyr`, `tidyr`, `purrr`, `tibble`, `readr`)
- `glue` - String interpolation

## Quick Start

### Basic Search

```r
library(inseeSearchEngine)

# Search for unemployment data
results <- search_insee("Chomage")

# Search for consumer price index
results <- search_insee("IPC")

# Search for GDP data
results <- search_insee("PIB")
```

### Explore a Dataset

```r
# Explore a specific dataset
explore_dataset("CHOMAGE-TRIM-NATIONAL")

# Explore without showing data sample
explore_dataset("IPC-2015", show_sample = FALSE)
```

### View Popular Keywords

```r
# See commonly used search terms
popular_keywords()
```

## Usage Examples

### Example 1: Find and Download Unemployment Data

```r
library(inseeSearchEngine)
library(insee)

# 1. Search for datasets
results <- search_insee("Chomage")

# 2. Load saved results
results <- readRDS("resultats_recherche/Chomage_YYYYMMDD_HHMMSS.rds")

# 3. Extract IDBanks from a dataset
dataset_id <- "CHOMAGE-TRIM-NATIONAL"
idbanks_df <- results[[dataset_id]]$idbanks

# 4. Filter for specific dimensions
library(dplyr)
idbanks_filtered <- idbanks_df %>%
  filter(SEXE == "1") %>%        # Men
  filter(AGE == "00-")           # All ages

# 5. Download data
data <- get_insee_idbank(idbanks_filtered$idbank, startPeriod = "2015-Q1")
```

### Example 2: Multi-Keyword Search

```r
# Search for multiple topics
keywords <- c("Chomage", "IPC", "Salaire", "Population")

results_list <- lapply(keywords, function(k) {
  search_insee(k, max_datasets = 5)
})
```

### Example 3: Custom Search Options

```r
# Limit number of datasets and IDBanks
results <- search_insee(
  keyword = "Emploi",
  max_datasets = 10,
  max_idbanks_per_dataset = 50,
  save_results = TRUE,
  output_dir = "my_results"
)
```

## Output Structure

When you run a search, results are saved in the `resultats_recherche/` directory:

```
resultats_recherche/
├── Keyword_20241123_120000.rds              # Complete results (load in R)
├── Keyword_20241123_120000_summary.csv      # Summary table
├── Keyword_DATASET1_20241123_120000.csv     # IDBanks for dataset 1
└── Keyword_DATASET2_20241123_120000.csv     # IDBanks for dataset 2
```

### File Contents

**RDS File** (complete results):

- Dataset IDs and names
- Number of IDBanks
- Available dimensions
- Complete IDBANK data frames

**CSV Files**:

- Summary: Overview of all datasets found
- Dataset files: All IDBanks with their dimensions

## Popular Keywords

| Category               | French                      | English                         |
| ---------------------- | --------------------------- | ------------------------------- |
| **Employment**   | chomage, emploi, travail    | unemployment, employment, labor |
| **Prices**       | ipc, inflation, prix        | cpi, inflation, prices          |
| **Economy**      | pib, croissance, production | gdp, growth, production         |
| **Trade**        | export, import, commerce    | export, import, trade           |
| **Demographics** | population, naissance       | population, birth, death        |
| **Housing**      | logement, construction      | housing, construction           |
| **Income**       | salaire, revenu             | wage, income, poverty           |
| **Business**     | entreprise, societe         | company, firm, creation         |

## Functions

### `search_insee()`

Search for INSEE datasets by keyword.

**Parameters:**

- `keyword`: Search term (character)
- `max_datasets`: Maximum datasets to return (default: 20)
- `max_idbanks_per_dataset`: Max IDBanks per dataset (default: 100)
- `save_results`: Save to disk (default: TRUE)
- `output_dir`: Output directory (default: "resultats_recherche")

**Returns:** Named list of results (invisible)

### `explore_dataset()`

Explore a specific INSEE dataset.

**Parameters:**

- `dataset_id`: Dataset identifier (e.g., "CHOMAGE-TRIM-NATIONAL")
- `show_sample`: Show data sample (default: TRUE)

**Returns:** Data frame of IDBanks (invisible)

### `popular_keywords()`

Display table of popular search keywords.

**Returns:** Tibble of keywords (invisible)

## Workflow

```r
# 1. Load package
library(inseeSearchEngine)

# 2. Search
results <- search_insee("Chomage")

# 3. Explore
explore_dataset("CHOMAGE-TRIM-NATIONAL")

# 4. Filter and download
library(insee)
library(dplyr)

idbanks <- results$`CHOMAGE-TRIM-NATIONAL`$idbanks %>%
  filter(SEXE == "1", AGE == "00-") %>%
  pull(idbank)

data <- get_insee_idbank(idbanks, startPeriod = "2020-Q1")

# 5. Analyze!
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [INSEE](https://www.insee.fr) for providing comprehensive French statistical data
- The [{insee}](https://cran.r-project.org/package=insee) R package for API access
- All contributors and users of this package

## Contact

For questions, suggestions, or issues, please:

- Open an [issue](https://github.com/yourusername/inseeSearchEngine/issues)
- Contact: mouaad.agourram@outlook.fr

## Links

- [INSEE API Documentation](https://api.insee.fr/catalogue/)
- [INSEE IDBANK Guide](https://www.insee.fr/fr/information/2868055)
- [Package Documentation](https://yourusername.github.io/inseeSearchEngine/)

---

**Made with ❤️ for the R and INSEE communities**
