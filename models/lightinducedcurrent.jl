#the bump function reaches its maximum for t = shape*scale (obtained by differentiating the function)
@inline _bumpvalmaximum(shape::AbstractFloat,scale::AbstractFloat) = shape*scale

###Calculate a bump value for a single time point
@inline function _bumpval(amplitude::AbstractFloat,shape::AbstractFloat,scale::AbstractFloat,timepoint::AbstractFloat)
    @fastmath amplitude*exp(shape*(1 - log(shape) + log(timepoint/scale)) - timepoint/scale)
end

###Calculate the bump (current) which results from a single photon
@inline function _bump!{T<:AbstractFloat}(bumpvals::Vector{T},timepoints::Vector{T},amplitude::T,shape::T,scale::T)
    @simd for i=1:length(timepoints)
        @inbounds bumpvals[i] = _bumpval(amplitude,shape,scale,timepoints[i])
    end
    bumpvals
end

bump!{T<:AbstractFloat}(bumpvals::Vector{T},timepoints::Vector{T},amplitude::T,shape::T,scale::T) = _bump!(bumpvals,timepoints,amplitude,shape,scale)
bump{T<:AbstractFloat}(timepoints::Vector{T},amplitude::T,shape::T,scale::T) = _bump!(Vector{T}(length(timepoints)),timepoints,amplitude,shape,scale)

###Function that determines how much timepoints to include in the bump calculation, based on the bump parameters
function bump(amplitude::AbstractFloat,shape::AbstractFloat,scale::AbstractFloat,cutoff::AbstractFloat)
    @assert cutoff > 0
    t = trunc(_bumpvalmaximum(shape,scale))*2+1 #starting from twice the maximum time of the bump function
    while _bumpval(amplitude,shape,scale,t) > cutoff
        t+=one(t)
    end
    timepoints = collect(one(t):one(t):t-one(t))
    _bump!(Vector{typeof(t)}(length(timepoints)),timepoints,amplitude,shape,scale)
end

###Calculate the macrocurrent generated by a sequence of photons (internal function)
@inline function _macrocurrent!{T<:AbstractFloat}(current::Vector{T},photons::Vector,bumpvals::Vector{T},nsteps::Int,bumplength::Int)
    for i = 1:nsteps-bumplength
        @inbounds p = photons[i]
        if (p>0)
            @simd for j = 1:bumplength
                @inbounds current[i+j-1] += p*bumpvals[j]
            end
        end
    end
    for i=nsteps-bumplength+1:nsteps
        @inbounds p = photons[i]
        if (p>0)
            @simd for j = 1:nsteps-i+1
                @inbounds current[i+j-1] += p*bumpvals[j]
            end
        end
    end
    current
end

function macrocurrent!{T<:AbstractFloat}(current::Vector{T},photons::Vector,bumpvals::Vector{T})
  @assert length(photons) == length(current)
  _macrocurrent!(current,photons,bumpvals,length(photons),length(bumpvals))
end

macrocurrent{T<:AbstractFloat}(photons::Vector,bumpvals::Vector{T}) = _macrocurrent!(zeros(T,length(photons)),photons,bumpvals,length(photons),length(bumpvals))

@inline function _filterphotons!{T<:AbstractFloat}(filteredphotons::Vector{Int},refractimes::Vector{Int},receptor::AbstractPhotoReceptor,
                                                   latency::Vector{T},refractory::Vector{T},bumplength::Int)
    pcounter = 1
    bl = bumplength - 1
    for t=1:receptor.numsteps
        for microvillus in microvilliwithphotons(receptor,t)
            @inbounds if refractimes[microvillus] < t
                lat = t + trunc(Int,latency[pcounter])
                if lat <= receptor.numsteps
                    @inbounds filteredphotons[lat] += 1
                    @inbounds refractimes[microvillus] = lat + bl + trunc(Int,refractory[pcounter])
                else
                    refractimes[microvillus] = receptor.numsteps
                end
                pcounter+=1
            end
        end
    end
    filteredphotons
end

function filterphotons!{T<:AbstractFloat}(filteredphotons::Vector{Int},receptor::AbstractPhotoReceptor,latency::Vector{T},refractory::Vector{T},bumplength::Int)
    _filterphotons!(filteredphotons,zeros(Int,receptor.numvilli),receptor,latency,refractory,bumplength)

end

function filterphotons{T<:AbstractFloat}(receptor::AbstractPhotoReceptor,latency::Vector{T},refractory::Vector{T},bumplength::Int)
    _filterphotons!(zeros(Int,receptor.numsteps),zeros(Int,receptor.numvilli),receptor,latency,refractory,bumplength)
end

@inline function _lightinducedcurrent!{T<:AbstractFloat}(current::Vector{T},filteredphotons::Vector{Int},refractimes::Vector{Int},receptor::AbstractPhotoReceptor,
                                                         latency::Vector{T},refractory::Vector{T},bumpvals::Vector{T})
    bumplength = length(bumpvals)
    _filterphotons!(filteredphotons,refractimes,receptor,latency,refractory,bumplength)
    _macrocurrent!(current,filteredphotons,bumpvals,receptor.numsteps,bumplength)
end

function lightinducedcurrent!{T<:AbstractFloat}(current::Vector{T},receptor::AbstractPhotoReceptor,latency::Vector{T},refractory::Vector{T},bumpvals::Vector{T})
    _lightinducedcurrent!(current,zeros(Int,receptor.numsteps),zeros(Int,receptor.numvilli),receptor,latency,refractory,bumpvals)
end

function lightinducedcurrent{T<:AbstractFloat}(receptor::AbstractPhotoReceptor,latency::Vector{T},refractory::Vector{T},bumpvals::Vector{T})
    _lightinducedcurrent!(zeros(T,receptor.numsteps),zeros(Int,receptor.numsteps),zeros(Int,receptor.numvilli),receptor,latency,refractory,bumpvals)
end
