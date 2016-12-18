s1 = StreamingStats(Float64)
s2 = StreamingStats(10,Float64)

ntestelements = 1000
x1 = randn(ntestelements)
x2 = randn(10,ntestelements)
m1,v1 = streamingstats(x1)
m2,v2 = streamingstats(x2)

for i=1:ntestelements
    update!(s1,x1[i])
    update!(s2,x2[:,i])
    #test the results of the update function against ground truth
    @test_approx_eq_eps mean(s1) mean(x1[1:i]) 1e-10
    @test_approx_eq_eps var(s1) var(x1[1:i]) 1e-10
    @test_approx_eq_eps std(s1) std(x1[1:i]) 1e-10
    @test_approx_eq_eps mean(s2) mean(x2[:,1:i],2) 1e-10
    @test_approx_eq_eps var(s2) var(x2[:,1:i],2) 1e-10
    @test_approx_eq_eps std(s2) std(x2[:,1:i],2) 1e-10
    #test the results of the streamstats function
    @test_approx_eq_eps m1[i] mean(s1) 1e-10
    @test_approx_eq_eps v1[i] var(s1) 1e-10
    @test_approx_eq_eps m2[:,i] mean(s2) 1e-10
    @test_approx_eq_eps v2[:,i] var(s2) 1e-10
end


println("==================")
println("Test show function")
println("==================")
show(s1)
show(s2)
println("=============")
println("End test show")
println("=============")
