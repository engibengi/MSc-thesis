#! /bin/sh

set -e

if [ $# -ne 3 ];
then 
	echo "ERROR: wrong amount of parameters, the call syntax for this script is: ./compile-and-run.sh main.c kernel.mlir compiled.elf" 1>&2
	exit 1
fi

MAINC=$1
KERNELMLIR=$2
COMPILED=$3

if ! [ -f "$MAINC" ];
then
	echo "ERROR: \"$MAINC\" is not a file!" 1>&2
	exit 2
fi

if ! test -f "$KERNELMLIR";
then
	echo "ERROR: \"$KERNELMLIR\" is not a file!" 1>&2
	exit 3
fi

MAINEXT=${MAINC##*.}

if test "$MAINEXT" != "c" -a "$MAINEXT" != "cc" -a "$MAINEXT" != "cpp" -a "$MAINEXT" != "C" -a "$MAINEXT" != "CC" -a "$MAINEXT" != "CPP";
then
	echo "ERROR: \"$MAINC\" is not a C/C++ file! (check by extension)" 1>&2
	exit 4
fi

KERNELEXT=${KERNELMLIR##*.}

if test "$KERNELEXT" != "mlir" -a "$KERNELEXT" != "MLIR";
then
	echo "ERROR: \"$KERNELMLIR\" is not an mlir file! (check by extension)" 1>&2
	exit 5
fi

MAINS=${MAINC%.c*}.S
MAINO=${MAINS%.S}.o
KERNELS=${KERNELMLIR%.mlir}.S
KERNELO=${KERNELS%.S}.o


# Compile C to snitch native riscv
/opt/snitch-llvm/bin/clang++ -Wno-unused-command-line-argument -menable-experimental-extensions -mcpu=snitch -mabi=ilp32d -mcmodel=medany \
						     -ftls-model=local-exec -ffast-math -fno-builtin-printf -fno-common -O3 -D__DEFINED_uint64_t \
						     -I/opt/snitch_cluster/target/snitch_cluster/sw/runtime/rtl/src -I/opt/snitch_cluster/target/snitch_cluster/sw/runtime/common \
						     -I/opt/snitch_cluster/sw/snRuntime/api -I/opt/snitch_cluster/sw/snRuntime/src -I/opt/snitch_cluster/sw/snRuntime/src/omp/ \
						     -I/opt/snitch_cluster/sw/snRuntime/api/omp/ -I/opt/snitch_cluster/sw/math/arch/riscv64/bits/ -I/opt/snitch_cluster/sw/math/arch/generic \
						     -I/opt/snitch_cluster/sw/math/src/include -I/opt/snitch_cluster/sw/math/src/internal -I/opt/snitch_cluster/sw/math/include/bits \
						     -I/opt/snitch_cluster/sw/math/include \
						     -S -x c++ -o $MAINS $MAINC
# Compile mlir to snitch native riscv
/usr/bin/mlir-opt-16 -opaque-pointers=0 -linalg-generalize-named-ops -eliminate-empty-tensors -empty-tensor-to-alloc-tensor \
					     -one-shot-bufferize='bufferize-function-boundaries function-boundary-type-conversion=identity-layout-map allow-return-allocs' \
					     -canonicalize $KERNELMLIR \
			| sed "s/arith.maxf/arith.maximumf/g" \
			| xdsl-opt -p arith-add-fastmath \
			| sed "s/arith.maxf/arith.maximumf/g" \
			| xdsl-opt -p canonicalize,convert-linalg-to-memref-stream,memref-stream-legalize,canonicalize,memref-stream-infer-fill,memref-stream-unnest-out-parameters,memref-stream-fold-fill,memref-stream-generalize-fill,memref-stream-interleave,memref-stream-tile-outer-loops{target_rank=4},memref-streamify,convert-memref-stream-to-loops,canonicalize,scf-for-loop-flatten,canonicalize,convert-memref-to-riscv-snitch,convert-memref-to-riscv,lower-affine,convert-scf-to-riscv-scf,convert-arith-to-riscv-snitch,convert-arith-to-riscv,convert-func-to-riscv-func,convert-memref-stream-to-snitch-stream,reconcile-unrealized-casts,canonicalize,convert-riscv-scf-for-to-frep,snitch-allocate-registers,convert-snitch-stream-to-snitch,lower-snitch,canonicalize,riscv-scf-loop-range-folding,canonicalize,riscv-allocate-registers,canonicalize,convert-riscv-scf-to-riscv-cf,canonicalize -t riscv-asm -o $KERNELS
# Compile main to object
/opt/snitch-llvm/bin/clang++ -menable-experimental-extensions -mcpu=snitch -mabi=ilp32d -mcmodel=medany -ftls-model=local-exec \
					      -ffast-math -fno-builtin-printf -fno-common -O3 -D__DEFINED_uint64_t \
					      -I/opt/snitch_cluster/target/snitch_cluster/sw/runtime/rtl/src -I/opt/snitch_cluster/target/snitch_cluster/sw/runtime/common \
					      -I/opt/snitch_cluster/sw/snRuntime/api -I/opt/snitch_cluster/sw/snRuntime/src -I/opt/snitch_cluster/sw/snRuntime/src/omp/ \
					      -I/opt/snitch_cluster/sw/snRuntime/api/omp/ -I/opt/snitch_cluster/sw/math/arch/riscv64/bits/ \
					      -I/opt/snitch_cluster/sw/math/arch/generic -I/opt/snitch_cluster/sw/math/src/include -I/opt/snitch_cluster/sw/math/src/internal \
					      -I/opt/snitch_cluster/sw/math/include/bits -I/opt/snitch_cluster/sw/math/include \
					      -c -o $MAINO $MAINS
# Compile mlir to object
/opt/snitch-llvm/bin/clang++ -menable-experimental-extensions -mcpu=snitch -mabi=ilp32d -mcmodel=medany -ftls-model=local-exec \
					      -ffast-math -fno-builtin-printf -fno-common -O3 -D__DEFINED_uint64_t \
					      -I/opt/snitch_cluster/target/snitch_cluster/sw/runtime/rtl/src -I/opt/snitch_cluster/target/snitch_cluster/sw/runtime/common \
					      -I/opt/snitch_cluster/sw/snRuntime/api -I/opt/snitch_cluster/sw/snRuntime/src -I/opt/snitch_cluster/sw/snRuntime/src/omp/ \
					      -I/opt/snitch_cluster/sw/snRuntime/api/omp/ -I/opt/snitch_cluster/sw/math/arch/riscv64/bits/ \
					      -I/opt/snitch_cluster/sw/math/arch/generic -I/opt/snitch_cluster/sw/math/src/include -I/opt/snitch_cluster/sw/math/src/internal \
					      -I/opt/snitch_cluster/sw/math/include/bits -I/opt/snitch_cluster/sw/math/include \
					      -c -o $KERNELO $KERNELS
# Link everything
/opt/snitch-llvm/bin/clang++ -fuse-ld=/opt/snitch-llvm/bin/ld.lld -nostartfiles -nostdlib -L/opt/snitch-llvm/lib/clang/15.0.0/lib/ \
				     -L/opt/snitch_cluster/target/snitch_cluster/sw/runtime/ -L/opt/snitch_cluster/target/snitch_cluster/sw/runtime/rtl \
				     -L/opt/snitch_cluster/target/snitch_cluster/sw/runtime/rtl/build -T/opt/snitch_cluster/sw/snRuntime/base.ld \
				     -lc -lsnRuntime -lclang_rt.builtins-riscv32 \
				     -o $COMPILED $MAINO $KERNELO

# Run code on simulator
/opt/snitch-rtl/bin/snitch_cluster.vlt $COMPILED
