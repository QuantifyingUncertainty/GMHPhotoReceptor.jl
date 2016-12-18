function printanalysis0(paramvals,logposteriors)
    println("Parameter Values: $(round(paramvals,4))")
    println("Mean (STD / %) of LogPosteriors: $(mean(logposteriors)) ($(round(std(logposteriors),2)) / $(abs(round(std(logposteriors)/mean(logposteriors)*100,2)))%)")
end

function printanalysis1(functionname,paramvals,logposteriors)
    println("====================================================")
    println("Results of $functionname for $(length(logposteriors)) iterations")
    println("====================================================")
    printanalysis0(paramvals,logposteriors)
end

function printanalysis2(functionname,paramvals,logposteriors)
    println("====================================================")
    println("Results of $functionname for $(size(logposteriors,1)) iterations and $(size(logposteriors,2)) parameter sets")
    println("====================================================")
    for i=1:size(paramvals,2)
        printanalysis0(paramvals[:,i],logposteriors[:,i])
    end
end

function currentplot(model::GMHPhotoReceptor.PhotoReceptorModel,current::Array)
    PyPlot.plot(dataindex(model),current)
    PyPlot.plot(dataindex(model),vec(mean(current,2));linewidth=1,color="black",label="mean")
    PyPlot.xlim(dataindex(model)[1],dataindex(model)[end])
    PyPlot.legend(loc="upper right",fancybox="true")
    PyPlot.grid("on")
    PyPlot.xlabel("Time (s)")
    PyPlot.ylabel("Current (nA)")
    PyPlot.title("PhotoReceptorModel Light-Induced Current")
end

function meancurrentplot(model::GMHPhotoReceptor.PhotoReceptorModel,meancurrent::Vector)
    PyPlot.plot(dataindex(model),measurements(model);linewidth=2,color="yellow",label="measured")
    PyPlot.plot(dataindex(model),meancurrent;linewidth=1,color="black",label="mean")
    PyPlot.legend(loc="upper right",fancybox="true")
    PyPlot.grid("on")
    PyPlot.xlabel("Time (s)")
    PyPlot.ylabel("Current (nA)")
    PyPlot.title("Measured vs. Mean PhotoReceptorModel Light-Induced Current")
end

function meancurrentsplot(model::GMHPhotoReceptor.PhotoReceptorModel,meancurrents::Array)
    PyPlot.plot(dataindex(model),meancurrents)
    PyPlot.xlim(dataindex(model)[1],dataindex(model)[end])
    PyPlot.grid("on")
    PyPlot.xlabel("Time (s)")
    PyPlot.ylabel("Current (nA)")
    PyPlot.title("Mean PhotoReceptorModel Light-Induced Currents")
end

function stdcurrentplot(model::GMHPhotoReceptor.PhotoReceptorModel,stdcurrent::Array)
    PyPlot.plot(dataindex(model),stdcurrent)
    PyPlot.xlim(dataindex(model)[1],dataindex(model)[end])
    PyPlot.grid("on")
    PyPlot.xlabel("Time (s)")
    PyPlot.ylabel("Current (nA)")
    PyPlot.title("STD of PhotoReceptorModel Light-Induced Current")
end

function logposteriorplot(model::GMHPhotoReceptor.PhotoReceptorModel,logposteriors::Vector)
    nbins = round(Int,sqrt(length(logposteriors)))
    e,c = hist(logposteriors,nbins)
    f = Distributions.fit(Distributions.Normal,logposteriors)
    PyPlot.plt[:hist](logposteriors,nbins)
    PyPlot.grid("on")
    PyPlot.plot(e,Distributions.pdf(f,e)*length(logposteriors)*(maximum(e)-minimum(e))/nbins)
    PyPlot.title("Histogram of Log-Posterior Values")
    f
end

function meanlogposteriorplot(model::GMHPhotoReceptor.PhotoReceptorModel,logposteriors::Array)
    meanlogpost,varlogpost = streamingstats(logposteriors')
    PyPlot.plot(1:size(meanlogpost,2),meanlogpost';linewidth=1)
    PyPlot.grid("on")
    PyPlot.xlabel("Iteration")
    PyPlot.ylabel("Log-Posterior")
    PyPlot.title("Mean of Log-Posterior Distribution")
end

function analysis1(model::GMHPhotoReceptor.PhotoReceptorModel,niterations::Integer;plotmode=:repl)
    #check the value of plotmode by converting it into a trait
    plotmodetrait = GeneralizedMetropolisHastings.trait(:plotmode,plotmode)
    #perform the required analysis
    paramvals,macrocurrents,logposteriors = evaluate1(model,niterations)
    meancurrent = vec(mean(macrocurrents,2))
    stdcurrent = vec(std(macrocurrents,2))
    #print the results
    printanalysis1("analysis1",paramvals,logposteriors)
    #plot in suitable manner for repl or notebook
    if traitvalue(plotmodetrait) == :repl
        PyPlot.figure()
        PyPlot.subplot(221)
    elseif traitvalue(plotmodetrait) == :notebook
        PyPlot.figure()
        PyPlot.subplot(211)
    end
    currentplot(model,macrocurrents)
    if traitvalue(plotmodetrait) == :repl
        PyPlot.subplot(223)
    elseif traitvalue(plotmodetrait) == :notebook
        PyPlot.figure()
        PyPlot.subplot(211)
    end
    meancurrentplot(model,meancurrent)
    if traitvalue(plotmodetrait) == :repl
        PyPlot.subplot(222)
    elseif traitvalue(plotmodetrait) == :notebook
        PyPlot.figure()
        PyPlot.subplot(211)
    end
    stdcurrentplot(model,stdcurrent)
    if traitvalue(plotmodetrait) == :repl
        PyPlot.subplot(224)
    elseif traitvalue(plotmodetrait) == :notebook
        PyPlot.figure()
    end
    f = logposteriorplot(model,logposteriors)
    #return the results
    paramvals,macrocurrents,logposteriors,f
end

function analysis2(model::GMHPhotoReceptor.PhotoReceptorModel,niterations::Integer;plotmode=:repl)
    #check the value of plotmode by converting it into a trait
    plotmodetrait = GeneralizedMetropolisHastings.trait(:plotmode,plotmode)
    #perform the required analysis
    paramvals,macrocurrentstats,logposteriors = evaluate2(model,niterations)
    meancurrent = mean(macrocurrentstats)
    stdcurrent = std(macrocurrentstats)
    #print the results
    printanalysis1("analysis2",paramvals,logposteriors)
    #plot in suitable manner for repl or notebook
    if traitvalue(plotmodetrait) == :repl
        PyPlot.figure()
        PyPlot.subplot(221)
    elseif traitvalue(plotmodetrait) == :notebook
        PyPlot.figure()
        PyPlot.subplot(211)
    end
    meancurrentplot(model,meancurrent)
    if traitvalue(plotmodetrait) == :repl
        PyPlot.subplot(222)
    elseif traitvalue(plotmodetrait) == :notebook
        PyPlot.figure()
        PyPlot.subplot(211)
    end
    stdcurrentplot(model,stdcurrent)
    if traitvalue(plotmodetrait) == :repl
        PyPlot.subplot(223)
    elseif traitvalue(plotmodetrait) == :notebook
        PyPlot.figure()
        PyPlot.subplot(121)
    end
    f = logposteriorplot(model,logposteriors)
    if traitvalue(plotmodetrait) == :repl
        PyPlot.subplot(224)
    elseif traitvalue(plotmodetrait) == :notebook
        PyPlot.subplot(122)
    end
    meanlogposteriorplot(model,logposteriors)
    #return the results
    paramvals,macrocurrentstats,logposteriors,f
end

function analysis3(model::GMHPhotoReceptor.PhotoReceptorModel,niterations::Integer;plotmode=:repl)
    #check the value of plotmode by converting it into a trait
    plotmodetrait = GeneralizedMetropolisHastings.trait(:plotmode,plotmode)
    #perform the required analysis
    nparamsets = 4
    paramvals,meancurrents,stdcurrents,logposteriors = evaluate3(model,niterations,nparamsets)
    #print the results
    printanalysis2("analysis3",paramvals,logposteriors)
    #plot the results
    if traitvalue(plotmodetrait) == :repl
        PyPlot.figure()
        PyPlot.subplot(221)
    elseif traitvalue(plotmodetrait) == :notebook
        PyPlot.figure()
        PyPlot.subplot(211)
    end
    meancurrentsplot(model,meancurrents)
    if traitvalue(plotmodetrait) == :repl
        PyPlot.subplot(222)
    elseif traitvalue(plotmodetrait) == :notebook
        PyPlot.figure()
        PyPlot.subplot(211)
    end
    stdcurrentplot(model,stdcurrents)
    if traitvalue(plotmodetrait) == :repl
        for i=1:4
            PyPlot.subplot(4,4,8+i)
            logposteriorplot(model,logposteriors[:,i])
            PyPlot.subplot(4,4,12+i)
            meanlogposteriorplot(model,logposteriors[:,i])
        end
    elseif traitvalue(plotmodetrait) == :notebook
        for s in Any[[1,2],[3,4]]
            PyPlot.figure()
            for (i,p) in enumerate(s)
                PyPlot.subplot(220+i)
                logposteriorplot(model,logposteriors[:,p])
                PyPlot.subplot(222+i)
                meanlogposteriorplot(model,logposteriors[:,p])
            end
        end
    end

    paramvals,meancurrents,stdcurrents,logposteriors
end

function analysis4(model::GMHPhotoReceptor.PhotoReceptorModel,niterations::Integer,nparamsets::Integer;plotmode=:repl)
    #check the value of plotmode by converting it into a trait
    plotmodetrait = GeneralizedMetropolisHastings.trait(:plotmode,plotmode)
    #perform the required analysis
    paramvals,meancurrents,stdcurrents,logposteriors = evaluate3(model,niterations,nparamsets)
    meanlogposteriors = mean(logposteriors,1)
    stdlogposteriors = std(logposteriors,1)
    #print the results
    printanalysis2("analysis4",paramvals,logposteriors)
    #plot the results
    if traitvalue(plotmodetrait) == :repl
        PyPlot.figure()
        PyPlot.subplot(221)
    elseif traitvalue(plotmodetrait) == :notebook
        PyPlot.figure()
        PyPlot.subplot(211)
    end
    meancurrentsplot(model,meancurrents)
    PyPlot.plot(dataindex(model),measurements(model);linewidth=2,color="yellow",label="measured")
    PyPlot.plot(dataindex(model),mean(meancurrents,2);linewidth=2,color="white",label="mean")
    if traitvalue(plotmodetrait) == :repl
        PyPlot.subplot(222)
    elseif traitvalue(plotmodetrait) == :notebook
        PyPlot.figure()
        PyPlot.subplot(211)
    end
    stdcurrentplot(model,stdcurrents)
    PyPlot.plot(dataindex(model),mean(stdcurrents,2);linewidth=2,color="white",label="mean")
    if traitvalue(plotmodetrait) == :repl
        PyPlot.subplot(223)
    elseif traitvalue(plotmodetrait) == :notebook
        PyPlot.figure(figsize=(10.0,10.0))
    end
    PyPlot.scatter(meanlogposteriors,stdlogposteriors)
    PyPlot.xlabel("Mean Log-Posterior")
    PyPlot.ylabel("STD Log-Posterior")
    if traitvalue(plotmodetrait) == :repl
        PyPlot.subplot(224)
    elseif traitvalue(plotmodetrait) == :notebook
        PyPlot.figure(figsize=(10.0,10.0))
    end
    PyPlot.scatter(meanlogposteriors,100*abs(stdlogposteriors./meanlogposteriors))
    PyPlot.ylim([0.0,5.0])
    PyPlot.xlabel("Mean Log-Posterior")
    PyPlot.ylabel("STD/Mean Log-Posterior")
    paramvals,meancurrents,stdcurrents,logposteriors
end

function analysis5(model::GMHPhotoReceptor.PhotoReceptorModel,niterations::Integer,gradienteps=1e-4;plotmode=:repl)
    #check the value of plotmode by converting it into a trait
    plotmodetrait = GeneralizedMetropolisHastings.trait(:plotmode,plotmode)
    #perform the required analysis
    paramvals,meancurrents,stdcurrents,logposteriors = gradient1(model,niterations,gradienteps)
    #print the results
    printanalysis2("analysis5",paramvals,logposteriors)
    printanalysis2("analysis5",paramvals,logposteriors-mean(logposteriors[:,1]))
    #plot the results
    if traitvalue(plotmodetrait) == :repl
        PyPlot.figure()
        PyPlot.subplot(221)
    elseif traitvalue(plotmodetrait) == :notebook
        PyPlot.figure()
        PyPlot.subplot(211)
    end
    meancurrentsplot(model,meancurrents)
    PyPlot.plot(dataindex(model),measurements(model);linewidth=2,color="yellow",label="measured")
    if traitvalue(plotmodetrait) == :repl
        PyPlot.subplot(222)
    elseif traitvalue(plotmodetrait) == :notebook
        PyPlot.figure()
        PyPlot.subplot(211)
    end
    stdcurrentplot(model,stdcurrents)
    if traitvalue(plotmodetrait) == :repl
        PyPlot.subplot(212)
    elseif traitvalue(plotmodetrait) == :notebook
        PyPlot.figure()
        PyPlot.subplot(211)
    end
    meanlogposteriorplot(model,logposteriors)
    paramvals,meancurrents,stdcurrents,logposteriors
end

