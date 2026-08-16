# SCC-VRP

This repository contains the optimization model, instance generator and benchmark
instances used in the computational study of the manuscript [2].

The problem addressed here is an extension of the **Shared Customer Collaboration
Vehicle Routing Problem (SCC-VRP)** introduced by [1], in which several carriers 
operating from their own depots collaborate to serve a set of customers, some of 
which have demand for more than one carrier (*shared customers*). 
Our extension additionally accounts for:

* **inter-depot transfers**, i.e. the cost of moving transferred demand
  between the depots of the collaborating carriers, and
* **travel times**, modelled through an asymmetric travel-time matrix.

## Outline

* [1. Optimization model](#1-optimization-model-ampl): contains the mixed-integer linear programming formulation of the
extended SCC-VRP.
* [2. Instance generator](#2-instance-generator-ampl): file that generates the benchmark instances (it is customizable).
* [3. Coalition generator](#3-coalition-generator-r)
* [4. Instances](#4-benchmark-instances)

## References

* Fernández, E., Roca-Riu, M., & Speranza, M. G. (2018). The Shared Customer
  Collaboration Vehicle Routing Problem. *European Journal of Operational Research*,
  265(3), 1078–1093. https://doi.org/10.1016/j.ejor.2017.08.051
  
* *[Your paper, once available: full reference and DOI]*
