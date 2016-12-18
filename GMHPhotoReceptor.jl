module GMHPhotoReceptor

import Compat: view
import Distributions
import JLD
import GeneralizedMetropolisHastings

import Base:
    show

import GeneralizedMetropolisHastings:
    AbstractModel,
    trait,traitvalue,traittype,_trait,_traitname,_policy,
    noise,numvalues,datavalues,dataindex,
    parameters,_parameters,_model,evaluate!,
    noisemodel,measurements

export
    photonsequence,lightinducedcurrent

include("models/util.jl")
include("models/datafunctions.jl")
include("models/PhotoReceptor.jl")
include("models/PhotoReceptorPolicy.jl")
include("models/PhotoReceptorModel.jl")
include("models/lightinducedcurrent.jl")

end
