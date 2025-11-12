module Sieve

# Implementation of the Sieve of Eratosthenes algorithm as described at
# https://en.wikipedia.org/wiki/Sieve_of_Eratosthenes

@doc raw"""
    sieve(n::int) -> Vector{Int}

Returns all prime numbers until the input n.

# Example

```jlcon
julia> Main.Sieve.sieve(20)
8-element Vector{Int64}:
  2
  3
  5
  7
 11
 13
 17
 19
```
"""
function sieve(n::Int)
    @assert n > 1
    candidate_list = collect(2:n)
    upper_limit = Int(floor(sqrt(length(candidate_list))))
    for i in 1:upper_limit
        if candidate_list[i] == 0
            continue
        end
        k = candidate_list[i]
        for j in (i+k):k:(n - 1)
            candidate_list[j] = 0
        end
    end
    return filter!(e -> e != 0, candidate_list)::Vector{Int}
end

export sieve
doc="""
benchmark without filter!
```jlcon
julia> @benchmark Sieve.sieve(500)
BenchmarkTools.Trial: 10000 samples with 77 evaluations per sample.
 Range (min … max):  813.260 ns …  1.560 ms  ┊ GC (min … max):  0.00% … 99.46%
 Time  (median):     929.143 ns              ┊ GC (median):     0.00%
 Time  (mean ± σ):     5.475 μs ± 72.885 μs  ┊ GC (mean ± σ):  80.64% ±  6.04%

  ▄▇██▇▆▅▄▄▃▂▂▁  ▁                                 ▁▂▂▂▁▁      ▂
  █████████████████▇▆▇▆▅▄▅▃▃▃▄▁▃▁▃▁▃▄▁▅▃▁▁▁▁▄▃▁▁▅▇████████▇▆▆▆ █
  813 ns        Histogram: log(frequency) by time      2.75 μs <

 Memory estimate: 8.81 KiB, allocs estimate: 7.
````
"""

anotherdoc = """
bencmark with filter! (inplace)
```jlcon
julia> @benchmark Sieve.sieve(500)
BenchmarkTools.Trial: 10000 samples with 151 evaluations per sample.
 Range (min … max):  505.007 ns … 697.334 μs  ┊ GC (min … max):  0.00% … 99.62%
 Time  (median):     745.904 ns               ┊ GC (median):     0.00%
 Time  (mean ± σ):     2.463 μs ±  29.821 μs  ┊ GC (mean ± σ):  68.33% ±  5.63%

  ▃▁       ▆▇██▇▆▅▄▂▁                         ▁ ▁               ▂
  ██▆▄▁▁▁▁█████████████▇▅▅▁▃▃▁▃▄▆▁▄▁▁▁▁▃▃▁▃▄▃██████▇▆▁▆▅▄▆▆▇▇▆▆ █
  505 ns        Histogram: log(frequency) by time        1.7 μs <

 Memory estimate: 4.80 KiB, allocs estimate: 4.
```
"""

almost_perfect = """
```jlcon
julia> @benchmark sieve(1_000_000)
BenchmarkTools.Trial: 2954 samples with 1 evaluation per sample.
 Range (min … max):  1.634 ms …   4.452 ms  ┊ GC (min … max): 0.00% … 28.95%
 Time  (median):     1.644 ms               ┊ GC (median):    0.00%
 Time  (mean ± σ):   1.692 ms ± 179.034 μs  ┊ GC (mean ± σ):  1.76% ±  5.91%

  █▅▂▁        ▁▁                                               
  ████▇▆▅▅▅▅▆████▆▃▁▅▁▃▃▁▃▁▁▁▁▁▁▃▁▁▁▁▁▁▁▁▁▃▁▁▁▃▃▄▅▆█▇▇▆▅▅▃▅▅▆ █
  1.63 ms      Histogram: log(frequency) by time      2.41 ms <

 Memory estimate: 735.61 KiB, allocs estimate: 7.
```
"""

end # module
