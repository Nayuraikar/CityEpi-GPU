
cmake_minimum_required(VERSION 3.20)

project(CityEpiGPU LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(ENABLE_OPENMP "Enable OpenMP" OFF)
option(ENABLE_MPI "Enable MPI" OFF)
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
