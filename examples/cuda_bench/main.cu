// main.cu
// Runs memory bandwidth and GEMM benchmarks on all visible CUDA devices
// and writes results to a timestamped JSON file for before/after comparison.

#include "bench_common.cuh"
#include <cuda_runtime.h>
#include <stdio.h>
#include <time.h>
#include <string.h>

static void write_json(int count,
                       cudaDeviceProp* props,
                       BenchResult* mem_results,
                       BenchResult* gemm_results) {
    time_t now = time(NULL);
    struct tm* t = localtime(&now);
    char fname[64];
    strftime(fname, sizeof(fname), "bench_%Y%m%dT%H%M%S.json", t);

    FILE* f = fopen(fname, "w");
    if (!f) { fprintf(stderr, "Cannot write %s\n", fname); return; }

    char ts[32];
    strftime(ts, sizeof(ts), "%Y-%m-%dT%H:%M:%S", t);

    fprintf(f, "{\n  \"timestamp\": \"%s\",\n  \"gpus\": [\n", ts);
    for (int i = 0; i < count; i++) {
        fprintf(f,
            "    {\n"
            "      \"index\": %d,\n"
            "      \"name\": \"%s\",\n"
            "      \"compute_capability\": \"sm_%d%d\",\n"
            "      \"vram_mb\": %.0f,\n"
            "      \"memory_bandwidth_gb_s\": %.2f,\n"
            "      \"gemm_gflops\": %.2f\n"
            "    }%s\n",
            i, props[i].name,
            props[i].major, props[i].minor,
            props[i].totalGlobalMem / 1024.0 / 1024.0,
            mem_results[i].value,
            gemm_results[i].value,
            (i < count - 1) ? "," : "");
    }
    fprintf(f, "  ]\n}\n");
    fclose(f);
    printf("\nResults written to %s\n", fname);
}

int main() {
    int count;
    cudaGetDeviceCount(&count);
    printf("CUDA devices: %d\n\n", count);

    cudaDeviceProp props[16];
    BenchResult    mem_results[16];
    BenchResult    gemm_results[16];

    for (int i = 0; i < count; i++) {
        cudaGetDeviceProperties(&props[i], i);
        printf("--- GPU %d: %s (sm_%d%d, %.0f MB) ---\n",
               i, props[i].name, props[i].major, props[i].minor,
               props[i].totalGlobalMem / 1024.0 / 1024.0);

        printf("  Memory bandwidth ... ");
        fflush(stdout);
        mem_results[i] = bench_memory(i);
        printf("%.2f GB/s\n", mem_results[i].value);

        printf("  GEMM throughput  ... ");
        fflush(stdout);
        gemm_results[i] = bench_gemm(i);
        printf("%.2f GFLOPS\n", gemm_results[i].value);
    }

    write_json(count, props, mem_results, gemm_results);
    return 0;
}
