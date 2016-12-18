using GMHPhotoReceptorAnalysis

###Load and display the photon sequence
photonfilename = joinpath(splitdir(@__FILE__())[1],"../data/naturallight.jld")

photons1 = GMHPhotoReceptor.photonsequence(photonfilename)
current1 = GMHPhotoReceptor.lightinducedcurrent(photonfilename)

println("====================================")
println("Measurement data loaded successfully")
println("====================================")

###Settings for the model
numvilli1 = 30000

#specify the values that determine the priors on the parameters
latencylocation = (2.0,3.5) #uniform distribution with (low,high) values
latencyscale = (0.2,0.7) #uniform distribution with (low,high) values
refractorylocation = (4.0,6.0) #uniform distribution with (low,high) values
refractoryscale = (1.5,2.5) #uniform distribution with (low,high) values
bumpamplitude = (3.0,5.0) #uniform distribution with (low,high) values
bumpshape = (log(3.0),0.3) #lognormal distribution with (location,scale) values
bumpscale = (log(2.5),0.3) #lognormal distribution with (location,scale) values

#4-parameter model with stochastic latency and refractory parameters and fixed bump parameters
mpolicy4 = GeneralizedMetropolisHastings.policy(:photoreceptor;bump=:fixed)
params4 = GeneralizedMetropolisHastings.parameters(:photoreceptor,mpolicy4,
                     latencylocation,latencyscale,refractorylocation,refractoryscale)

#7-parameter model with latency, refractory and bump parameters
mpolicy7 = GeneralizedMetropolisHastings.policy(:photoreceptor;bump=:sample)
params7 = GeneralizedMetropolisHastings.parameters(:photoreceptor,mpolicy7,
                     latencylocation,latencyscale,refractorylocation,refractoryscale,
                     bumpamplitude,bumpshape,bumpscale)

variance1 = [3600.0]

println("=====================================")
println("Model parameters defined successfully")
println("=====================================")

###Create PhotoReceptor models
model4 = GeneralizedMetropolisHastings.model(:photoreceptor,params4,photons1,current1,variance1,numvilli1,mpolicy4)
model7 = GeneralizedMetropolisHastings.model(:photoreceptor,params7,photons1,current1,variance1,numvilli1,mpolicy7)

###Show the model
println("===========================")
println("Models defined successfully")
println("===========================")
show(model4)
show(model7)

###Plot evaluation data
#GMHPhotoReceptorAnalysis.analysis1(model4,100)
#GMHPhotoReceptorAnalysis.analysis2(model4,500)
#GMHPhotoReceptorAnalysis.analysis3(model4,200)
#GMHPhotoReceptorAnalysis.analysis4(model4,50,200)
GMHPhotoReceptorAnalysis.analysis5(model4,100,1e-3)

nothing
