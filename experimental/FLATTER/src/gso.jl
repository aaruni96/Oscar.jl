
function proj(v::Vector{ArbFieldElem}, u::Vector{ArbFieldElem})::Vector{ArbFieldElem}
    retval = dot(v,u) / dot(u,u) .* u
    return retval
end

@doc raw"""
    gso_with_prec(v::Matrix{<:Number}, n::Int)::ArbMatrix

Function returns the result of Gram Schmidt Orthogonalization of `v`, in `n` precision.

# Example
```jlcon
julia> m = [[1 0 331 303]
       [0 1 456 225]
       [0 0 628 0]
       [0 0 0 628]]
4×4 Matrix{Int64}:
 1  0  331  303
 0  1  456  225
 0  0  628    0
 0  0    0  628

julia> u = Oscar.gso_with_prec(v, 64);

julia> u * transpose(matrix(RR, m));

julia> Float64.(ans)
[    201371.0       219111.0       207868.0   190284.0]
[ 1.82424e-14        20148.2        60187.6   -65747.3]
[-2.20325e-14   -4.51653e-14        13.8453   -19.7221]
[ 5.17197e-14     1.8822e-15   -1.57434e-13    2.76887]
```
"""
function gso_with_prec(v::Matrix{<:Number}, n::Int)::ArbMatrix
  RR = ArbField(n)
  return gso_with_prec(matrix(RR,v), RR)
end

function gso_with_prec(v::ArbMatrix, RR::ArbField)::ArbMatrix
    u = Any[]
    for r in axes(v, 1)
        s = zeros(length(v[r,:]))
        for j in 1:r-1
            s = s + proj(v[r,:], u[j])
        end
        push!(u, v[r,:]-s)
    end
    return matrix(RR, mapreduce(permutedims, vcat, u))
end

function proj(v::Vector{QQFieldElem}, u::Vector{QQFieldElem})::Vector{QQFieldElem}
    retval = dot(v,u) / dot(u,u) * u
    return retval
end

function gram_schmidt_orthogonalization(v::QQMatrix)::Any
    u = Any[]
    for r in axes(v, 1)
        s = zeros(length(v[r,:]))
        for j in 1:r-1
            s = s + proj(v[r,:], u[j])
        end
        push!(u, v[r,:]-s)
    end
    return matrix(QQ,mapreduce(permutedims, vcat, u))
end
