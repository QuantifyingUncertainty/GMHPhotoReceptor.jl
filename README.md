# Photo receptor model of a fly's eye. 

For use with Generalized Metropolis-Hastings algorithm [(Calderhead, 2014)](#refs). 

The core code for the GMH algorithms resides in [GeneralizedMetropolisHastings.jl](https://github.com/QuantifyingUncertainty/GeneralizedMetropolisHastings.jl).

To setup and run these experiments in Amazon Web Services, JuliaBox or on your local machine, see: http://quantifyinguncertainty.github.io

The repository contains the following folders:

- **models**: model-specific code in Julia
- **data**: files containing measurment data
- **notebooks**: documented examples for MCMC experiments, to be used in an IJulia notebook server
- **scripts**: documented examples for MCMC experiments that can be run from a Julia command-line (REPL) session
- **evoqus**: scripts to run on Evoqus
	
###<a name="refs"/>References
Calderhead B. (2014), A general construction for parallelizing Metropolis-Hastings algorithms, PNAS, Vol: 111, Pages: 17408-17413
