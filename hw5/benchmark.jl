using Random
using Base.Threads: @threads, nthreads

function one_replicate(seed)
    rng = Xoshiro(seed)
    y = randn(rng, 20_000)
    theta = 0.0
    for _ in 1:2_000
        theta += sum(y .- theta) / length(y)
    end
    return theta
end

function parallel_replicates(seeds)
    result = Vector{Float64}(undef, length(seeds))
    @threads for i in eachindex(seeds)
        result[i] = one_replicate(seeds[i])
    end
    return result
end

function serial_sqrt(integers)
    result = Vector{Float64}(undef, length(integers))
    for i in eachindex(integers)
        @inbounds result[i] = sqrt(integers[i])
    end
    return result
end

function parallel_sqrt(integers)
    result = Vector{Float64}(undef, length(integers))
    @threads for i in eachindex(integers)
        @inbounds result[i] = sqrt(integers[i])
    end
    return result
end

function benchmark(workload, jobs, repeats)
    expected = jobs.serial()
    for job in values(jobs)
        @assert job() ≈ expected
    end
    for run in 1:repeats
        for (method, job) in pairs(jobs)
            GC.gc()
            elapsed = @elapsed result = job()
            @assert result ≈ expected
            println("$workload,Julia,$method,$run,$elapsed")
        end
    end
end

function main(repeats)
    @assert nthreads() > 1 "Launch Julia with at least two threads, e.g. julia -t auto."
    @assert repeats >= 3
    println(stderr, "Julia $VERSION; nthreads() = $(nthreads())")
    println("workload,language,method,run,seconds")
    seeds = 1:16
    integers = 1:1_000_000
    benchmark("replicate", (
        serial = () -> map(one_replicate, seeds),
        parallel = () -> parallel_replicates(seeds),
    ), repeats)
    benchmark("sqrt", (
        serial = () -> serial_sqrt(integers),
        parallel = () -> parallel_sqrt(integers),
        vectorized = () -> sqrt.(integers),
    ), repeats)
end

main(parse(Int, only(ARGS)))
