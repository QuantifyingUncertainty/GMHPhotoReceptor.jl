println("========================")
println("Preparing Run for Evoqus")
println("========================")
#Make sure the package is installed
try
    Pkg.clone("https://github.com/QuantifyingUncertainty/GeneralizedMetropolisHastings.jl")
catch
    warn("Package already installed in previous run")
end

include("/workspace/GMHPhotoReceptor.jl")

import GeneralizedMetropolisHastings
import GMHPhotoReceptor

@everywhere include("/workspace/GMHPhotoReceptor.jl")

