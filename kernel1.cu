#include "rmm/cuda_stream_view.hpp"

// Problems:
// - atomic header not found
// - some headers contain CPU-code that are not executed on the device, i.e. <stdexcept> used in RMM_CUDA_TRY in rmm/error.hpp
//

__global__ void add_kernel(int const *__restrict x, int const *__restrict y,
                           int *__restrict z, unsigned long long int length)
{
  if (threadIdx.x < length)
  {
    z[threadIdx.x] = x[threadIdx.x] + y[threadIdx.x];
  }
}
