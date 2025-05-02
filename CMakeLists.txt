cmake_minimum_required(VERSION 3.16)

project(Jitty LANGUAGES C CXX CUDA)

include(FetchContent)

option(BUILD_TESTING "..." OFF)

FetchContent_Declare(
  jitify
  GIT_REPOSITORY https://github.com/NVIDIA/jitify.git
  GIT_TAG jitify2-preprocessing-overhaul
  CONFIGURE_COMMAND "" BUILD_COMMAND ""
  )

FetchContent_Declare(
  cccl
  GIT_REPOSITORY https://github.com/NVIDIA/cccl.git
  GIT_TAG main)

FetchContent_MakeAvailable(jitify)
FetchContent_MakeAvailable(cccl)

find_package(CUDAToolkit REQUIRED)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

set(GENERATED_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/generated)
add_executable(jitify_preprocess "${jitify_SOURCE_DIR}/jitify2_preprocess.cpp")

target_compile_definitions(jitify_preprocess PRIVATE "_FILE_OFFSET_BITS=64")
target_link_libraries(jitify_preprocess PUBLIC ${CMAKE_DL_LIBS} CCCL::libcudacxx CUDA::cudart_static)

# Take a list of files to JIT-compile and run them through jitify_preprocess.
function(jit_preprocess_files)
  cmake_parse_arguments(ARG "" "SOURCE_DIRECTORY" "FILES" ${ARGN})

  get_target_property(libcudacxx_raw_includes CCCL::libcudacxx
                      INTERFACE_INCLUDE_DIRECTORIES)
  set(includes)
  foreach(inc IN LISTS libcudacxx_raw_includes CUDAToolkit_INCLUDE_DIRS)
    list(APPEND includes "-I${inc}")
  endforeach()
  foreach(ARG_FILE ${ARG_FILES})
    set(ARG_OUTPUT ${GENERATED_INCLUDE_DIR}/${ARG_FILE}.jit.hpp)
    get_filename_component(jit_output_directory "${ARG_OUTPUT}" DIRECTORY)
    list(APPEND JIT_PREPROCESSED_FILES "${ARG_OUTPUT}")

    # Note: need to pass _FILE_OFFSET_BITS=64 in COMMAND due to a limitation in
    # how conda builds glibc
    add_custom_command(
      OUTPUT ${ARG_OUTPUT}
      DEPENDS jitify_preprocess "${ARG_SOURCE_DIRECTORY}/${ARG_FILE}"
      WORKING_DIRECTORY ${ARG_SOURCE_DIRECTORY}
      VERBATIM
      COMMAND ${CMAKE_COMMAND} -E make_directory "${jit_output_directory}"
      COMMAND
        "${CMAKE_COMMAND}" -E env LD_LIBRARY_PATH=${CUDAToolkit_LIBRARY_DIR}
        $<TARGET_FILE:jitify_preprocess> ${ARG_FILE} -o ${GENERATED_INCLUDE_DIR}
        -i -std=c++17 -remove-unused-globals -D_FILE_OFFSET_BITS=64
        -D__CUDACC_RTC__ -DRUNTIME_JIT -I${CMAKE_CURRENT_SOURCE_DIR} ${includes}
        --no-preinclude-workarounds --no-replace-pragma-once
      COMMENT "Custom command to JIT-compile files.")
  endforeach()
  set(JIT_PREPROCESSED_FILES
      "${JIT_PREPROCESSED_FILES}"
      PARENT_SCOPE)
endfunction()

if(NOT (EXISTS "${GENERATED_INCLUDE_DIR}"))
  make_directory("${GENERATED_INCLUDE_DIR}")
endif()

jit_preprocess_files(SOURCE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} FILES
                     jit_kernel.cu)

add_custom_target(
  jitify_preprocess_run
  DEPENDS ${JIT_PREPROCESSED_FILES}
  COMMENT "Target representing jitified files.")

# when a user requests CMake to clean the build directory
#
# * `cmake --build <dir> --target clean`
# * `cmake --build <dir> --clean-first`
# * ninja clean
#
# We also remove the jitify2 program cache as well. This ensures that we don't
# keep older versions of the programs in cache
set(cache_path "$ENV{HOME}/.cudf")
if(ENV{LIBCUDF_KERNEL_CACHE_PATH})
  set(cache_path "$ENV{LIBCUDF_KERNEL_CACHE_PATH}")
endif()
cmake_path(APPEND cache_path "${CUDF_VERSION}/")
set_target_properties(jitify_preprocess_run PROPERTIES ADDITIONAL_CLEAN_FILES
                                                       "${cache_path}")

add_executable(launch launch.cu)
add_dependencies(launch jitify_preprocess_run)
target_include_directories(launch PUBLIC ${GENERATED_INCLUDE_DIR}
                                         ${jitify_SOURCE_DIR})
