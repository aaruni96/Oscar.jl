
@doc raw"""
    norm(b::Vector{ArbFieldElem}) -> ArbFieldElem

Function returns the 2norm of a vector, for gso profile reasons
"""
function norm(b::Vector{ArbFieldElem})
    return sqrt(sum(b.*b))::ArbFieldElem
end

@doc raw"""
    profile(gso::ArbMatrix) -> Vector{ArbFieldElem}

Function gives profile of a given prec GSO matrix (row major)
"""
function profile(gso::ArbMatrix)
    l = ArbFieldElem[]
    for i in 1:nrows(gso)
        push!(l, norm(gso[i,:]))
    end
    return log.(2, BigFloat.(l))::Vector{BigFloat}
end
