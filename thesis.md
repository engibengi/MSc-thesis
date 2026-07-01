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

Describe MLIR, how it works, it's base concepts, why was it introduced, dialects, and so on.

#### Motivations

Proliferation of custom IRs across compilers that require duplicated engineering effort and reinvent infrastructure rather than sharing it, and LLVM IR too low level for representing high level domains.

#### What it is

A framework for building IRs, multi-level, extensible, with domain semantics (comparison with LLVM IR too).

#### Core concepts

Operations, SSA values, attributes, generic vs specific pretty print operation, 

#### Dialect system

What is dialect, why many instead of one specific op set, interfaces (how shared behavior rather than with ereditary), a few dialects to describe and show

#### Progressive lowering

high level dialect -> lowering passes/dialect conversions -> low level dialect (often LLVM?) -> LLVM IR -> Machine code
Then speak about passes, what are they, pass manager, etc.

#### Use cases and adoption

ML compiler stacks, HW compiler backend, our case.

#### Optional summary

3-4 line at most

### xDSL

Samesies

## Design of an xDSL compiler toolchain

High level description of what I want to obtain, what various passes did, and what I did.
Avoid implementation details as much as possible.

## Experimental results



## Conclusions


