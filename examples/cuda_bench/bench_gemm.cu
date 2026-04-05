// bench_gemm.cu
// Measures FP32 GEMM throughput using tiled matrix multiply.
// Reports achieved GFLOPS for each visible GPU.

#include "bench_common.cuh"
#include <cuda_runtime.h>
#include <stdio.h>

static const int M = 2048, N = 2048, K = 2048;
static const int TILE  = 16;
static const int ITERATIONS = 20;

__global__ void gemm_kernel(const float* A, const float* B, float* C,
                            int m, int n, int k) {
    __shared__ float sa[TILE][TILE];
    __shared__ float sb[TILE][TILE];

    int row = blockIdx.y * TILE + threadIdx.y;
    int col = blockIdx.x * TILE + threadIdx.x;
    float acc = 0.0f;

    for (int t = 0; t < (k + TILE - 1) / TILE; t++) {
        sa[threadIdx.y][threadIdx.x] =
            (row < m && t * TILE + threadIdx.x < k)
            ? A[row * k + t * TILE + threadIdx.x] : 0.0f;
        sb[threadIdx.y][threadIdx.x] =
            (col < n && t * TILE + threadIdx.y < k)
            ? B[(t * TILE + threadIdx.y) * n + col] : 0.0f;
        __syncthreads();
        for (int i = 0; i < TILE; i++) acc += sa[threadIdx.y][i] * sb[i][threadIdx.x];
        __syncthreads();
    }
    if (row < m && col < n) C[row * n + col] = acc;
}

BenchResult bench_gemm(int device) {
    cudaSetDevice(device);
    size_t bytes = (size_t)M * K * sizeof(float);

    float *d_A, *d_B, *d_C;
    cudaMalloc(&d_A, bytes);
    cudaMalloc(&d_B, bytes);
    cudaMalloc(&d_C, (size_t)M * N * sizeof(float));
    cudaMemset(d_A, 1, bytes);
    cudaMemset(d_B, 1, bytes);

    dim3 block(TILE, TILE);
    dim3 grid((N + TILE - 1) / TILE, (M + TILE - 1) / TILE);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    // Warmup
    gemm_kernel<<<grid, block>>>(d_A, d_B, d_C, M, N, K);
    cudaDeviceSynchronize();

    cudaEventRecord(start);
    for (int i = 0; i < ITERATIONS; i++)
        gemm_kernel<<<grid, block>>>(d_A, d_B, d_C, M, N, K);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float ms = 0;
    cudaEventElapsedTime(&ms, start, stop);

    double flops = 2.0 * M * N * K * ITERATIONS;
    double gflops = flops / (ms / 1000.0) / 1e9;

    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);
    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    BenchResult r;
    r.device = device;
    r.value  = gflops;
    return r;
}
