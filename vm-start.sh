#! /bin/sh

if [ $# -ne 1 ];
then 
	echo "ERROR: wrong amount of parameters, the call syntax for this script is: {...}/start-vm.sh {...}/riscv-paper-experiments" 1>&2
	exit 1
fi

docker --version > /dev/null 2>&1

if [ $? -ne 0 ];
then
	echo "ERROR: Docker does not seem to be installed, please install it before running this script!"
	exit 2
fi

set -e

REPO=$1

if ! [ -d $REPO ];
then
	echo "ERROR: $REPO should be a directory, but it's not!" 1>&2
	exit 3
fi

LAST_DIR=$(pwd)
cd $REPO
REPO=$(pwd)
cd $LAST_DIR

VENV="$REPO/.venv-docker"

if [ -d $VENV ];
then 
	sudo rm -rf $VENV
fi

cp ./compile-and-run.sh $REPO
cp ./compile.sh $REPO
cp ./run.sh $REPO

docker run --rm -ti --volume $REPO:/src ghcr.io/opencompl/snitch-toolchain:7.0.0 /bin/bash -c "cd /src; exec bash"
