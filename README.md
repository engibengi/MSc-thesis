# Compile C/C++ + mlir for Risc-v Snitch

In order to compile code for the Risc-V Snitch platform, first of all you need Python 3.11

Once you have python 3.11, you need to deepclone this repo.

Then, you'll be able to compile and run the executables by using the following command:

```
./start-and-run.sh ./riscv-docker main-f32.c data-f32.h kernelprod-f32.mlir main-f32.elf
```

The command above can be run directly, but you can also write your own code and run it.

The data\*.h file is not mandatory and can be omitted (if your code does not need to load data of course).
