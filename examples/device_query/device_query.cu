// device_query.cu
// Enumerates all CUDA-visible GPUs and prints their key properties.
// Used to verify CUDA installation and confirm Tesla M10 sub-GPUs are detected.
//
// Build:  make
// Run:    ./device_query

#include <stdio.h>
#include <cuda_runtime.h>

int main() {
    int count;
    cudaError_t err = cudaGetDeviceCount(&count);

    if (err != cudaSuccess) {
        fprintf(stderr, "cudaGetDeviceCount failed: %s\n", cudaGetErrorString(err));
        return 1;
    }

    printf("CUDA devices found: %d\n\n", count);

    for (int i = 0; i < count; i++) {
        cudaDeviceProp prop;
        cudaGetDeviceProperties(&prop, i);

        printf("GPU %d: %s\n", i, prop.name);
        printf("  Compute capability : sm_%d%d\n", prop.major, prop.minor);
        printf("  Total VRAM         : %.0f MB\n", prop.totalGlobalMem / 1024.0 / 1024.0);
        printf("  Multiprocessors    : %d\n", prop.multiProcessorCount);
        printf("  Clock rate         : %.0f MHz\n", prop.clockRate / 1000.0);
        printf("  ECC enabled        : %s\n\n", prop.ECCEnabled ? "yes" : "no");
    }

    return 0;
}
