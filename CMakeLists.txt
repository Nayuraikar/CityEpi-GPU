
cmake_minimum_required(VERSION 3.20)

project(CityEpiGPU LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(ENABLE_OPENMP "Enable OpenMP" OFF)
option(ENABLE_MPI "Enable MPI" OFF)

add_library(cityepi_core STATIC
    src/common/simulation.cpp
    src/common/contact.cpp
    src/common/transitions.cpp
    src/common/rng.cpp
    src/v1_ilp/v1_simulation.cpp
    src/v2_openmp/v2_simulation.cpp
)
target_include_directories(cityepi_core PUBLIC include)

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

target_compile_options(cityepi_core PUBLIC
    -O3
    -Wall
    -Wextra
)
