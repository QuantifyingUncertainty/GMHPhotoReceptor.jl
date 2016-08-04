#Make sure the package is installed
try
    Pkg.clone("git://github.com/QuantifyingUncertainty/GeneralizedMetropolisHastings.jl")
catch
    warn("Package already installed in previous run")
end

import GeneralizedMetropolisHastings

#Run the script
include("photo/evoqus/PhotoReceptor1.jl")
