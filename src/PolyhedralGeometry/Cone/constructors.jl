###############################################################################
###############################################################################
### Definition and constructors
###############################################################################
###############################################################################

#TODO: have cone accept exterior description and reserve positive  hull for
#interior description?

struct Cone{T} #a real polymake polyhedron
    pm_cone::Polymake.BigObject
    
    # only allowing scalar_types;
    # can be improved by testing if the template type of the `BigObject` corresponds to `T`
    Cone{T}(c::Polymake.BigObject) where T<:scalar_types = new{T}(c)
end

# default scalar type: `QQFieldElem`
Cone(x...; kwargs...) = Cone{QQFieldElem}(x...; kwargs...)

# Automatic detection of corresponding OSCAR scalar type;
# Avoid, if possible, to increase type stability
Cone(p::Polymake.BigObject) = Cone{detect_scalar_type(Cone, p)}(p)

@doc raw"""
    positive_hull([::Type{T} = QQFieldElem,] R::AbstractCollection[RayVector] [, L::AbstractCollection[RayVector]]; non_redundant::Bool = false) where T<:scalar_types

A polyhedral cone, not necessarily pointed, defined by the positive hull of the
rays `R`, with lineality given by `L`.

`R` is given row-wise as representative vectors, with lineality generated by the
rows of `L`, i.e. the cone consists of all positive linear combinations of the
rows of `R` plus all linear combinations of the rows of `L`.

This is an interior description, analogous to the $V$-representation of a
polytope.

Redundant rays are allowed.

# Examples
To construct the positive orthant as a `Cone`, you can write:
```jldoctest
julia> R = [1 0; 0 1];

julia> PO = positive_hull(R)
Polyhedral cone in ambient dimension 2
```

To obtain the upper half-space of the plane:
```jldoctest
julia> R = [0 1];

julia> L = [1 0];

julia> HS = positive_hull(R, L)
Polyhedral cone in ambient dimension 2
```
"""
function positive_hull(::Type{T}, R::AbstractCollection[RayVector], L::Union{AbstractCollection[RayVector], Nothing} = nothing; non_redundant::Bool = false) where T<:scalar_types
    inputrays = remove_zero_rows(unhomogenized_matrix(R))
    if isnothing(L) || isempty(L)
        L = Polymake.Matrix{scalar_type_to_polymake[T]}(undef, 0, _ambient_dim(R))
    end

    if non_redundant
        return Cone{T}(Polymake.polytope.Cone{scalar_type_to_polymake[T]}(RAYS = inputrays, LINEALITY_SPACE = L,))
    else
        return Cone{T}(Polymake.polytope.Cone{scalar_type_to_polymake[T]}(INPUT_RAYS = inputrays, INPUT_LINEALITY = L,))
    end
end
# Redirect everything to the above constructor, use QQFieldElem as default for the
# scalar type T.
positive_hull(R::AbstractCollection[RayVector], L::Union{AbstractCollection[RayVector], Nothing} = nothing; non_redundant::Bool = false) = positive_hull(QQFieldElem, R, L; non_redundant=non_redundant)
Cone(R::AbstractCollection[RayVector], L::Union{AbstractCollection[RayVector], Nothing} = nothing; non_redundant::Bool = false) = positive_hull(QQFieldElem, R, L; non_redundant=non_redundant)
Cone{T}(R::AbstractCollection[RayVector], L::Union{AbstractCollection[RayVector], Nothing} = nothing; non_redundant::Bool = false) where T<:scalar_types = positive_hull(T, R, L; non_redundant=non_redundant)
Cone(::Type{T}, x...) where T<:scalar_types = positive_hull(T, x...)


function ==(C0::Cone{T}, C1::Cone{T}) where T<:scalar_types
    # TODO: Remove the following 3 lines, see #758
    for pair in Iterators.product([C0, C1], ["RAYS", "FACETS"])
        Polymake.give(pm_object(pair[1]),pair[2])
    end
    return Polymake.polytope.equal_polyhedra(pm_object(C0), pm_object(C1))
end


@doc raw"""
    cone_from_inequalities([::Type{T} = QQFieldElem,] I::AbstractCollection[LinearHalfspace] [, E::AbstractCollection[LinearHyperplane]]; non_redundant::Bool = false)

The (convex) cone defined by

$$\{ x |  Ix ≤ 0, Ex = 0 \}.$$

Use `non_redundant = true` if the given description contains no redundant rows to
avoid unnecessary redundancy checks.

# Examples
```jldoctest
julia> C = cone_from_inequalities([0 -1; -1 1])
Polyhedral cone in ambient dimension 2

julia> rays(C)
2-element SubObjectIterator{RayVector{QQFieldElem}}:
 [1, 0]
 [1, 1]
```
"""
function cone_from_inequalities(::Type{T}, I::AbstractCollection[LinearHalfspace], E::Union{Nothing, AbstractCollection[LinearHyperplane]} = nothing; non_redundant::Bool = false) where T<:scalar_types
    IM = -linear_matrix_for_polymake(I)
    EM = isnothing(E) || isempty(E) ? Polymake.Matrix{scalar_type_to_polymake[T]}(undef, 0, size(IM, 2)) : linear_matrix_for_polymake(E)

    if non_redundant
        return Cone{T}(Polymake.polytope.Cone{scalar_type_to_polymake[T]}(FACETS = IM, LINEAR_SPAN = EM))
    else
        return Cone{T}(Polymake.polytope.Cone{scalar_type_to_polymake[T]}(INEQUALITIES = IM, EQUATIONS = EM))
    end
end

@doc raw"""
    cone_from_equations([::Type{T} = QQFieldElem,] E::AbstractCollection[LinearHyperplane]; non_redundant::Bool = false)

The (convex) cone defined by
```math
\{ x | Ex = 0 \}.
```
Use `non_redundant = true` if the given description contains no redundant rows to
avoid unnecessary redundancy checks.

# Examples
```jldoctest
julia> C = cone_from_equations([1 0 0; 0 -1 1])
Polyhedral cone in ambient dimension 3

julia> lineality_space(C)
1-element SubObjectIterator{RayVector{QQFieldElem}}:
 [0, 1, 1]

julia> dim(C)
1
```
"""
function cone_from_equations(s::Type{T}, E::AbstractCollection[LinearHyperplane]; non_redundant::Bool = false) where T<:scalar_types
    EM = linear_matrix_for_polymake(E)
    IM = Polymake.Matrix{scalar_type_to_polymake[T]}(undef, 0, size(EM, 2))
    return cone_from_inequalities(s, IM, EM; non_redundant = non_redundant)
end

cone_from_inequalities(x...) = cone_from_inequalities(QQFieldElem, x...)

cone_from_equations(E::AbstractCollection[LinearHyperplane]; non_redundant::Bool = false) = cone_from_equations(QQFieldElem, E; non_redundant = non_redundant)

"""
    pm_object(C::Cone)

Get the underlying polymake `Cone`.
"""
pm_object(C::Cone) = C.pm_cone


###############################################################################
###############################################################################
### Display
###############################################################################
###############################################################################

function Base.show(io::IO, C::Cone{T}) where T<:scalar_types
    print(io, "Polyhedral cone in ambient dimension $(ambient_dim(C))")
    T != QQFieldElem && print(io, " with $T type coefficients")
end

Polymake.visual(C::Cone; opts...) = Polymake.visual(pm_object(C); opts...)