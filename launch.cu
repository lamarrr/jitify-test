#include "jit_kernel.cu.jit.hpp"

#include "jitify2.hpp"

int main() {

  std::string src = R"***(
    void GENERIC_OPERATION(int64_t i, float * out, float * a, float * b){
    out[i] = a[i] + b[i];
    }
    )***";

  std::string kernel_name =
      jitify2::reflection::Template("add_kernel").instantiate("float", "float");

  auto cache = std::make_unique<jitify2::ProgramCache<>>(
      10'000, *jit_kernel_cu_jit, nullptr, "/tmp", 100'000);

      int64_t s = 0;
      float * a = nullptr,* b = nullptr;

  cache->get_kernel(kernel_name, {}, {{"operation.hpp", src}}, {"-arch=sm_."})
      ->configure_1d_max_occupancy(0, 0, nullptr, nullptr)
      ->launch(s, a, b);
}