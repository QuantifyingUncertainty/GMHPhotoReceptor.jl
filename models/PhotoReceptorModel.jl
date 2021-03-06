immutable PhotoReceptorModel{P<:GeneralizedMetropolisHastings.AbstractParameter} <: AbstractModel

    #Generic model specs
    name::AbstractString
    parameters::Vector

    photons::GeneralizedMetropolisHastings.DataArray
    measurements::GeneralizedMetropolisHastings.DataArray
    noisemodel::GeneralizedMetropolisHastings.AbstractNoiseModel

    policy::PhotoReceptorPolicy
    receptor::AbstractPhotoReceptor

    ###variable holding the result of a model evaluation
    lightinducedcurrent::Vector{Float32}

    ###temp location to store model data
    fixedbumpvals::Vector{Float32}
    latency::Vector{Float32}
    refractory::Vector{Float32}

    ###Inner constructor
    function PhotoReceptorModel(parameters::Vector{P},photons::GeneralizedMetropolisHastings.DataArray,measurements::GeneralizedMetropolisHastings.DataArray,
                                noisemodel::GeneralizedMetropolisHastings.AbstractNoiseModel,policy::PhotoReceptorPolicy,receptor::AbstractPhotoReceptor,fixedbumpvals)
        @assert (traitvalue(policy.bump) == :fixed && length(fixedbumpvals) > 0) || (traitvalue(policy.bump) == :sample && length(fixedbumpvals) == 0)
        n = "PhotoReceptorModel"
        nsteps = numtimesteps(receptor)
        nvilli = numvilli(receptor)
        nphotons = numphotons(receptor)
        new(n,parameters,photons,measurements,noisemodel,policy,receptor,zeros(Float32,nsteps),fixedbumpvals,zeros(Float32,nphotons),zeros(Float32,nphotons))
    end
end

###Factory functions
_paramprior(::Type{Val{:uniform}},args...) = Distributions.Uniform(args...)
_paramprior(::Type{Val{:normal}},args...) = Distributions.Normal(args...)
_paramprior(::Type{Val{:lognormal}},args...) = Distributions.LogNormal(args...)

function _parameters(::Type{Val{:photoreceptor}},policy::PhotoReceptorPolicy,args...)
    latencykeys = paramkeys(policy.latency)
    refractorykeys = paramkeys(policy.refractory)
    bumpkeys = paramkeys(policy.bump)
    latencypriors = parampriors(policy.latency)
    refractorypriors = parampriors(policy.refractory)
    bumppriors = parampriors(policy.bump)
    numparams = 4 + length(bumpkeys)
    params = Vector{GeneralizedMetropolisHastings.AbstractParameter}(numparams)
    pcounter = 0
    acounter = 0
    for i=1:length(latencykeys)
        params[pcounter+=1] = GeneralizedMetropolisHastings.parameter(latencykeys[i],_paramprior(Val{latencypriors[i]},args[acounter+=1]...))
    end
    if length(latencykeys) == 1
        params[pcounter+=1] = GeneralizedMetropolisHastings.parameter(:unused,0.0f0)
    end
    for i=1:length(refractorykeys)
        params[pcounter+=1] = GeneralizedMetropolisHastings.parameter(refractorykeys[i],_paramprior(Val{refractorypriors[i]},args[acounter+=1]...))
    end
    if length(refractorykeys) == 1
        params[pcounter+=1] = GeneralizedMetropolisHastings.parameter(:unused,0.0f0)
    end
    for i=1:length(bumpkeys)
        params[pcounter+=1] = GeneralizedMetropolisHastings.parameter(bumpkeys[i],_paramprior(Val{bumppriors[i]},args[acounter+=1]...))
    end
    params
end

function _model(::Type{Val{:photoreceptor}},parameters::Vector,photons::GeneralizedMetropolisHastings.DataArray,measurements::GeneralizedMetropolisHastings.DataArray,
                variance::Vector,nvilli::Int,policy::PhotoReceptorPolicy)
    @assert numvalues(photons) == numvalues(measurements)
    @assert (traitvalue(policy.bump) == :fixed && length(parameters) == 4) || (traitvalue(policy.bump) == :sample && length(parameters) == 7)
    n = noise(:gaussian,variance)
    r = photoreceptor(:cell,datavalues(photons),nvilli,nvilli<typemax(UInt16)?UInt16:UInt32)
    b = traitvalue(policy.bump)==:fixed?bump(fixedbumpvalues(policy.fixedbump)...):Float32[]
    PhotoReceptorModel{eltype(parameters)}(parameters,photons,measurements,n,policy,r,b)
end

###evaluate! function

function evaluate!(model::PhotoReceptorModel,vals::AbstractVector,times::Int)
    nvals = numvalues(model.photons)
    result = zeros(Float32,nvals,times)
    for i=1:times
        l = evaluate!(model,vals)
        copy!(result,(i-1)*nvals+1,l,1,nvals)
    end
    result
end

function evaluate!(model::PhotoReceptorModel,vals::AbstractVector)
    _resettemp(model)
    bumpvals = _bumpvals(traittype(model.policy.bump),model,vals)
    _latency!(traittype(model.policy.latency),model,vals)
    _refractory!(traittype(model.policy.refractory),model,vals)
    lightinducedcurrent!(model.lightinducedcurrent,model.receptor,model.latency,model.refractory,bumpvals)
end

###Utility functions used in generic implementations in AbstractModel
@inline dataindex(model::PhotoReceptorModel) = dataindex(model.measurements)
@inline measurements(model::PhotoReceptorModel) = datavalues(model.measurements)
@inline noisemodel(model::PhotoReceptorModel) = model.noisemodel
lightinducedcurrent(model::PhotoReceptorModel) = model.lightinducedcurrent

@inline _setval!{N<:Number}(vals::Vector{N},v::N) = @simd for i=1:length(vals) @inbounds vals[i] = v end

@inline _resettemp(model::PhotoReceptorModel) = _setval!(model.lightinducedcurrent,0.0f0)

@inline _latency!(::Type{Val{:deterministic}},m::PhotoReceptorModel,vals::AbstractVector) = _setval!(m.latency,Float32(vals[1]))
@inline function _latency!(::Type{Val{:lognormal}},m::PhotoReceptorModel,vals::AbstractVector)
    randlognormal!(m.latency,Float32(vals[1]),Float32(vals[2]))
end

@inline _refractory!(::Type{Val{:deterministic}},m::PhotoReceptorModel,vals::AbstractVector) = _setval!(m.refractory,Float32(vals[3]))
@inline function _refractory!(::Type{Val{:lognormal}},m::PhotoReceptorModel,vals::AbstractVector)
    randlognormal!(m.refractory,Float32(vals[3]),Float32(vals[4]))
end

@inline _bumpvals(::Type{Val{:fixed}},m::PhotoReceptorModel,vals::AbstractVector) = m.fixedbumpvals
@inline function _bumpvals(::Type{Val{:sample}},m::PhotoReceptorModel,vals::AbstractVector)
    bump(Float32(vals[5]),Float32(vals[6]),Float32(vals[7]),m.policy.fixedbump.cutoff)
end

###Base functionality
function show(io::IO,m::PhotoReceptorModel)
    println(io,"Model ",m.name)
    print(io,"parameters: ") ; show(io,m.parameters)
    print(io,"photons: ") ; show(io,m.photons)
    print(io,"measurements: ") ; show(io,m.measurements)
    print(io,"noisemodel: ") ; show(io,m.noisemodel)
    print(io,"policy: ") ; show(io,m.policy)
    print(io,"receptor: ") ; show(io,m.receptor)
    println(io)
    nothing
end



