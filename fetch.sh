#!/bin/bash
set -e

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
##

# Clone LLVM-based SVF first
git clone --no-checkout https://github.com/SVF-tools/SVF "$FUZZER/SVF"
git -C "$FUZZER/SVF" checkout a99ee34ed34a67ce72f028ca9dbd8005b5463d05

cp "$FUZZER/src/svf/setup.sh" "$FUZZER/SVF/setup.sh"
cp "$FUZZER/src/svf/build.sh" "$FUZZER/SVF/build.sh"

cp "$FUZZER/src/svf/svf-ex.cpp" "$FUZZER/SVF/tools/Example/svf-ex.cpp"
cp "$FUZZER/src/svf/GenericGraph.h" "$FUZZER/SVF/include/Graphs/GenericGraph.h"
cp "$FUZZER/src/svf/CMakeLists.txt" "$FUZZER/SVF/tools/Example/CMakeLists.txt"

cp "$FUZZER/src/svf/fence.cpp" "$FUZZER/SVF/tools/Example/fence.cpp"
cp "$FUZZER/src/svf/util.cpp" "$FUZZER/SVF/tools/Example/util.cpp"
cp "$FUZZER/src/svf/svf-af.h" "$FUZZER/SVF/include/svf-af.h"

git clone --no-checkout https://github.com/gabime/spdlog "$FUZZER/spdlog"
# Need check
git -C "$FUZZER/spdlog" checkout ad0e89cbfb4d0c1ce4d097e134eb7be67baebb36

cp -r "$FUZZER/spdlog/include/spdlog/" "$FUZZER/SVF/include"


# Clone AFL++
git clone --no-checkout https://github.com/AFLplusplus/AFLplusplus "$FUZZER/repo"
git -C "$FUZZER/repo" checkout 70a67ca67d0ea105d2b75dae388be03051cf0bf3

cp "$FUZZER/src/afl/afl-fuzz.c" "$FUZZER/repo/src/afl-fuzz.c"
cp "$FUZZER/src/afl/afl-fuzz-queue.c" "$FUZZER/repo/src/afl-fuzz-queue.c"
cp "$FUZZER/src/afl/afl-fuzz-globals.c" "$FUZZER/repo/src/afl-fuzz-globals.c"
cp "$FUZZER/src/afl/afl-fuzz-run.c" "$FUZZER/repo/src/afl-fuzz-run.c"
cp "$FUZZER/src/afl/afl-sharedmem.c" "$FUZZER/repo/src/afl-sharedmem.c"

cp "$FUZZER/src/afl/afl-fuzz.h" "$FUZZER/repo/include/afl-fuzz.h"
cp "$FUZZER/src/afl/config.h" "$FUZZER/repo/include/config.h"

###
cp "$FUZZER/src/afl/helper.h" "$FUZZER/repo/include/helper.h"
cp "$FUZZER/src/afl/utarray.h" "$FUZZER/repo/include/utarray.h"

cp "$FUZZER/src/afl/Makefile_AFL_llvm_mode" "$FUZZER/repo/llvm_mode/Makefile"
cp "$FUZZER/src/afl/Makefile_AFL" "$FUZZER/repo/Makefile"
cp "$FUZZER/src/afl/afl-llvm-pass.so.cc" "$FUZZER/repo/llvm_mode/afl-llvm-pass.so.cc"
cp "$FUZZER/src/afl/afl-llvm-rt.o.c" "$FUZZER/repo/llvm_mode/afl-llvm-rt.o.c"

cp "$FUZZER/src/afl/fn_bit.txt" "$FUZZER/repo/llvm_mode/fn_bit.txt"

# AFL++ driver
mkdir -p "$FUZZER/repo/utils/aflpp_driver"
cp "$FUZZER/src/aflpp_driver.c" "$FUZZER/repo/utils/aflpp_driver/aflpp_driver.c"
cp "$FUZZER/src/GNUmakefile" "$FUZZER/repo/utils/aflpp_driver/GNUmakefile"
