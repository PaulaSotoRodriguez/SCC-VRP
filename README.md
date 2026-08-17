# Extensions of the Shared Customer Collaboration Vehicle Routing Problem (SCC-VRP)

This repository contains the code and data used in the computational study of [2]. It includes: 

1. The Mixed-Integer Linear Programming (MILP) model implemented in AMPL.
2. An instance generator script in AMPL.
3. An R script to generate the subproblems needed to construct cooperative games.
4. Benchmark instances and illustrative data examples.

## The Problem

The problem addressed here is an extension of the **Shared Customer Collaboration
Vehicle Routing Problem (SCC-VRP)** introduced by [1], where multiple carriers collaborate to serve a 
shared set of customers by transferring customer demands to one another.

While the original problem assumes all depots store the same products (homogeneous depots), 
our model extends the formulation to address more realistic logistics settings:

Specifically, our extension accounts for:

* **heterogeneous depots**: we assume that each depot stores a different product.Therefore, when a carrier serves demand on behalf of another, the goods must be transferred between carriers first.
* **transfer points**: product transfers between carriers can occur either at a shared customer location or directly at the receiving carrier's depot.
* **travel times and time-based objective functions**: we model the synchronization of transfers through time constraints, and 
consider asymmetric travel times to reflect real-world traffic and road networks. We also consider time-based objective functions.

## Contents

* [1. Optimization model](model_extension_SCC_VRP.mod): mixed-integer linear programming formulation of the
extended SCC-VRP.
* [2. Instance generator](instances/simulation_instances_time.run): AMPL script used to generate synthetic benchmark instances. 
Allows users to customize the number of customers, carriers, vehicle capacities, customer exclusivity rates, and time/distance matrices.
* [3. Coalition generator](dat_files_coalitions.R): R script that generates the individual .dat files for every possible carrier coalition. 
These subproblem files are used to compute the characteristic function values of the associated cooperative game.
* [4. Instances](instances): contains the .dat benchmark instances generated for the simulation study in [2].
* [5. Data examples](Data_examples): small-scale example .dat files discussed in the manuscript [2].

## References

[1] Fernández, E., Roca-Riu, M., & Speranza, M. G. (2018). The Shared Customer
  Collaboration Vehicle Routing Problem. *European Journal of Operational Research*,
  265(3), 1078–1093. https://doi.org/10.1016/j.ejor.2017.08.051
  
[2] Soto-Rodríguez, P., Casas-Méndez, B., Fiestras-Janeiro, M.G, & Saavedra-Nieves, A. (2026) 
Cooperative savings allocation in shared-customer last-mile delivery. *Manuscript under preparation*.
