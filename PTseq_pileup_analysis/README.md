## Copy right and Contact
PI: pcdedon@mit.edu

Author and contact: yfyuan@mit.edu, msdemott@mit.edu

## Edit log
10/04/2025 revised: add test dataset, version number

## Overview
This foler contains bash and python scripts and bash commands used in the manuscripts entitled "Phosphorothioate DNA modification by BREX type 4 systems in the human gut microbiome" and "PT-seq: A method for metagenomic analysis of phosphorothioate epigenetics in complex microbial communities"

It aims to align reads of an example PT-seq dataset, identify read pileups, and extract sequences including 6 flanking nt at the pileup sites. The package utilizes a simply pipeline from trimming to mapping, sorting and sequencing analysis.

## Hardware requirements
The PTseq pileup analysis pipelien requires only a standard computer with enough RAM to support the in-memory operations.

## OS Requirements
This package is supported for macOS and Linux. The package has been tested on the following systems:

macOS: Mojave (10.14.1)
Linux: Centos 7

## Installation and dependences
bowtie2 v
