CUDA_TOOLKIT_DIR="$(pkg-config --cflags cudart-12.6)"

./build/jitify2_preprocess  ./kernel1.cu -I${PWD}/rmm/include/ ${CUDA_TOOLKIT_DIR} -I/usr/include -std=c++17 