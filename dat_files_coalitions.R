# ==============================================================================
# COOPERATIVE GAME DATA GENERATOR FOR THE SHARED-CUSTOMER COLLABORATION 
# VEHICLE ROUTING PROBLEM (SCC-VRP)
#
# Description: Parses master AMPL .dat benchmark instance files, extracts
#              variables and parameters, and generates sub-instance .dat files
#              for every possible carrier coalition (cooperative game).
# ==============================================================================
# ==============================================================================
# 1. PARSER FUNCTION: AMPL .dat -> R Data Structure
# ==============================================================================
#' Parse AMPL .dat Instance File
#'
#' Reads an AMPL data file defining an SCC-VRP instance and parses sets, 
#' parameters, and matrices into structured native R objects.
#'
#' @param file_path Character. Path to the input .dat file.
#' @return A named list containing:
#'   - \code{clients}: Integer vector of customer IDs (set N)
#'   - \code{carriers}: Integer vector of carrier IDs (set C)
#'   - \code{Q}: Integer vehicle capacity limit
#'   - \code{K}: Named list of vehicle fleet indices per carrier
#'   - \code{depots}: Character vector of depot identifiers (set o)
#'   - \code{dist_matrix}: Numeric matrix of inter-node distances
#'   - \code{trav_matrix}: Numeric matrix of asymmetric travel times
#'   - \code{demand}: Numeric matrix of customer demands per carrier (param d)

parse_ampl_dat <- function(file_path) {
  lines <- readLines(file_path, warn = FALSE)
  lines <- trimws(lines) 
  lines <- lines[lines != ""]  
  
  data <- list()
  
  line_N <- grep("^set N", lines, value = TRUE)[1]
  data$clients <- as.integer(unlist(strsplit(gsub(".*:=|;", "", line_N), "\\s+")))
  data$clients <- data$clients[!is.na(data$clients)]
  
  line_C <- grep("^set C", lines, value = TRUE)[1]
  data$carriers <- as.integer(unlist(strsplit(gsub(".*:=|;", "", line_C), "\\s+")))
  data$carriers <- data$carriers[!is.na(data$carriers)]
  
  line_Q <- grep("^param Q", lines, value = TRUE)[1]
  data$Q <- as.integer(gsub(".*:=\\s*|;", "", line_Q))
  
  K_lines <- grep("^set K\\[", lines, value = TRUE)
  if (length(K_lines) > 0) {
    data$K <- list()
    for (l in K_lines) {
      m <- regmatches(l, regexec("set K\\[(\\d+)\\] := (.*);", l))[[1]]
      if (length(m) == 3) {
        carrier <- m[2]
        values <- as.integer(unlist(strsplit(m[3], "\\s+")))
        data$K[[carrier]] <- values[!is.na(values)]
      }
    }
  } else {
    data$K <- NULL  
  }
  
  line_o <- grep("^set o", lines, value = TRUE)[1]
  data$depots <- gsub("\"", "", unlist(strsplit(gsub(".*:=|;", "", line_o), "\\s+")))
  data$depots <- data$depots[data$depots != ""]
  

  i_dist <- grep("^param dist:", lines)
  i_dist_end <- grep(";", lines)
  i_dist_end <- i_dist_end[i_dist_end > i_dist][1]
  
  dist_header_line <- lines[i_dist]
  dist_header <- unlist(strsplit(gsub(".*param dist:\\s*", "", dist_header_line), "\\s+"))
  dist_header <- dist_header[dist_header != ":="]  
  
  dist_matrix <- matrix(NA, nrow = length(dist_header), ncol = length(dist_header))
  rownames(dist_matrix) <- colnames(dist_matrix) <- dist_header
  
  
  for (i in (i_dist + 1):i_dist_end) {
    tokens <- unlist(strsplit(trimws(lines[i]), "\\s+"))
    
    
    if (length(tokens) == 0 || tokens[1] == ";") next
    
    row_name <- gsub(";", "", tokens[1])
    if (row_name == "") next
    
    values <- as.numeric(gsub(";", "", tokens[-1]))  
    if (length(values) != length(dist_header)) {
      warning(paste("Skipping row", row_name, "- expected", length(dist_header), "values, got", length(values)))
      next
    }
    dist_matrix[row_name, ] <- values
  }
  data$dist_matrix <- dist_matrix
  
  
  i_trav <- grep("^param trav_time:", lines)
  if (length(i_trav) > 0) {
    i_trav <- i_trav[1]
    i_trav_end <- grep(";", lines)
    i_trav_end <- i_trav_end[i_trav_end > i_trav][1]
    
    trav_header_line <- lines[i_trav]
    trav_header <- unlist(strsplit(gsub(".*param trav_time:\\s*", "", trav_header_line), "\\s+"))
    trav_header <- trav_header[trav_header != ":="]
    
    trav_matrix <- matrix(NA, nrow = length(trav_header), ncol = length(trav_header))
    rownames(trav_matrix) <- colnames(trav_matrix) <- trav_header
    
    
    for (i in (i_trav + 1):i_trav_end) {
      tokens <- unlist(strsplit(trimws(lines[i]), "\\s+"))
      
      if (length(tokens) == 0 || tokens[1] == ";") next
      
      row_name <- gsub(";", "", tokens[1])
      if (row_name == "") next
      
      values <- as.numeric(gsub(";", "", tokens[-1]))
      if (length(values) != length(trav_header)) {
        warning(paste("Skipping trav_time row", row_name, "- expected", length(trav_header), "values, got", length(values)))
        next
      }
      trav_matrix[row_name, ] <- values
    }
    data$trav_matrix <- trav_matrix
  }
  
  
  i_demand <- grep("^param d:", lines)
  i_demand_end <- grep(";", lines)
  i_demand_end <- i_demand_end[i_demand_end > i_demand][1]
  
  demand_header_line <- lines[i_demand]
  demand_cols <- unlist(strsplit(gsub(".*param d:\\s*", "", demand_header_line), "\\s+"))
  demand_cols <- demand_cols[demand_cols != ":="]
  
  demand_matrix <- matrix(NA, nrow = length(data$clients), ncol = length(demand_cols))
  rownames(demand_matrix) <- as.character(data$clients)
  colnames(demand_matrix) <- demand_cols
  
  
  for (i in (i_demand + 1):i_demand_end) {
    tokens <- unlist(strsplit(trimws(lines[i]), "\\s+"))
    
    if (length(tokens) == 0 || tokens[1] == ";") next
    
    row_name <- gsub(";", "", tokens[1])
    if (row_name == "") next
    
    values <- as.numeric(gsub(";", "", tokens[-1]))
    if (length(values) != length(demand_cols)) {
      warning(paste("Skipping demand row", row_name, "- mismatch in number of values"))
      next
    }
    if (!is.na(row_name) && row_name %in% rownames(demand_matrix)) {
      demand_matrix[row_name, ] <- values
    }
  }
  data$demand <- demand_matrix
  
  return(data)
}
# ==============================================================================
# 2. EXPORTER FUNCTION: Coalition Subproblem -> AMPL .dat Format
# ==============================================================================
#' Write Coalition-Specific AMPL Data File
#' 
#' Extracts subproblem data for a specified carrier coalition and exports 
#' the corresponding AMPL .dat file with re-indexed sets, vehicle fleets, 
#' and projected parameter matrices.
#'
#' @param input_file Character. Path to the original .dat file.
#' @param subset_carriers Integer vector. Indices of carriers forming the coalition 
#' (e.g., c(1, 2) is equal to the coalition {1,2}, with carriers 1 and 2).
#' @param file_name Character. Output destination path for the generated .dat file.

write_ampl_dat_file_new <- function(input_file = "vrpdata_new.dat", subset_carriers = c(1, 2), file_name = "subset_data.dat") {
  
  data_R <- parse_ampl_dat(input_file) 
  
  subset_carriers_index <- 1:length(subset_carriers)
  
  onew <- c()
  for (i in 1:length(subset_carriers_index)){
    onew <- c(onew, paste("o", subset_carriers_index[i], sep=""))
  }
  
  file_conn <- file(file_name, open = "w")
  
  writeLines(paste("set N := ", paste(data_R$clients, collapse=" "), ";"), file_conn)
  writeLines(paste("set C := ", paste(subset_carriers_index, collapse=" "), ";"), file_conn)
  
  if (!is.null(data_R$K)) {
    for (i in seq_along(subset_carriers)) {
      original_carrier <- as.character(subset_carriers[i])
      local_index <- i
      k_values <- data_R$K[[original_carrier]]
      if (!is.null(k_values)) {
        k_string <- paste(k_values, collapse = " ")
        writeLines(paste0("set K[", local_index, "] := ", k_string, ";"), file_conn)
      }
    }
  }
  
  writeLines(paste("set o := ", paste(onew, collapse=" "), ";\n"), file_conn)
  writeLines(paste("param Q := ", data_R$Q, ";\n"), file_conn)
  
  dist_keys0 <- c(onew, data_R$clients) 
  writeLines(paste("param dist:", paste(dist_keys0, collapse=" "), ":="), file_conn)
  
  i0 <- c(subset_carriers, (data_R$clients + max(data_R$carriers))) 
  
  d0 <- data_R$dist_matrix[i0, i0] 
  colnames(d0) <- dist_keys0
  rownames(d0) <- dist_keys0
  
  for (i in dist_keys0) {
    row_line <- i
    for (j in dist_keys0) {
      row_line <- paste(row_line, d0[i,j])
    }
    writeLines(row_line, file_conn)
  }
  writeLines(";\n", file_conn)
  
  if (!is.null(data_R$trav_matrix)) {
    writeLines(paste("param trav_time:", paste(dist_keys0, collapse=" "), ":="), file_conn)
    
    t0 <- data_R$trav_matrix[i0, i0] 
    colnames(t0) <- dist_keys0
    rownames(t0) <- dist_keys0
    
    for (i in dist_keys0) {
      row_line <- i
      for (j in dist_keys0) {
        row_line <- paste(row_line, t0[i,j])
      }
      writeLines(row_line, file_conn)
    }
    writeLines(";\n", file_conn)
  }
  
  writeLines(paste("param d: ", paste(subset_carriers_index, collapse=" "), ":="), file_conn)
  
  for (i in data_R$clients) {
    writeLines(paste(i, paste(data_R$demand[i,subset_carriers], collapse = " ")), file_conn)
  }
  writeLines(";", file_conn)
  
  close(file_conn)
}

# ==============================================================================
# 3. COOPERATIVE GAME: Characteristic Function Subproblems (All Coalitions)
# ==============================================================================
#' Constructs the cooperative game from the coalition-specific AMPL data files
#' (for each instance)

library(CoopGame)

# Total number of participating carriers in the grand coalition
n <- 5 

# Generate binary incidence matrix of all 2^n - 1 non-empty coalitions 
# (excluding empty set)
coaL <- createBitMatrix(n)[,-(n+1)]


# Directory path containing master AMPL benchmark instance files (.dat)
# NOTE: Update this path to a relative or project-specific directory before running
instances_dir <- "/Applications/AMPL/ampl_macos64/mis_instancias_simulaciones/instancias"

# Locate all master instance files
instance_files <- list.files(path = instances_dir, pattern = "\\.dat$", full.names = TRUE)

# Process every instance and generate coalition subproblems
for(dat_file in instance_files){
  #---------------------------------------------------------------
  # Extract instance name
  #---------------------------------------------------------------
  instance_name <- tools::file_path_sans_ext(basename(dat_file))
  #---------------------------------------------------------------
  # Create a output directory for the current instance
  #---------------------------------------------------------------
  output_dir <- file.path(getwd(), instance_name)
  
  if(!dir.exists(output_dir)){
    dir.create(output_dir)}
  #----------------------------------------------------------------
  # Generate .dat files for all possible non-empty sub-coalitions
  #----------------------------------------------------------------
  for(i in 1:nrow(coaL)) {
    coalition <- which(coaL[i, ] != 0)
    coalition_id <- paste(coalition, collapse = "")
    file_name <- file.path(output_dir, paste0("proba", coalition_id, "_", instance_name,".dat" ))
    write_ampl_dat_file_new(input_file = dat_file, subset_carriers = coalition, file_name = file_name)
  }
  
  cat("Finished:", instance_name, "\n")
  
}