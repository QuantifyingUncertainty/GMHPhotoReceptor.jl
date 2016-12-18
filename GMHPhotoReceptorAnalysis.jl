module GMHPhotoReceptorAnalysis

import GeneralizedMetropolisHastings
import GMHPhotoReceptor
import Distributions
import PyPlot

import Base: show,mean,std,var

using GeneralizedMetropolisHastings
using GMHPhotoReceptor

include("analysis/StreamingStats.jl")
include("analysis/evaluate.jl")
include("analysis/analysis.jl")

end
