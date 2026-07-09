#! /bin/sh

# Check that we are given the right amount of parameters
if [ $# -ne 4 -a $# -ne 5 ];
then 
	echo "ERROR: wrong amount of parameters, the call syntax for this script is:\n{...}/start-and-run.sh {...}/riscv-docker main.c [data.h] kernel.mlir main.elf" 1>&2
	exit 1
fi

docker --version > /dev/null 2>&1

#Check that docker exists and can be run
if [ $? -ne 0 ];
then
	echo "ERROR: Docker does not seem to be installed, please install it before running this script!"
	exit 2
fi

set -e

MAINC=$2
DATAH=""
KERNELMLIR=""
COMPILED=""

if [ $# -eq 5 ];
then
	DATAH=$3
	KERNELMLIR=$4
	COMPILED=$5
else
	KERNELMLIR=$3
	COMPILED=$4
fi

# Check that parameters correspond to the correct stuff

if test $# -eq 5 && ! test -f $DATAH;
then
	echo "ERROR: \"$DATAH\" is not a regular file!" 1>&2
	exit 2
fi

if ! [ -f $MAINC ];
then
	echo "ERROR: \"$MAINC\" is not a regular file!" 1>&2
	exit 3
fi

if ! test -f $KERNELMLIR;
then
	echo "ERROR: \"$KERNELMLIR\" is not a regular file!" 1>&2
	exit 4
fi

DATAEXT=${DATAH##*.}

if test $# -eq 5 && test $DATAEXT != "h" -a $DATAEXT != "H";
then
	echo "ERROR: \"$DATAH\" is not a C/C++ header file! (check by extension)" 1>&2
	exit 5
fi

MAINEXT=${MAINC##*.}

if test $MAINEXT != "c" -a $MAINEXT != "cc" -a $MAINEXT != "cpp" -a $MAINEXT != "C" -a $MAINEXT != "CC" -a $MAINEXT != "CPP";
then
	echo "ERROR: \"$MAINC\" is not a C/C++ file! (check by extension)" 1>&2
	exit 6
fi

KERNELEXT=${KERNELMLIR##*.}

if test $KERNELEXT != "mlir" -a $KERNELEXT != "MLIR";
then
	echo "ERROR: \"$KERNELMLIR\" is not an mlir file! (check by extension)" 1>&2
	exit 7
fi

REPO=$1

if ! [ -d $REPO ];
then
	echo "ERROR: $REPO should be a directory, but it's not!" 1>&2
	exit 8
fi

LAST_DIR=$(pwd)
cd $REPO
REPO=$(pwd)
cd $LAST_DIR

VENV="$REPO/.venv-docker"

# Delete old venv if present
if [ -d $VENV ];
then 
	echo "Removing old Venv"
	sudo rm -rf $VENV
fi

# Copy files into the riscv-paper-experiments repo
cp ./compile-and-run.sh $REPO

cp $2 $REPO

cp $3 $REPO

if [ $# -eq 5 ];
then
	cp $4 $REPO
fi

# Start the vm and run the compilation script
docker run --rm -ti --volume $REPO:/src ghcr.io/opencompl/snitch-toolchain:4.0.0 /bin/bash -c "cd /src; ./compile-and-run.sh $MAINC $KERNELMLIR $COMPILED"
