#!/bin/bash

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
# - env TARGET: path to target work dir
# - env OUT: path to directory where artifacts are stored
# - env SHARED: path to directory shared with host (to store results)
# - env PROGRAM: name of program to run (should be found in $OUT)
# - env ARGS: extra arguments to pass to the program
# - env FUZZARGS: extra arguments to pass to the fuzzer
##

if nm "$OUT/afl/$PROGRAM" | grep -E '^[0-9a-f]+\s+[Ww]\s+main$'; then
    ARGS="-"
fi

mkdir -p "$SHARED/findings/output"

declare -A targets
targets["PNG003"]="MAGMA_png_handle_PLTE"

targets["SND005"]="aiff_read_chanmap"

targets["PDF006"]="blitTransparent"

targets["SSL003"]="asn1_d2i_read_bio"

targets["PHP011"]="exif_offset_info_try_get"

targets["TIF007"]="ChopUpSingleUncompressedStrip"
targets["TIF012"]="setExtraSamples"
targets["TIF014"]="ChopUpSingleUncompressedStrip"

targets["LUA004"]="luaG_traceexec"
# targets["PDF006"]="blitTransparent"
# targets["PDF006"]="blitTransparent"
# targets["PDF006"]="blitTransparent"
# targets["PDF006"]="blitTransparent"
# targets["PDF006"]="blitTransparent"

export AFL_SKIP_CPUFREQ=1
export AFL_NO_AFFINITY=1
export AFL_NO_UI=1
export AFL_MAP_SIZE=256000
export AFL_DRIVER_DONT_DEFER=1

# export PROGRAM=sndfile_fuzzer


"$FUZZER/SVF/Release-build/bin/svf-ex" -p=6200 --tag="$SHARED/findings/output" \
    -f="${targets[${PATCH_NAME}]}" --get-indirect --activation="$OUT/sievefuzz/fn_indices.txt" \
    --stat=false --run-server --dump-stats "$OUT/BITCODE/${PROGRAM}.bc" &

sleep 30

"$FUZZER/repo/afl-fuzz" -m none -P 6200 -i "$TARGET/corpus/$PROGRAM" -o "$SHARED/findings" \
    -d $FUZZARGS -- "$OUT/$PROGRAM" $ARGS 2>&1
