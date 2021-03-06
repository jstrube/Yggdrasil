# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

const name = "libcgal_julia"
const version = v"0.9.1"

# Collection of sources required to build CGAL
const sources = [
    GitSource("https://github.com/rgcv/libcgal-julia.git",
              "306c43938205c81d28cccf47eab5a24297dea5ba"),
]

# Dependencies that must be installed before this package can be built
const dependencies = [
    BuildDependency("Julia_jll"),

    Dependency("CGAL_jll"),
    Dependency("libcxxwrap_julia_jll"),
]

# Bash recipe for building across all platforms
const script = raw"""
## pre-build setup
# exit on error
set -eu

## configure build
cmake libcgal-julia*/ -B build \
  `# cmake specific` \
  -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TARGET_TOOLCHAIN" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_FIND_ROOT_PATH="$prefix" \
  -DCMAKE_INSTALL_PREFIX="$prefix" \
  `# tell jlcxx where julia is` \
  -DJulia_PREFIX="$prefix"

## and away we go..
VERBOSE=ON cmake --build build --config Release --target install -- -j$nproc

install_license libcgal-julia*/LICENSE

# HACK: Apparently, this isn't a simple build system anymore..
case $target in
  *mingw32*) mv "$prefix/lib/"*.dll "$prefix/bin" ;;
esac
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
const platforms = [
    Linux(:x86_64, libc=:glibc),
    MacOS(:x86_64),
    Windows(:x86_64),
] |> expand_cxxstring_abis
filter!(p->cxxstring_abi(p) === :cxx11, platforms)

# The products that we will ensure are always built
const products = [
    LibraryProduct("libcgal_julia_exact", :libcgal_julia_exact),
    LibraryProduct("libcgal_julia_inexact", :libcgal_julia_inexact),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")

