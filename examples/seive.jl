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
    return filter(e -> e != 0, candidate_list)::Vector{Int}
end

export sieve

end # module
