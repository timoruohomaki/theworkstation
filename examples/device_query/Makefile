NVCC      := nvcc
TARGET    := device_query
SRC       := device_query.cu

# Support Quadro K2200 (sm_50) and Tesla M10 (sm_52) — both Maxwell
ARCH_FLAGS := -gencode arch=compute_50,code=sm_50 \
              -gencode arch=compute_52,code=sm_52

CFLAGS    := -O2 $(ARCH_FLAGS)

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SRC)
	$(NVCC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(TARGET)
