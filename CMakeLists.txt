
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
)
target_include_directories(cityepi_core PUBLIC include)

add_executable(cityepi src/common/main.cpp)
target_link_libraries(cityepi PRIVATE cityepi_core)

enable_testing()
add_executable(test_v0 tests/test_v0.cpp)
target_link_libraries(test_v0 PRIVATE cityepi_core)
add_test(NAME v0 COMMAND test_v0)

if(ENABLE_OPENMP)
    find_package(OpenMP REQUIRED)
    target_link_libraries(cityepi_core PUBLIC OpenMP::OpenMP_CXX)
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
