#!/bin/bash -ex

# Config, edit me!
HOST=x86_64-unknown-linux-gnu
TARGET=powerpc-unknown-linux-gnu
LINKERFLAG="-C linker=powerpc-linux-gnu-gcc" # Set this only if you need to use a nonstandard linker
####

# Setup and use:
# On your build machine
#   ./configure --target=<target> --disable-jemalloc
#   make
#
# While that's running:
# On your target machine
#   ./configure
#   make <target>/rt/librustllvm.a
#
# From your target machine, copy:
#   <target>/llvm/Release+Asserts/lib
#   <target>/rt/librustllvm.a
#
# Back to your host.
# Finally:
#   ./cross.sh
#
# And hopefully you get a working, target native rustc!

export CFG_LLVM_LINKAGE_FILE=`pwd`/$HOST/rt/llvmdeps.rs
export LD_LIBRARY_PATH=./$HOST/stage2/lib
_RUSTC=./$HOST/stage2/bin/rustc
RUSTC="$_RUSTC $LINKERFLAG --target $TARGET -L $TARGET/rt -L $TARGET/stage2/bootstrap -L $TARGET/llvm/Release+Asserts/lib"

# Setup for the llvm build we'll inject
mkdir -p ./$TARGET/llvm/Release+Asserts/lib
# TODO Technically this conflicts with the instructions, an -ssh option to
# login to, build, and then fetch the assets would be pretty neat.

mkdir -p ./$TARGET/stage2/lib
mkdir -p ./$TARGET/stage2/bin
mkdir -p ./$TARGET/stage2/bootstrap

# Rebuild all of the things we have natively
# for lib in ./$HOST/stage2/lib/*.so; do
#     lib=$(echo "$lib" | grep -Eo "lib[a-z_]+-4e7c5e5c.so" | sed -e "s/-.*$//")

for lib in libfmt_macros libarena libflate libgetopts libgraphviz liblog librbml libsyntax libserialize libstd libterm libtest librustc_back librustc_llvm librustc librustc_borrowck librustc_lint librustc_privacy librustc_resolve librustc_trans librustc_typeck librustc_driver; do
    $RUSTC --out-dir ./$TARGET/stage2/lib src/$lib/lib.rs

    case $lib in
        libfmt_macros | libsyntax | librustc | librustc*)
            # This glob will do the wrong thing for librustc
            cp ./$TARGET/stage2/lib/$lib* ./$TARGET/stage2/bootstrap
            ;;
    esac
done

# Finally, build rustc using only our new crates

$RUSTC -o ./$TARGET/stage2/bin/rustc --cfg rustc src/driver/driver.rs
