type StreamingStats{T<:Union{Number,Vector}}
    iteration::Int
    runningmean::T
    runningvar::T
    tempdiff::T
end

StreamingStats{T<:AbstractFloat}(::Type{T}) = StreamingStats(0,zero(T),zero(T),zero(T))
StreamingStats{T<:AbstractFloat}(s::Integer,::Type{T}) = StreamingStats(0,zeros(T,s),zeros(T,s),zeros(T,s))

@inline _varupdatefactor(i::Integer,v::Number) = i==1?zero(typeof(v)):convert(typeof(v),(i-2)/(i-1))
@inline _varupdatefactor(i::Integer,v::Vector) = i==1?zero(eltype(v)):convert(eltype(v),(i-2)/(i-1))

@inline _updatetempdiff!(s::StreamingStats,v::Number) = (s.tempdiff = v - s.runningmean ; s)
@inline _updatetempdiff!(s::StreamingStats,v::Vector) = (@simd for i=1:length(v) @inbounds s.tempdiff[i] = v[i] - s.runningmean[i] end ; s)

@inline _updatemean!(s::StreamingStats,v::Number) = (s.runningmean = ((s.iteration-1)*s.runningmean + v)/s.iteration ; s)
@inline _updatemean!{T<:AbstractFloat}(s::StreamingStats,v::Vector{T}) = (@simd for i=1:length(v) @inbounds s.runningmean[i] = ((s.iteration-1)*s.runningmean[i] + v[i])/s.iteration end ; s)

@inline _updatevar!{T<:AbstractFloat}(s::StreamingStats,v::T,f::T) = (s.runningvar = f*s.runningvar + s.tempdiff*s.tempdiff/s.iteration ; s)
@inline _updatevar!{T<:AbstractFloat}(s::StreamingStats,v::Vector{T},f::T) = (@simd for i=1:length(v) @inbounds s.runningvar[i] = f*s.runningvar[i] + s.tempdiff[i]*s.tempdiff[i]/s.iteration end ; s)

function update!(s::StreamingStats,value)
    s.iteration += 1
    _updatetempdiff!(s,value)
    _updatemean!(s,value)
    _updatevar!(s,value,_varupdatefactor(s.iteration,value))
    s
end

function streamingstats(x::Vector)
    s = StreamingStats(eltype(x))
    m = zeros(x)
    v = zeros(x)
    for i=1:length(x)
        update!(s,x[i])
        m[i] = mean(s)
        v[i] = var(s)
    end
    m,v
end

function streamingstats(a::Matrix)
    s = StreamingStats(size(a,1),eltype(a))
    m = zeros(a)
    v = zeros(a)
    for i=1:size(a,2)
        update!(s,a[:,i])
        m[:,i] = mean(s)
        v[:,i] = var(s)
    end
    m,v
end

mean(s::StreamingStats) = s.runningmean
var(s::StreamingStats) = s.runningvar*(s.iteration-1)/(s.iteration-1)
std(s::StreamingStats) = sqrt(var(s))

function show(io::IO,s::StreamingStats)
    println(io,"iterations = ",s.iteration)
    println(io,"mean = ",round(mean(s),2))
    println(io,"var = ",round(var(s),2))
    println(io,"std = ",round(std(s),2))
end

