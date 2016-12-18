initvalues(model::GMHPhotoReceptor.PhotoReceptorModel) = GeneralizedMetropolisHastings.initvalues(trait(:initialize,:prior),parameters(model),Float64)

#Iterate evaluate n times and store all currents + all logposteriors
function evaluate1(model::GMHPhotoReceptor.PhotoReceptorModel,niterations::Integer;paramvals=nothing)
    if paramvals == nothing
        paramvals = initvalues(model)
    end
    ntimesteps = GeneralizedMetropolisHastings.numvalues(model.photons)
    macrocurrents = zeros(Float32,ntimesteps,niterations)
    logposteriors = zeros(Float32,niterations)
    lprior = logprior(parameters(model),paramvals,Float32)
    for i=1:niterations
        macrocurrent =  evaluate!(model,paramvals)
        copy!(macrocurrents,(i-1)*ntimesteps+1,macrocurrent,1,ntimesteps)
        logposteriors[i] = loglikelihood(model,macrocurrent) + lprior
    end
    paramvals,macrocurrents,logposteriors
end

#Iterate evaluate n times and store mean and std current + all logposteriors
function evaluate2(model::GMHPhotoReceptor.PhotoReceptorModel,niterations::Integer;paramvals=nothing,macrocurrentstats=nothing)
    ntimesteps = GeneralizedMetropolisHastings.numvalues(model.photons)
    if paramvals == nothing
        paramvals = initvalues(model)
    end
    if macrocurrentstats == nothing
        macrocurrentstats = StreamingStats(ntimesteps,Float32)
    end
    logposteriors= zeros(Float32,niterations)
    lprior = logprior(parameters(model),paramvals,Float32)
    for i=1:niterations
        macrocurrent =  evaluate!(model,paramvals)
        update!(macrocurrentstats,macrocurrent)
        logposteriors[i] = loglikelihood(model,macrocurrent) + lprior
    end
    paramvals,macrocurrentstats,logposteriors
end

#Run evaluate2 for 4 different parameter values and return all mean and std of macrocurrents + logposteriors
function evaluate3(model::GMHPhotoReceptor.PhotoReceptorModel,niterations::Integer,nparamsets::Integer)
    ntimesteps = GeneralizedMetropolisHastings.numvalues(model.photons)
    paramvals = zeros(GeneralizedMetropolisHastings.numparas(model),nparamsets)
    meancurrents = zeros(Float32,ntimesteps,nparamsets)
    stdcurrents = zeros(meancurrents)
    logposteriors = zeros(Float32,niterations,nparamsets)
    r = pmap((n)->evaluate2(model,niterations),1:nparamsets)
    for p=1:nparamsets
        paramvals[:,p] = r[p][1]
        meancurrents[:,p] = mean(r[p][2])
        stdcurrents[:,p] = std(r[p][2])
        logposteriors[:,p] = r[p][3]
    end
    paramvals,meancurrents,stdcurrents,logposteriors
end

function gradient1(model::GMHPhotoReceptor.PhotoReceptorModel,niterations::Integer,gradienteps::Number=1e-4;paramvals=nothing)
    ntimesteps = GeneralizedMetropolisHastings.numvalues(model.photons)
    nparamsets = GeneralizedMetropolisHastings.numparas(model) + 1
    gradparamvals = repmat(initvalues(model),1,nparamsets)
    for i=2:nparamsets
        gradparamvals[i-1,i]+=gradienteps
    end
    meancurrents = zeros(Float32,ntimesteps,nparamsets)
    stdcurrents = zeros(meancurrents)
    logposteriors = zeros(Float32,niterations,nparamsets)
    r = pmap((n)->evaluate2(model,niterations;paramvals=gradparamvals[:,n]),1:nparamsets)
    for p=1:nparamsets
        meancurrents[:,p] = mean(r[p][2])
        stdcurrents[:,p] = std(r[p][2])
        logposteriors[:,p] = r[p][3]
    end
    gradparamvals,meancurrents,stdcurrents,logposteriors
end





