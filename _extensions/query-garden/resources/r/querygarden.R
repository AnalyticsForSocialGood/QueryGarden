.query_garden_option_line <- function(name, value) {
  if (is.null(value)) {
    return(NULL)
  }
  if (is.logical(value)) {
    value <- if (isTRUE(value)) "true" else "false"
  }
  paste0("#| ", name, ": ", value)
}

.query_garden_fence <- function(sql) {
  fence <- "```"
  while (grepl(fence, sql, fixed = TRUE)) {
    fence <- paste0(fence, "`")
  }
  fence
}

query_garden_sql_block <- function(
  sql,
  db,
  sql_file_path = NULL,
  dialect = NULL,
  editable = NULL,
  output_location = NULL
) {
  sql <- trimws(paste(sql, collapse = "\n"))
  fence <- .query_garden_fence(sql)
  options <- c(
    .query_garden_option_line("query-garden", TRUE),
    .query_garden_option_line("db", db),
    .query_garden_option_line("sql-file-path", sql_file_path),
    .query_garden_option_line("editable", editable),
    .query_garden_option_line("dialect", dialect),
    .query_garden_option_line("output-location", output_location)
  )

  paste0(
    fence, "{.sql}\n",
    paste(options, collapse = "\n"), "\n",
    sql, "\n",
    fence
  )
}

query_garden_sql_block_from_file <- function(query_file_path, ...) {
  sql <- paste(readLines(query_file_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  query_garden_sql_block(sql, ...)
}

query_garden_emit_sql_block <- function(sql, ...) {
  cat(query_garden_sql_block(sql, ...), sep = "\n")
}

query_garden_emit_sql_block_from_file <- function(query_file_path, ...) {
  cat(query_garden_sql_block_from_file(query_file_path, ...), sep = "\n")
}

