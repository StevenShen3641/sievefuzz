#!/bin/bash
set -e

apt update && \
    apt install -y \
    silversearcher-ag beanstalkd gdb screen patchelf apt-transport-https ca-certificates clang-9 libclang-9-dev zlib1g-dev\
    gcc-7 g++-7 sudo curl wget build-essential make cmake ninja-build git subversion python3 python3-dev python3-pip autoconf automake &&\
    python3 -m pip install --upgrade pip && python3 -m pip install greenstalk psutil 

update-alternatives --install /usr/bin/clang clang /usr/bin/clang-9 10 \
                        --slave /usr/bin/clang++ clang++ /usr/bin/clang++-9 \
                        --slave /usr/bin/opt opt /usr/bin/opt-9

update-alternatives --install /usr/lib/llvm llvm /usr/lib/llvm-9 20 \
                        --slave /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-9 \
                        --slave /usr/bin/llvm-link llvm-link /usr/bin/llvm-link-9
