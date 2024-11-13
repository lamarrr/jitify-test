CUDA_TOOLKIT_DIR="$(pkg-config --cflags cudart-12.6)"

rm -r jitify
rm -r cccl
rm -r rmm
git submodule update --init --recursive
cd ./jitify && git apply ../jitify.patch
cd ../rmm && git apply ../rmm.patch
cd ..

rm -r build
mkdir build
cd build
cmake ../jitify -GNinja 
cd ..

./build/jitify2_preprocess  ./kernel1.cu -I${PWD}/rmm/include/ ${CUDA_TOOLKIT_DIR} -I/usr/include -std=c++17 