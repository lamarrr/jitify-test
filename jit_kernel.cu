

#include <cuda/std/cstdint>

#include "operation.hpp"

template <typename... T> __global__ void add_kernel(int64_t size, T *...data) {
  int64_t start =
      (int64_t)blockIdx.x * (int64_t)blockDim.x + (int64_t)threadIdx.x;
  int64_t stride = (int64_t)gridDim.x * (int64_t)blockDim.x;

  for (int64_t i = start; i < size; i += stride) {
    GENERIC_OPERATION(i, data...);
  }
}
