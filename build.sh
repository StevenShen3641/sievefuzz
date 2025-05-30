#!/bin/bash
set -ex

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
##

if [ ! -d "$FUZZER/repo" ]; then
    echo "fetch.sh must be executed first."
    exit 1
fi

cd "$FUZZER/SVF"
./build.sh || true

cd "$FUZZER/repo"
AF=1 TRACE_METRIC=1 CC=clang-9 CXX=clang++-9 LLVM_CONFIG=llvm-config-9 make all -j $(nproc) || exit 1
cd llvm_mode
AF=1 TRACE_METRIC=1 CC=clang-9 CXX=clang++-9 LLVM_CONFIG=llvm-config-9 make all -j $(nproc) || exit 1

# Setup gllvm
cp "$FUZZER/src/gllvm_bins/"* "$FUZZER/SVF/Release-build/bin/"

# Need to check aflpp driver
# mkdir -p "$OUT/afl" "$OUT/cmplog"
