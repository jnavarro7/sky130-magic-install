#!/bin/bash

#set -euo pipefail

prerequisites-install() {
    sudo dnf install -y  @development-tools 
    sudo dnf install -y gcc-c++ git tcl-devel tk-devel libX11-devel libXext-devel \
        libXrender-devel libXScrnSaver-devel mesa-libGL-devel \
        mesa-libGLU-devel cairo-devel \
        python3 python3-pip wget bison flex
}

install-conda() {
    cd "$HOME"
    if [ ! -d "miniconda3" ]; then
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
        bash Miniconda3-latest-Linux-x86_64.sh -b -p "$HOME/miniconda3"
        rm Miniconda3-latest-Linux-x86_64.sh
        # Initialize conda for bash
        "$HOME/miniconda3/bin/conda" init bash
    fi
    # Reload bashrc to activate conda
    source ~/.bashrc
}

install-magic() {
    set -e
    git clone https://github.com/RTimothyEdwards/magic.git
    cd magic
    ./configure
    make
    sudo make install
}

accept-conda-tos() {
    set -e
    # Accept TOS for SkyWater
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
}

install-skywater130() {
    set -e
    cd "$HOME"
    git clone https://github.com/google/skywater-pdk.git
    cd skywater-pdk
    make timing
    # make all  # To download all data
}

set-environment-variables() {
    set -e
    # Usually you add PDK_ROOT to ~/.bashrc instead of just exporting here, e.g.:
    if ! grep -q 'PDK_ROOT=' "$HOME/.bashrc"; then
        echo 'export PDK_ROOT="$HOME/skywater-pdk"' >> "$HOME/.bashrc"
    fi
    # Then source it for the current shell
    # shellcheck source=/dev/null
    source "$HOME/.bashrc"
}

test-magic() {
    set -e
    if magic --version >/dev/null 2>&1; then
        echo "magic is installed and reachable in PATH"
    else
        echo "magic test failed" >&2
        exit 1
    fi
}

prerequisites-install
install-conda
install-magic
accept-conda-tos
install-skywater130
set-environment-variables
test-magic
