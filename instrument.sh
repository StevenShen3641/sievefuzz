#!/bin/bash
set -ex

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
# - env TARGET: path to target work dir
# - env MAGMA: path to Magma support files
# - env OUT: path to directory where artifacts are stored
# - env CFLAGS and CXXFLAGS must be set to link against Magma instrumentation
##

ROOT="$FUZZER"
sievefuzz="$ROOT/repo" # AFL with SieveFuzz specific modifications

# revert bnutils version back to 2.26.1 for objcopy compatibility
export PATH=/opt/binutils-2.26.1/bin:$PATH

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

clean_counters() {
    rm -f /tmp/fn_indices.txt
    rm -f /tmp/fn_counter.txt
}

build_magma_target() {
    "$MAGMA/build.sh"
    "$TARGET/build.sh"
}

make_bitcode() {

    # Sets up the Gclang to use clang-9.0 as the compiler
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$FUZZER/SVF/Release-build

    export PATH=/usr/bin:$PATH

    export CC=$GCLANG
    export CXX=$GCLANGXX
    export CFLAGS="-g" 
    export LLVM_CONFIG=$AF_LLVMCONFIG
    export PREFIX=$OUT/BITCODE

    clean_counters
    build_magma_target

    mkdir $PREFIX

    case $NAME in 
    "libtiff")
        echo
        ;;
    "poppler")
        if [[ "${PATCH_NAME}" == "PDF006" ]]; then
            cp "$TARGET/work/poppler/utils/pdftoppm" "$OUT/BITCODE/"
        else
            echo
        fi     

    # Create bitcode
    cd $OUT/BITCODE
    echo "$GETBC -a $AF_AR -l $AF_LLVMLINK $(ls -1 | head -n 1)"
    $GETBC -a $AF_AR -l $AF_LLVMLINK $(ls -1 | head -n 1)
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
    build_magma_target

    # Copy over the function indices list
    mkdir $OUT/sievefuzz

    cp /tmp/fn_indices.txt $OUT/sievefuzz/fn_indices.txt
    cd -

    echo "[X] Please check that the two numbers are within delta of 1. If not, automatically re-run the script to build the target. This info is used to sanity-check that each function was assigned a unique ID" 
    cat /tmp/fn_indices.txt | wc -l && tail -n1 /tmp/fn_indices.txt

    while true; do
        line_count=$(wc -l < /tmp/fn_indices.txt)
        last_line=$(tail -n1 /tmp/fn_indices.txt)
        
        # Extract the number after the last colon
        last_num=$(echo "$last_line" | awk -F':' '{print $NF}')
        
        # Check if line count <= last number + 1
        if [ "$line_count" -le $((last_num + 1)) ]; then
            break
        else
            echo "line count ($line_count) > last index + 1 ($((last_num + 1)))"
            clean_counters
            build_magma_target
        fi
    done
}

make_bitcode
make_sievefuzz

# rm -rf $OUT/sievefuzz
# mkdir -p $OUT/sievefuzz

# make_sievefuzz

# export CC="$FUZZER/repo/afl-clang-fast"
# export CXX="$FUZZER/repo/afl-clang-fast++"
# export AS="llvm-as"

# export LIBS="$LIBS -lc++ -lc++abi $FUZZER/repo/utils/aflpp_driver/libAFLDriver.a"

# # AFL++'s driver is compiled against libc++
# export CXXFLAGS="$CXXFLAGS -stdlib=libc++"



# NOTE: We pass $OUT directly to the target build.sh script, since the artifact
#       itself is the fuzz target. In the case of Angora, we might need to
#       replace $OUT by $OUT/fast and $OUT/track, for instance.
