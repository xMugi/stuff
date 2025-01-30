#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

wget https://github.com/docker/cli/archive/v20.10.2.tar.gz -O cli-20.10.2.tar.gz
tar xf cli-20.10.2.tar.gz
mkdir -p src/github.com/docker
mv docker-cli-20.10.2 src/github.com/docker/cli

export GOPATH=$(pwd)
export VERSION=v20.10.2-ce
export DISABLE_WARN_OUTSIDE_CONTAINER=1

cd src/github.com/docker/cli
xargs sed -i 's_/var/\(run/docker\.sock\)_/data/docker/\1_g' < <(grep -R /var/run/docker\.sock | cut -d':' -f1 | sort | uniq)

patch vendor/github.com/containerd/containerd/platforms/database.go ../../../../database.go.patch.txt
patch scripts/docs/generate-man.sh ../../../../generate-man.sh.patch.txt
patch man/md2man-all.sh ../../../../md2man-all.sh.patch.txt
patch cli/config/config.go ../../../../config.go.patch.txt

make dynbinary
make manpages

install -Dm 0700 build/docker-android-* $PREFIX/bin/docker
install -Dm 600 -t $PREFIX/share/man/man1 man/man1/*
install -Dm 600 -t $PREFIX/share/man/man5 man/man5/*
install -Dm 600 -t $PREFIX/share/man/man8 man/man8/*

echo "Docker CLI build and installation completed successfully."
