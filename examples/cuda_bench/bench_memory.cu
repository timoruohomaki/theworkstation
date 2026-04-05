// bench_memory.cu
// Measures device memory bandwidth using a large buffer copy.
// Reports achieved GB/s for each visible GPU.

#include "bench_common.cuh"
#include <cuda_runtime.h>
#include <stdio.h>

static const size_t BUF_BYTES = 512ULL * 1024 * 1024; // 512 MB
static const int    ITERATIONS = 20;

__global__ void copy_kernel(const float* __restrict__ src,
                            float* __restrict__ dst,
                            size_t n) {
    size_t i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) dst[i] = src[i];
}

BenchResult bench_memory(int device) {
    cudaSetDevice(device);
    size_t n = BUF_BYTES / sizeof(float);

    float *d_src, *d_dst;
    cudaMalloc(&d_src, BUF_BYTES);
    cudaMalloc(&d_dst, BUF_BYTES);
    cudaMemset(d_src, 1, BUF_BYTES);

    dim3 block(256);
    dim3 grid((n + block.x - 1) / block.x);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    // Warmup
    copy_kernel<<<grid, block>>>(d_src, d_dst, n);
    cudaDeviceSynchronize();

    cudaEventRecord(start);
    for (int i = 0; i < ITERATIONS; i++)
        copy_kernel<<<grid, block>>>(d_src, d_dst, n);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float ms = 0;
    cudaEventElapsedTime(&ms, start, stop);

    double bytes_moved = 2.0 * BUF_BYTES * ITERATIONS; // read + write
    double gb_per_s = bytes_moved / (ms / 1000.0) / 1e9;

    cudaFree(d_src);
    cudaFree(d_dst);
    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    BenchResult r;
    r.device = device;
    r.value  = gb_per_s;
    return r;
}
