// bench_common.cuh
// Shared types and declarations for cuda_bench.

#pragma once

struct BenchResult {
    int    device;
    double value;
};

BenchResult bench_memory(int device);
BenchResult bench_gemm(int device);
