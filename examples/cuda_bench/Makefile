NVCC      := nvcc
TARGET    := cuda_bench
SRCS      := main.cu bench_memory.cu bench_gemm.cu

# Quadro K2200 (sm_50) and Tesla M10 (sm_52)
ARCH_FLAGS := -gencode arch=compute_50,code=sm_50 \
              -gencode arch=compute_52,code=sm_52

CFLAGS    := -O2 $(ARCH_FLAGS)

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SRCS) bench_common.cuh
	$(NVCC) $(CFLAGS) -o $@ $(SRCS)

clean:
	rm -f $(TARGET) bench_*.json
