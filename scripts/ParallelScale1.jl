println("===========================================================================")
println("Beginning execution of script GMHPhotoReceptor.jl/scripts/PhotoReceptor1.jl")
println("===========================================================================")

using GeneralizedMetropolisHastings
using GMHPhotoReceptor

###Values of the model
numvilli1 = 30000

#specify the values that determine the priors on the parameters
latencylocation = (2.0,3.5) #uniform distribution with (low,high) values
latencyscale = (0.2,0.7) #uniform distribution with (low,high) values
refractorylocation = (4.0,6.0) #uniform distribution with (low,high) values
refractoryscale = (1.5,2.5) #uniform distribution with (low,high) values
bumpamplitude = (3.0,5.0) #uniform distribution with (low,high) values
bumpshape = (log(3.0),0.3) #lognormal distribution with (location,scale) values; variable can vary roughly between 2.0 and 4.0, but becomes increasingly penalized outside
bumpscale = (log(2.5),0.3) #lognormal distribution with (location,scale) values; variable can vary roughly between 1.5 and 3.5, but becomes increasingly penalized outside

photonfilename = joinpath(splitdir(@__FILE__())[1],"../data/naturallight.jld")
photons1 = photonsequence(photonfilename)
current1 = lightinducedcurrent(photonfilename)

modelpolicy1 = policy(:photoreceptor) #4-parameter model with stochastic lognormal latency and refractory parameters and fixed bump parameters
params1 = parameters(:photoreceptor,modelpolicy1,latencylocation,latencyscale,refractorylocation,refractoryscale)

####Variance for the noise model, estimated from previous runs
variance1 = [3600.0]

println("==========================================")
println("Simulation parameters defined successfully")
println("==========================================")

###Create a PhotoReceptor model
model1 = model(:photoreceptor,params1,photons1,current1,variance1,numvilli1,modelpolicy1)

###Show the model
println("==========================")
println("Model defined successfully")
println("==========================")
show(model1)

###Create a Metropolis sampler with a Normal proposal density
propcov = [0.1,0.01,0.1,0.01]
sampler1 = sampler(:mh,:normal,0.1,propcov)
println("============================")
println("Sampler defined successfully")
println("============================")
show(sampler1)

#MCMC iteration specifications
niterations = 20
npropbase1 = 5000
npropbase2 = 1000
ntunerperiod = npropbase1*niterations

###Create a tuner that just reports the time
tuner1 = tuner(:monitor,ntunerperiod)
println("==========================")
println("Tuner defined successfully")
println("==========================")
show(tuner1)

println("Running a simulation with Standard MH")
runnerpolicy0 = policy(:mh,1;initialize=:prior)
runner0 = runner(runnerpolicy0,npropbase2*niterations)
show(runner0)
@time chain0 = run!(runner0,model1,sampler1,tuner1)
smhruntime = chain0.runtime
smhproposed = chain0.proposed

println("Running a simulation with Generalized MH in 1 process")
runnerpolicy1 = policy(:mh,npropbase2;initialize=:prior)
runner1 = runner(runnerpolicy1,niterations,npropbase2)
@time chain1 = run!(runner1,model1,sampler1,tuner1)
gmhruntime = chain1.runtime
gmhproposed = chain1.proposed

NWORKERS = [1,2,4,8,12,16,24,32]
proposalstrategy = ["total","segment"]
nproposals = [npropbase1*ones(Int,length(NWORKERS)) npropbase2*max(NWORKERS,1)]
parallelruntimes = zeros(length(NWORKERS),2)
parallelproposed = zeros(Int,length(NWORKERS),2)

for (j,s) in enumerate(proposalstrategy)
    println("=======================================")
    println("Testing fixed number of $s proposals")
    println("=======================================")
    for (i,n) in enumerate(NWORKERS)
        try 
            addprocs(n)
        
            @everywhere using GeneralizedMetropolisHastings
            @everywhere using GMHPhotoReceptor
        
            println("Running simulation with $(nworkers()) workers: ")
    
            ###Create a Generalized Metropolis-Hastings runner
            runnerpolicy2 = policy(:mh,nproposals[i,j];initialize=:prior)
            runner2 = runner(runnerpolicy2,niterations,nproposals[i,j])
            @time chain2 = run!(runner2,model1,sampler1,tuner1)
        
            ###Show the result of the simulations
            show(chain2)
        
            parallelruntimes[i,j] = chain2.runtime
            parallelproposed[i,j] = chain2.proposed
            
        catch e
            println(e)
        end
        rmprocs(workers())
    end
end

println("Strategy \t Runtime \t Proposals \t Proposal Rate")
println("=========================================================================")
println("Standard MH \t $smhruntime \t $smhproposed \t $(smhproposed/smhruntime)")
println("GMH No Workers \t $gmhruntime \t $gmhproposed \t $(gmhproposed/gmhruntime)")
for i=1:length(NWORKERS)
    println("TOT $(NWORKERS[i]) Workers \t $(parallelruntimes[i,1]) \t $(parallelproposed[i,1]) \t $(parallelproposed[i,1]/parallelruntimes[i,1])")
end
for i=1:length(NWORKERS)
    println("SEG $(NWORKERS[i]) Workers \t $(parallelruntimes[i,2]) \t $(parallelproposed[i,2]) \t $(parallelproposed[i,2]/parallelruntimes[i,2])")
end
