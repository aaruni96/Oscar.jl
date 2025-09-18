module Primes
# internal helper function for filtering
function divides_and_not_equals(i, e)
    # if e, the list iterator divides i, the current list element
    if (e % i) == 0
        # if i is not equal to e
        if i != e
            return true
        end
    end
    return false
end

@doc raw"""
    primes(n::int)

Returns all prime numbers until the input n.
"""
function sieve(n::Int)::Vector{Int}
    @assert n > 1
    candidate_list = collect(2:n)
    upper_limit = Int(floor(sqrt(length(candidate_list))))

    for i in 2:upper_limit
        filter!(e -> !divides_and_not_equals(i, e), candidate_list)
    end

    return candidate_list

end

export primes

end # module
