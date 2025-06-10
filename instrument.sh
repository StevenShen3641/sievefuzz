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

sievefuzz="$FUZZER/repo" # AFL with SieveFuzz specific modifications

TEMP_LIBS=$LIBS
AFL_RT="$sievefuzz/afl-llvm-rt.o"

# revert bnutils version back to 2.26.1 for objcopy compatibility
export PATH=/opt/binutils-2.26.1/bin:$PATH

AF_CLANG="clang"
AF_CLANGXX="clang++"
AF_LLVMCONFIG="llvm-config"
AF_AR="llvm-ar-9"
AF_LLVMLINK="llvm-link"
GCLANG="$FUZZER/SVF/Release-build/bin/gclang"
GCLANGXX="$FUZZER/SVF/Release-build/bin/gclang++"
GETBC="$FUZZER/SVF/Release-build/bin/get-bc"

export NAME=$(basename "$TARGET")

# Modify configure files for SVF compatibility
case $NAME in
"libsndfile")
    echo
    ;;
"libtiff")
    sed -i '/^# Get latest config\.guess and config\.sub from upstream master since/,$d' $TARGET/repo/autogen.sh
    sed -i 's|./configure --disable-shared --prefix="\$WORK"|./configure --disable-jpeg --disable-old-jpeg --disable-lzma --disable-shared --prefix="\$WORK"|' $TARGET/build.sh
    ;;
"poppler")
    if [[ "${PATCH_NAME}" == "PDF006" ]]; then
        cp "$TARGET/work/poppler/utils/pdftoppm" "$OUT/BITCODE/"
    else
        echo
    fi     
    ;;
esac

clean_counters() {
    rm -f /tmp/fn_indices.txt
    rm -f /tmp/fn_counter.txt
}

build_magma_target() {
    "$MAGMA/build.sh"
    "$TARGET/build.sh"
}

make_bitcode() {
    # Add afl-llvm-rt.o for gclang to compile afl_driver
    export LIBS="$TEMP_LIBS -l:aflpp_driver.o $AFL_RT -lc++ -lc++abi"

    # Sets up the Gclang to use clang-9.0 as the compiler
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$FUZZER/SVF/Release-build

    export PATH=/usr/bin:$PATH

    export CC=$GCLANG
    export CXX=$GCLANGXX
    export LLVM_CONFIG=$AF_LLVMCONFIG
    export PREFIX=$OUT/BITCODE

    ####
    cd "$FUZZER/repo/utils/aflpp_driver"
    $CC -I. -I../../include -g -c aflpp_driver.c -o aflpp_driver.o
    # cd "$FUZZER/repo"
    # make -C utils/aflpp_driver clean || exit 1
    # make -C utils/aflpp_driver || exit 1
    cp $FUZZER/repo/utils/aflpp_driver/aflpp_driver.o $OUT

    clean_counters
    build_magma_target

    mkdir -p $PREFIX

    case $NAME in 
    "libpng")
        cp "$OUT/libpng_read_fuzzer" "$OUT/BITCODE/"
        ;;
    "lua")
        cp "$OUT/lua" "$OUT/BITCODE/"
        ;;
    "libsndfile")
        cp 
        ;;
    "openssl")
        if [[ "${PATCH_NAME}" == "SSL001" || "${PATCH_NAME}" == "SSL003" ]]; then
            cp "$OUT/asn1" "$OUT/BITCODE/"
        else
            echo
        fi  
        ;;
    "php")
        cp "$OUT/exif" "$OUT/BITCODE/"
        ;;
    "libtiff")
        cp "$TARGET/work/bin/tiffcp" "$OUT/BITCODE/"
        ;;
    "poppler")
        if [[ "${PATCH_NAME}" == "PDF006" ]]; then
            cp "$TARGET/work/poppler/utils/pdftoppm" "$OUT/BITCODE/"
        else
            echo
        fi     
        ;;
    esac

    # Create bitcode
    cd $OUT/BITCODE
    echo "$GETBC -a $AF_AR -l $AF_LLVMLINK $(ls -1 | head -n 1)"
    $GETBC -a $AF_AR -l $AF_LLVMLINK $(ls -1 | head -n 1)
}

# Variant with function activation policy inferred through static analysis
make_sievefuzz() {
    export LIBS="$TEMP_LIBS -l:aflpp_driver.o -lc++ -lc++abi"

    # Setup environment variables
    export CC=$sievefuzz/afl-clang-fast
    export CXX=$sievefuzz/afl-clang-fast++
    export LLVM_CONFIG=$AF_LLVMCONFIG
    export AFL_CC=$AF_CLANG
    export AFL_CXX=$AF_CLANGXX
    export AFL_USE_ASAN=1
    export PREFIX=$OUT/sievefuzz
    export ASAN_OPTIONS=detect_leaks=0

    ####
    cd "$FUZZER/repo"
    make -C utils/aflpp_driver clean || exit 1
    AF=1 TRACE_METRIC=1 CC=clang-9 CXX=clang++-9 LLVM_CONFIG=llvm-config-9 make -C utils/aflpp_driver || exit 1
    cp $FUZZER/repo/utils/aflpp_driver/aflpp_driver.o $OUT

    clean_counters
    build_magma_target

    mkdir -p $PREFIX

    # Copy over the function indices list
    cp /tmp/fn_indices.txt $PREFIX/fn_indices.txt
    echo "[X] Please check that the two numbers are within delta of 1. If not, automatically re-run the script to build the target. This info is used to sanity-check that each function was assigned a unique ID" 
    cat /tmp/fn_indices.txt | wc -l && tail -n1 /tmp/fn_indices.txt

    while true; do
        line_count=$(wc -l < /tmp/fn_indices.txt)
        last_line=$(tail -n1 /tmp/fn_indices.txt)
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

# NOTE: We pass $OUT directly to the target build.sh script, since the artifact
#       itself is the fuzz target. In the case of Angora, we might need to
#       replace $OUT by $OUT/fast and $OUT/track, for instance.
