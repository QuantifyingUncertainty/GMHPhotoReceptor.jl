import Base.Test: @test,@test_approx_eq,@test_approx_eq_eps,@test_throws

@everywhere import GeneralizedMetropolisHastings:
    ParameterUnivariate,ParameterDefault,
    data,datavalues,dataindex,numvalues,
    trait,traitvalue,traittype,policy,
    parameters,model,evaluate!,loglikelihood

@everywhere import GMHPhotoReceptor:
    PhotoReceptorModel,
    photonsequence,
    photoreceptor,numvilli,numtimesteps,numphotons,
    bump!,bump,macrocurrent!,macrocurrent,filterphotons!,filterphotons,
    lightinducedcurrent!,lightinducedcurrent,fixedbumpshape

import GMHPhotoReceptorAnalysis:
    StreamingStats,update!,streamingstats



