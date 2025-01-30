#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

VERSION=v20.10.2
ARCHIVE_NAME=cli-$VERSION.tar.gz
CLI_DIR=src/github.com/docker/cli
GOPATH_DIR=$(pwd)

# Download Docker CLI source
wget https://github.com/docker/cli/archive/$VERSION.tar.gz -O $ARCHIVE_NAME

# Extract the archive
tar xf $ARCHIVE_NAME

# Create directory structure
mkdir -p src/github.com/docker
mv cli-$VERSION $CLI_DIR

# Set environment variables
export GOPATH=$GOPATH_DIR
export VERSION=${VERSION}-ce
export DISABLE_WARN_OUTSIDE_CONTAINER=1

# Change to CLI directory
cd $CLI_DIR

# Modify docker.sock path
xargs sed -i 's_/var/\(run/docker\.sock\)_/data/docker/\1_g' < <(grep -R /var/run/docker\.sock | cut -d':' -f1 | sort | uniq)

# Apply patches
patch vendor/github.com/containerd/containerd/platforms/database.go ../../../../database.go.patch.txt
patch scripts/docs/generate-man.sh ../../../../generate-man.sh.patch.txt
patch man/md2man-all.sh ../../../../md2man-all.sh.patch.txt
patch cli/config/config.go ../../../../config.go.patch.txt

# Build the binaries
make dynbinary
make manpages

# Install binaries and manpages
install -Dm 0700 build/docker-android-* $PREFIX/bin/docker
install -Dm 600 -t $PREFIX/share/man/man1 man/man1/*
install -Dm 600 -t $PREFIX/share/man/man5 man/man5/*
install -Dm 600 -t $PREFIX/share/man/man8 man/man8/*

echo "Docker CLI build and installation completed successfully."
