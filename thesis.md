# Thesis

## Scaletta
1. Introduction -> è il primo capitolo ma si scrive alla fine perché deve dare l'idea del flusso che hai seguito
2. Background -> qua metti sezioni per capire il contesto. Adesso mi vengono in mente tre argomenti principali: il target hardware (Snitch), il contesto di MLIR (come funziona, quali sono i concetti base, perché è stato introdotto, esempi di uso dei dialetti), xDSL
3. Design of an xDSL compiler toolchain -> spieghi ad alto livello cosa vuoi ottenere, cosa fanno i vari passi della toolchain da cui sei partito e cosa hai fatto tu. Cerca di evitare il più possibile dettagli implementativi di basso livello
4. Experimental results -> descrivi cosa si ottiene con gli esperimenti
5. Conclusion -> Riepiloghi in breve tutto quello di cui si è parlato e poi un po' di riflessioni e sviluppi futuri (poi ne parliamo)

## Introduciton

TODO

## Background

### Snitch

Describe the Snitch architecture

### MLIR

MLIR is best introduced by its name, which is an acronym standing for Multi-Level Intermediate Representation.  
Multi-Level refers to the levels of abstraction at which an IR can be represented, ranging from higher levels, suited for representing tensors and complex operations, to lower levels dealing with more basic operations, such as memory management, arithmetic, and control flow.  
In turn, an Intermediate Representation is any data structure that allows for efficient and complete description of source code in a manageable form for compiler frameworks and infrastructures. 

Indeed, MLIR is not simply an IR, but rather a framework that supports the creation of such IRs, designed to facilitate the development of domain-specific compilers and compilers for heterogeneous platforms.


#### Motivations

Prior to the introduction of MLIR, a common problem with compilers and ML-frameworks was the necessity of developing IRs independently, due to the unsuitability of existing ones. TensorFlow had its graph IR, XLA had HLO, ONNX is essentially an IR of its own, and PyTorch has several. While many contributions to the IR landscape can bring progress and innovation, much of the effort behind these IRs is substantially repeated work: parsers, printers, pass managers, verifiers, testing tools, and most documentation are mainly reimplementations of the same thing.

Older IRs, even extremely successful ones such as LLVM's own IR, lack the infrastructure to fit these higher-level domains. This stems from IRs being developed specifically for simple instructions to be executed on CPUs, hence low-level and close to hardware. Lowering a program to this level discards higher-level structure — structure that has become increasingly valuable, as it can now be leveraged by hardware innovations such as Stream Registers, SIMD instructions, and Zero-Overhead Loop Buffers.

MLIR was first developed at Google, motivated by work on XLA and TensorFlow's compiler infrastructure, to address this issue by providing a *reusable, extensible infrastructure* for building IRs, rather than a single, domain-specific IR. It was later adopted by LLVM as one of its subprojects, and is now widely used in the ML sector and beyond.
CITATION: "MLIR: A Compiler Infrastructure for the End of Moore's Law" (CGO 2021)

#### What it is

Whereas the LLVM IR is a single, fixed IR, as stated previously, MLIR is better described as a **framework for defining IRs**, providing common data structures, infrastructures, and tools - such as parsers, printers, pass management, verification, rewriting.
Most importantly, it also provides a mechanism, called dialects, for plugging in new operations, types, and attributes without modifying its core. 

Dialects are the mechanism that enables multiple levels of abstraction in MLIR, even within the same translation unit (the source code unit being lowered by the compiler). 
A high-level dialect describing tensor operations can sit alongside lower-level arithmetic operations, as MLIR manages progressive lowering, a sequence of smaller, verifiable steps that transform code from a high-level representation down toward hardware.

#### Core concepts

Another important distinction between LLVM and MLIR is their foundational building blocks: LLVM has separate classes for instructions, functions and modules. By contrast, in MLIR everything is an operation ("op"), starting from instructions and functions, all the way to loops and modules.  

This is the principle that keeps the core infrastructure unchanged as new domains are added: the uniformity means that tools such as parsers and printers only need to interface with a single type of object.
Despite its advantages, having everything defined as an operation may initially seem like a limitation. However, dialect-specific transformations — implemented as lowering passes and rewrite patterns — handle this complexity, so the apparent limitations do not emerge in practice.

##### Operations

Operations are defined by a name (generally in the form `dialect.opname`, e.g. `arith.addi`), a list of operands, a list of results, attributes (metadata consumed at compile time), and, optionally, one or more regions containing further code.

##### Types

Beyond operations, MLIR's type system is another core concept worth examining. MLIR has several built-in types (integers, floats, functions, tensors, memrefs), and dialects can define their own. In MLIR, types are first-class citizens used to define the properties of SSA values, such as their representation and constraints.


##### Regions and Blocks

Lastly, Regions and Blocks are another distinctive feature that sets MLIR apart from LLVM IR. An operation can contain one or more regions, each containing one or more basic blocks, which are made up of a list of operations (that can recursively contain regions). This means that MLIR is able to represent structured control flow directly with nested regions, rather than having separate blocks connected by branches as happens in LLVM IR. This is one of the key features that enables loop nests, functions, and modules to be represented under the same "operation" abstraction.

```mlir
%sum = scf.for %iv = %lb to %ub step %step
      iter_args(%sum_iter = %sum_0) -> (f32) {
    %t = load %buffer[%iv] : memref<1024xf32>
    %sum_next = arith.addf %sum_iter, %t : f32
    // Yield current iteration sum to next iteration %sum_iter or to %sum
    // if final iteration.
    scf.yield %sum_next : f32
  }
```
CITATION: example taken from [SCF dialect documentation](https://mlir.llvm.org/docs/Dialects/SCFDialect/)

#### Dialect system

Before proceeding further, it is worthwhile to formalize the definition of **dialects**, which has thus far been treated only implicitly.

A **dialect** is a logical grouping of operations, types, and attributes that share a namespace and a common abstraction level or domain (e.g., `arith`, `linalg`, `tensor`). Dialects will also be the main focus for developers, whether they need to expand hardware compatibility, add higher-level instructions, or represent constructs from a new programming language.

#### Progressive lowering


However, dialects alone are insufficient to enable the degree of optimization MLIR aims for. This is where the MLIR compilation workflow becomes relevant.

Typically, an MLIR-based compiler pipeline follows several steps: the first translation from source language or framework graph to high-level dialect(s), a sequence of dialect conversions and optimizations that progressively lower operations to hardware-like instructions (for standard MLIR this is achieved with the LLVM dialect), followed by a translation to LLVM's own IR, which is finally compiled into machine code.

The primary mechanism by which MLIR performs transformations is that sequence of conversions and optimizations, implemented as passes, which can themselves be composed into a pipeline.

Within a pass, transformations are typically carried out through one of two complementary mechanisms: rewrite patterns, applied by a pattern-rewrite driver for local, often dialect-preserving simplifications, or the dialect conversion framework, used for more structural conversions from one dialect to another — which can also be partial, leaving part of the original dialect untouched.

This is what allows for higher-level structures to be preserved and optimized as needed, concretizing the advantages of MLIR's multi-level design. 

#### Use cases and adoption

Although relatively new, the ecosystem around MLIR is already extensive and rapidly growing.
Several established ML frameworks now rely on MLIR-based compiler infrastructure, including TensorFlow and PyTorch (through Torch-MLIR), alongside newer projects such as IREE.
Other applications are emerging beyond the ML domain: CIRCT targets hardware design, Flang is a new Fortran frontend, and Polygeist is a C/C++ frontend built to enable polyhedral optimization.

xDSL, developed in Python, seeks to replicate MLIR's architecture by making dialects easier to develop, while also targeting architectures less commonly considered by mainstream tooling, including RISC-V, the architecture underlying the Snitch platform discussed in this thesis.

#### Summary

Taken together, the concepts discussed in this chapter show how MLIR addresses the problem outlined above: a shared, extensible infrastructure prevents the IR fragmentation described in the motivations, while progressive lowering enables optimizations to occur at whichever abstraction level suits them best.
The following chapter examines xDSL, which builds directly on this foundation.

### xDSL

Samesies

## Design of an xDSL compiler toolchain

High level description of what I want to obtain, what various passes did, and what I did.
Avoid implementation details as much as possible.

## Experimental results



## Conclusions


