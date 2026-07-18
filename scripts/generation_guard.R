# Artifact writers are intentionally private children of rebuild_all.R.
generation_context_fail <- function(detail = NULL) {
  suffix <- if (is.null(detail)) "" else paste0(" (", detail, ")")
  stop(paste0("artifact writers may run only inside scripts/rebuild_all.R",
              suffix, "; run Rscript scripts/rebuild_all.R instead."),
       call. = FALSE)
}

generation_root <- Sys.getenv("CASCADE_GENERATION_ROOT", unset = "")
generation_token <- Sys.getenv("CASCADE_GENERATION_TOKEN", unset = "")
if (!nzchar(generation_root) || !nzchar(generation_token))
  generation_context_fail("missing generation capability")

expected_root <- tryCatch(normalizePath(generation_root, winslash = "/",
                                         mustWork = TRUE),
                          error = function(e) generation_context_fail("invalid staging root"))
actual_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
if (!identical(actual_root, expected_root))
  generation_context_fail("working directory is not the isolated staging root")

token_path <- file.path(expected_root, ".cascade-generation-token")
info <- file.info(token_path)
link <- Sys.readlink(token_path)
if (!file.exists(token_path) || nrow(info) != 1L || is.na(info$isdir) || info$isdir ||
    (!is.na(link) && nzchar(link)))
  generation_context_fail("generation capability file is missing or unsafe")
bytes <- readBin(token_path, what = "raw", n = info$size)
if (any(as.integer(bytes) %in% c(0L, 13L)))
  generation_context_fail("generation capability file is malformed")
recorded <- readLines(token_path, warn = FALSE, encoding = "UTF-8")
if (length(recorded) != 1L || !identical(recorded, generation_token))
  generation_context_fail("generation capability does not match")

rm(generation_root, generation_token, expected_root, actual_root, token_path,
   info, link, bytes, recorded)
