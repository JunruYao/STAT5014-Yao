library(parallel)

one_replicate <- function(seed) {
  set.seed(seed)
  y <- rnorm(20000)
  theta <- 0
  for (k in seq_len(2000)) {
    theta <- theta + sum(y - theta) / length(y)
  }
  theta
}

run_benchmarks <- function(workers, repeats) {
  seeds <- 1:16
  integers <- 1:1000000
  methods <- list(
    replicate = list(
      serial = function() unlist(lapply(seeds, one_replicate)),
      parallel = function() unlist(mclapply(seeds, one_replicate, mc.cores = workers))
    ),
    sqrt = list(
      serial = function() unlist(lapply(integers, sqrt)),
      parallel = function() unlist(mclapply(integers, sqrt, mc.cores = workers)),
      vectorized = function() sqrt(integers)
    )
  )

  cat(sprintf("R %s; %d workers\n", getRversion(), workers), file = stderr())
  cat("workload,language,method,run,seconds\n")
  for (workload in names(methods)) {
    jobs <- methods[[workload]]
    expected <- jobs$serial()
    for (run in seq_len(repeats)) {
      for (method in names(jobs)) {
        invisible(gc())
        elapsed <- system.time(result <- jobs[[method]](), gcFirst = FALSE)[["elapsed"]]
        stopifnot(isTRUE(all.equal(result, expected)))
        cat(sprintf("%s,R,%s,%d,%.9f\n", workload, method, run, elapsed))
      }
    }
  }
}

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
workers <- as.integer(args[1])
repeats <- as.integer(args[2])
stopifnot(workers > 1L, repeats >= 3L, .Platform$OS.type == "unix")
run_benchmarks(workers, repeats)
