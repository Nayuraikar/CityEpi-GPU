
cmake_minimum_required(VERSION 3.20)

project(CityEpiGPU LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(ENABLE_OPENMP "Enable OpenMP" OFF)
option(ENABLE_MPI "Enable MPI" OFF)
option(ENABLE_CUDA "Build V5 (naive CUDA, needs nvcc + a GPU to run); independent of ENABLE_OPENACC" OFF)
option(ENABLE_OPENACC "Build V4 (OpenACC): GCC -fopenacc host fallback or NVHPC nvc++ -acc=gpu" OFF)

add_library(cityepi_core STATIC
    src/common/simulation.cpp
    src/common/contact.cpp
    src/common/transitions.cpp
    src/common/rng.cpp
    src/v1_ilp/v1_simulation.cpp
    src/v2_openmp/v2_simulation.cpp
)
target_include_directories(cityepi_core PUBLIC include)

# V3 (SIMD / ARM NEON): separate target; scalar fallback is compiled on non-NEON targets.
add_library(cityepi_v3 STATIC src/v3_simd/v3_simulation.cpp src/v3_simd/v3_hybrid.cpp)
target_link_libraries(cityepi_v3 PUBLIC cityepi_core)

add_executable(cityepi src/common/main.cpp)
target_link_libraries(cityepi PRIVATE cityepi_core)

enable_testing()
add_executable(test_v0 tests/test_v0.cpp)
target_link_libraries(test_v0 PRIVATE cityepi_core)
add_test(NAME v0 COMMAND test_v0)
add_executable(test_v1 tests/test_v1.cpp)
target_link_libraries(test_v1 PRIVATE cityepi_core)
add_test(NAME v1 COMMAND test_v1)
add_executable(test_v2 tests/test_v2.cpp)
target_link_libraries(test_v2 PRIVATE cityepi_core)
add_test(NAME v2 COMMAND test_v2)
add_executable(test_v3 tests/test_v3.cpp)
target_link_libraries(test_v3 PRIVATE cityepi_v3)
add_test(NAME v3 COMMAND test_v3)
add_executable(bench_v3 bench/bench_v3.cpp)
target_link_libraries(bench_v3 PRIVATE cityepi_v3)
add_executable(bench_v2 bench/bench_v2.cpp)
target_link_libraries(bench_v2 PRIVATE cityepi_core)
add_executable(bench_v0v1 bench/bench.cpp)
target_link_libraries(bench_v0v1 PRIVATE cityepi_core)

if(ENABLE_OPENMP)
    if(APPLE AND EXISTS /opt/homebrew/opt/libomp AND NOT OpenMP_ROOT)
        set(OpenMP_ROOT /opt/homebrew/opt/libomp)
    endif()
    find_package(OpenMP REQUIRED)
    target_link_libraries(cityepi_core PUBLIC OpenMP::OpenMP_CXX)
else()
    target_compile_options(cityepi_core PUBLIC -Wno-unknown-pragmas)
endif()

if(ENABLE_MPI)
    find_package(MPI REQUIRED)
    target_link_libraries(cityepi_core PUBLIC MPI::MPI_CXX)
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL "NVHPC")
    target_compile_options(cityepi_core PUBLIC -O3)
else()
    target_compile_options(cityepi_core PUBLIC
        -O3
        -Wall
        -Wextra
    )
endif()

# V4 (OpenACC): opt-in, independent of V0-V3. Nothing above changes when OFF.
#   GCC host fallback : cmake -DENABLE_OPENACC=ON -DCMAKE_CXX_COMPILER=g++-16   (-fopenacc, no GPU)
#   NVHPC GPU         : cmake -DENABLE_OPENACC=ON -DCMAKE_CXX_COMPILER=nvc++ [-DCITYEPI_GPU_CC=75]
if(ENABLE_OPENACC)
    if(CMAKE_CXX_COMPILER_ID STREQUAL "NVHPC")
        set(CITYEPI_ACC_FLAGS "-acc=gpu" "-Minfo=accel")
        if(CITYEPI_GPU_CC)
            list(APPEND CITYEPI_ACC_FLAGS "-gpu=cc${CITYEPI_GPU_CC}")
        endif()
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set(CITYEPI_ACC_FLAGS "-fopenacc")
    else()
        message(FATAL_ERROR "ENABLE_OPENACC needs GCC (-fopenacc) or NVHPC nvc++; got ${CMAKE_CXX_COMPILER_ID}")
    endif()
    add_library(cityepi_v4 STATIC src/v4_openacc/v4_simulation.cpp)
    target_include_directories(cityepi_v4 PUBLIC include)
    target_compile_options(cityepi_v4 PUBLIC ${CITYEPI_ACC_FLAGS})
    target_link_options(cityepi_v4 PUBLIC ${CITYEPI_ACC_FLAGS})
    target_link_libraries(cityepi_v4 PUBLIC cityepi_core cityepi_v3)

    # Flags as actually applied to bench_v4's translation unit (compile order): global flags,
    # per-config flags, std flag, cityepi_core PUBLIC options, V4 OpenACC options.
    if(CMAKE_BUILD_TYPE)
        string(TOUPPER "${CMAKE_BUILD_TYPE}" _cfg_up)
        set(_cfg_flags "${CMAKE_CXX_FLAGS_${_cfg_up}}")
        set(_cfg_name "${CMAKE_BUILD_TYPE}")
    else()
        set(_cfg_flags "")
        set(_cfg_name "none")
    endif()
    get_target_property(_core_opts cityepi_core INTERFACE_COMPILE_OPTIONS)
    if(NOT _core_opts)
        set(_core_opts "")
    endif()
    set(_flag_list ${CMAKE_CXX_FLAGS} ${_cfg_flags} -std=c++${CMAKE_CXX_STANDARD} ${_core_opts} ${CITYEPI_ACC_FLAGS})
    string(REPLACE ";" " " _flags_joined "${_flag_list}")
    string(STRIP "${_flags_joined}" _flags_joined)
    set(CITYEPI_BUILD_FLAGS_STR "${_flags_joined} [build_type=${_cfg_name} openmp=${ENABLE_OPENMP}]")
    add_executable(test_v4 tests/test_v4.cpp)
    target_link_libraries(test_v4 PRIVATE cityepi_v4)
    add_test(NAME v4 COMMAND test_v4)
    add_executable(bench_v4 bench/bench_v4.cpp)
    target_link_libraries(bench_v4 PRIVATE cityepi_v4)
    target_compile_definitions(bench_v4 PRIVATE "CITYEPI_BUILD_FLAGS=\"${CITYEPI_BUILD_FLAGS_STR}\"")
endif()

# V5 (CUDA): opt-in, independent of V0-V4 and of ENABLE_OPENACC. Nothing above changes when OFF.
#   cmake -S . -B build -DENABLE_CUDA=ON -DCMAKE_BUILD_TYPE=Release [-DCMAKE_CUDA_ARCHITECTURES=75]   (T4 = sm_75)
# cityepi_core is linked LINK_ONLY so its host-only options (-Wall -Wextra ...) never reach nvcc.
# -fmad=false keeps V0's floating-point operation order (no FMA contraction) in the probability kernel.
if(ENABLE_CUDA)
    if(NOT CMAKE_CUDA_ARCHITECTURES)
        set(CMAKE_CUDA_ARCHITECTURES 75)
    endif()
    enable_language(CUDA)
    find_package(CUDAToolkit REQUIRED)
    set(CMAKE_CUDA_STANDARD 17)
    set(CMAKE_CUDA_STANDARD_REQUIRED ON)
    set(CITYEPI_NVCC_FLAGS -fmad=false -prec-div=true -prec-sqrt=true)

    add_library(cityepi_v5 STATIC src/v5_cuda/v5_simulation.cu src/v5_cuda/v5_host_info.cpp)
    target_include_directories(cityepi_v5 PUBLIC include)
    target_compile_options(cityepi_v5 PRIVATE
        $<$<COMPILE_LANGUAGE:CUDA>:${CITYEPI_NVCC_FLAGS}>
        $<$<COMPILE_LANGUAGE:CXX>:-O3 -Wall -Wextra>)
    target_link_libraries(cityepi_v5 PUBLIC $<LINK_ONLY:cityepi_core> CUDA::cudart)

    if(CMAKE_BUILD_TYPE)
        string(TOUPPER "${CMAKE_BUILD_TYPE}" _v5_up)
        set(_v5_cxx_cfg "${CMAKE_CXX_FLAGS_${_v5_up}}")
        set(_v5_cuda_cfg "${CMAKE_CUDA_FLAGS_${_v5_up}}")
        set(_v5_name "${CMAKE_BUILD_TYPE}")
    else()
        set(_v5_cxx_cfg "")
        set(_v5_cuda_cfg "")
        set(_v5_name "none")
    endif()
    string(REPLACE ";" " " _v5_nvcc_opts "${CITYEPI_NVCC_FLAGS}")
    set(CITYEPI_V5_FLAGS_STR "cxx: ${CMAKE_CXX_FLAGS} ${_v5_cxx_cfg} -std=c++${CMAKE_CXX_STANDARD} -O3 | cuda: ${CMAKE_CUDA_FLAGS} ${_v5_cuda_cfg} ${_v5_nvcc_opts} -std=c++${CMAKE_CUDA_STANDARD} archs=${CMAKE_CUDA_ARCHITECTURES} [build_type=${_v5_name} openmp=${ENABLE_OPENMP}]")

    add_executable(test_v5 tests/test_v5.cpp)
    target_link_libraries(test_v5 PRIVATE cityepi_v5)
    target_compile_options(test_v5 PRIVATE -O3 -Wall -Wextra)
    # --require-gpu: a pass must mean kernels really ran on a GPU (a GPU-less machine fails, not skips).
    add_test(NAME v5 COMMAND test_v5 --require-gpu)
    add_executable(bench_v5 bench/bench_v5.cpp)
    target_link_libraries(bench_v5 PRIVATE cityepi_v5 cityepi_v3)
    target_compile_options(bench_v5 PRIVATE -O3 -Wall -Wextra)
    target_compile_definitions(bench_v5 PRIVATE "CITYEPI_BUILD_FLAGS=\"${CITYEPI_V5_FLAGS_STR}\"")
endif()
