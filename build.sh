#!/usr/bin/env bash
CUDA_TOOLKIT_FLAGS="$(pkg-config --cflags cudart-12.6)"

SOURCE_DIR=${PWD}


rm -r ${SOURCE_DIR}/jitify
rm -r ${SOURCE_DIR}/rmm

cd ${SOURCE_DIR}
git submodule update --init --recursive

cd ${SOURCE_DIR}/jitify
git apply ${SOURCE_DIR}/jitify.patch

cd ${SOURCE_DIR}/rmm
git apply ${SOURCE_DIR}/rmm.patch

rm -r ${SOURCE_DIR}/build
mkdir ${SOURCE_DIR}/build
cp -r ${SOURCE_DIR}/jitify ${SOURCE_DIR}/build/jitify-src
cp -r ${SOURCE_DIR}/rmm ${SOURCE_DIR}/build/rmm-src

mkdir ${SOURCE_DIR}/build/jitify-build
cmake -S ${SOURCE_DIR}/build/jitify-src -GNinja -B ${SOURCE_DIR}/build/jitify-build
cd ${SOURCE_DIR}/build/jitify-build
ninja

cd ${SOURCE_DIR}

${SOURCE_DIR}/build/jitify-build/jitify2_preprocess  ./kernel1.cu -I${SOURCE_DIR}/build/rmm-src/include/ ${CUDA_TOOLKIT_FLAGS} -I/usr/include -std=c++17
