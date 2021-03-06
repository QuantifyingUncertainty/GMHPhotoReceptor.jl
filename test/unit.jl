unittests = [
    "photoreceptor",
    "analysis"]

println("===================")
println("Running unit tests:")
println("===================")

for t in unittests
  tfile = t*".jl"
  println("  * $(tfile) *")
  include(string("unit/",tfile))
  println()
  println()
end

