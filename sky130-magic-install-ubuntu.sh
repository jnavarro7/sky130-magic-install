#!/bin/bash

#set -euo pipefail
set -ex

prerequisites-install() {
    echo "Installing prerequisites"
    sudo apt update
#    sudo apt install -y build-essential git tcl-dev tk-dev libx11-dev libxext-dev \
#        libxrender-dev libxss-dev libgl1-mesa-dev libglu1-mesa-dev \
#        libcairo2-dev python3 python3-pip wget bison flex
    sudo apt install -y build-essential tar bzip2 m4 tcsh csh libx11-dev tcl-dev tk-dev libcairo2-dev mesa-common-dev libglu1-mesa-dev libncurses-dev 
    echo Done with prerequisites install
}

cleaning() {
    echo "Cleaning"
    echo Cleaning, removing directory structure.
    rm -rf $HOME/miniconda3
    rm -rf $HOME/magic
    rm -rf $HOME/skywater-pdk
    rm -rf $HOME/open_pdks
}
install-conda() {
    echo "Installing conda"
    cd "$HOME"
    if [ ! -d "miniconda3" ]; then
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
        # curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
        bash Miniconda3-latest-Linux-x86_64.sh -b -p "$HOME/miniconda3"
        rm Miniconda3-latest-Linux-x86_64.sh
        # Initialize conda for bash
        "$HOME/miniconda3/bin/conda" init bash
    fi
    # Reload bashrc to activate conda
    source ~/.bashrc
}

install-magic() {
    echo "Installing magic"
    set -e
    git clone https://github.com/RTimothyEdwards/magic.git
    cd magic
    ./configure
    make
    sudo make install
}

accept-conda-tos() {
    echo "Accepting conda terms of service"
    set -e
    # Accept TOS for SkyWater
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
}

install-skywater130() {
    echo "Installing skywater130A"
    set -e
    cd "$HOME"
    git clone https://github.com/google/skywater-pdk.git
    wget http://opencircuitdesign.com/open_pdks/archive/open_pdks-1.0.535.tgz
    tar -xvf open_pdks-1.0.535.tgz
    pushd open_pdks-1.0.535
    ./configure --enable-sky130-pdk=/home/jn/skywater-pdk
    make
    sudo make install
    popd
    pushd skywater-pdk
    sed -i 's/^rst_include$/# rst_include/' requirements.txt
    make timing # make all  # To download all data
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
    echo "Testing magic"
    set -e
    if magic --version >/dev/null 2>&1; then
        echo "magic is installed and reachable in PATH"
    else
        echo "magic test failed" >&2
        exit 1
    fi
    echo Launch Magic with the following command:
    echo "magic -rcfile ~/skywater-pdk/env/conda/envs/skywater-pdk-scripts/share/pdk/sky130A/libs.tech/magic/sky130A.magicrc"
}

prerequisites-install
cleaning
install-conda
install-magic
accept-conda-tos
install-skywater130
set-environment-variables
test-magic