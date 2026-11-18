import argparse
import math
import multiprocessing as mp
import platform
import sys
from time import perf_counter

import numpy as np


def one_replicate(seed):
    rng = np.random.default_rng(seed)
    y = rng.standard_normal(20_000)
    theta = 0.0
    for _ in range(2_000):
        theta += np.sum(y - theta) / y.size
    return theta


def benchmark(workload, jobs, repeats):
    expected = jobs["serial"]()
    for run in range(1, repeats + 1):
        for method, job in jobs.items():
            start = perf_counter()
            result = job()
            elapsed = perf_counter() - start
            np.testing.assert_allclose(result, expected, rtol=1e-12, atol=1e-14)
            print(f"{workload},Python,{method},{run},{elapsed:.9f}", flush=True)
            del result


def run_benchmarks(workers, repeats):
    seeds = range(1, 17)
    integers = range(1, 1_000_001)
    vector = np.arange(1, 1_000_001)
    x = np.random.default_rng(5014).standard_normal(20_000_000)
    chunks = np.array_split(x, workers)
    chunk_size = math.ceil(len(integers) / (4 * workers))
    context = mp.get_context("fork" if "fork" in mp.get_all_start_methods() else "spawn")

    print(
        f"Python {platform.python_version()}, NumPy {np.__version__}; "
        f"{workers} workers ({context.get_start_method()})",
        file=sys.stderr,
    )
    print("workload,language,method,run,seconds")
    with context.Pool(workers) as pool:
        benchmark("replicate", {
            "serial": lambda: list(map(one_replicate, seeds)),
            "parallel": lambda: pool.map(one_replicate, seeds, chunksize=1),
        }, repeats)
        benchmark("sqrt", {
            "serial": lambda: list(map(math.sqrt, integers)),
            "parallel": lambda: pool.map(math.sqrt, integers, chunksize=chunk_size),
            "vectorized": lambda: np.sqrt(vector),
        }, repeats)
        benchmark("exp", {
            "serial": lambda: np.exp(x),
            "parallel": lambda: np.concatenate(pool.map(np.exp, chunks, chunksize=1)),
        }, repeats)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("workers", type=int)
    parser.add_argument("repeats", type=int)
    args = parser.parse_args()
    if args.workers < 2 or args.repeats < 3:
        parser.error("use at least two workers and three runs")
    run_benchmarks(args.workers, args.repeats)
