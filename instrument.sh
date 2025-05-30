#!/bin/bash
set -e

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
# - env TARGET: path to target work dir
# - env MAGMA: path to Magma support files
# - env OUT: path to directory where artifacts are stored
# - env CFLAGS and CXXFLAGS must be set to link against Magma instrumentation
##

ROOT="$FUZZER"
sievefuzz="$ROOT/sievefuzz" # AFL with SieveFuzz specific modifications

AF_CLANG="clang"
AF_CLANGXX="clang++"
AF_LLVMCONFIG="llvm-config"
AF_AR="llvm-ar-9"
AF_LLVMLINK="llvm-link"
GCLANG="$ROOT/SVF/Release-build/bin/gclang"
GCLANGXX="$ROOT/SVF/Release-build/bin/gclang++"
GETBC="$ROOT/SVF/Release-build/bin/get-bc"

# Declare a binary folder loc array
export NAME=$(basename "$TARGET")
declare -A locs=( 
    # ["lua"]="lua"
    # ["poppler"]="poppler"
    # ["php"]="php"
    # ["libpng"]="libpng"
    # ["sndfile"]="sndfile"
    # ["sqlite3"]="sqlite3"
    ["libtiff"]="bin/tiffcp"
)

clean_counters() {
    rm -f /tmp/fn_indices.txt
    rm -f /tmp/fn_counter.txt
}

build_target() {
    "$MAGMA/build.sh"
    "$TARGET/build.sh"
}

make_bitcode() {
    # Sets up the Gclang to use clang-9.0 as the compiler
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$FUZZER/SVF/Release-build

    export SVFHOME=$FUZZER/SVF
    # export LLVM_DIR=$SVFHOME/llvm-10.0.0.obj
    export PATH=$LLVM_DIR/bin:$PATH

    export CC=$GCLANG
    export CXX=$GCLANGXX
    export CFLAGS="-g" 
    export LLVM_CONFIG=$AF_LLVMCONFIG
    export PREFIX=$OUT/BITCODE

    clean_counters
    build_target
     
    # Create bitcode
    cd $OUT/BITCODE
    echo $PWD
    echo "$GETBC -a $AF_AR -l $AF_LLVMLINK ${locs[${NAME}]}"
    $GETBC -a $AF_AR -l $AF_LLVMLINK ${locs[${NAME}]}
    cd -
}

# Variant with function activation policy inferred through static analysis
make_sievefuzz() {
    # Setup environment variables
    export CC=$sievefuzz/afl-clang-fast
    export CXX=$sievefuzz/afl-clang-fast++
    export LLVM_CONFIG=$AF_LLVMCONFIG
    export AFL_CC=$AF_CLANG
    export AFL_CXX=$AF_CLANGXX
    export AFL_USE_ASAN=1
    export PREFIX=$OUT/sievefuzz
    export ASAN_OPTIONS=detect_leaks=0

    clean_counters
    build_target

    # Copy over the function indices list
    cp /tmp/fn_indices.txt $OUT/sievefuzz/fn_indices.txt
    cd -
    echo "[X] Please check that the two numbers are within delta of 1. If not, please re-run the script to build the target. This info is used to sanity-check that each function was assigned a unique ID" 
    cat /tmp/fn_indices.txt | wc -l && tail -n1 /tmp/fn_indices.txt
}

make_bitcode

# rm -rf $OUT/sievefuzz
# mkdir -p $OUT/sievefuzz

# make_sievefuzz

# export CC="$FUZZER/repo/afl-clang-fast"
# export CXX="$FUZZER/repo/afl-clang-fast++"
# export AS="llvm-as"

# export LIBS="$LIBS -lc++ -lc++abi $FUZZER/repo/utils/aflpp_driver/libAFLDriver.a"

# # AFL++'s driver is compiled against libc++
# export CXXFLAGS="$CXXFLAGS -stdlib=libc++"

# # Build the AFL-only instrumented version
# (
#     export OUT="$OUT/afl"
#     export LDFLAGS="$LDFLAGS -L$OUT"

#     "$MAGMA/build.sh"
#     "$TARGET/build.sh"
# )

# # Build the CmpLog instrumented version

# (
#     export OUT="$OUT/cmplog"
#     export LDFLAGS="$LDFLAGS -L$OUT"
#     # export CFLAGS="$CFLAGS -DMAGMA_DISABLE_CANARIES"

#     export AFL_LLVM_CMPLOG=1

#     "$MAGMA/build.sh"
#     "$TARGET/build.sh"
# )

# NOTE: We pass $OUT directly to the target build.sh script, since the artifact
#       itself is the fuzz target. In the case of Angora, we might need to
#       replace $OUT by $OUT/fast and $OUT/track, for instance.
