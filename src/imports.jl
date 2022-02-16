# standard packages
using Markdown
using Pkg
using Random
using RandomExtensions
using Test

# our packages
import AbstractAlgebra
import GAP
import Hecke
import Nemo
import Polymake
import Singular

# import stuff from Base for which we want to provide extra methods
import Base:
    +,
    *,
    ^,
    ==,
    conj,
    convert,
    eltype,
    exponent,
    getindex,
    intersect,
    inv,
    isfinite,
    issubset,
    iterate,
    length,
    mod,
    one,
    parent,
    print,
    show,
    sum,
    values,
    Vector,
    zero

import AbstractAlgebra:
    @attr,
    @attributes,
    @show_name,
    @show_special,
    addeq!,
    base_ring,
    canonical_unit,
    codomain,
    degree,
    dim,
    domain,
    elem_type,
    evaluate,
    expressify,
    Field,
    FieldElem,
    force_coerce,
    force_op,
    gen,
    Generic,
    Generic.finish,
    Generic.MPolyBuildCtx,
    Generic.MPolyCoeffs,
    Generic.MPolyExponentVectors,
    Generic.push_term!,
    gens,
    get_attribute,
    get_attribute!,
    Ideal,
    map,
    MatElem,
    matrix,
    MatSpace,
    MPolyElem,
    MPolyRing,
    ngens,
    nvars,
    ordering,
    parent_type,
    PolyElem,
    PolynomialRing,
    PolyRing,
    Ring,
    RingElem,
    RingElement,
    set_attribute!,
    SetMap,
    symbols,
    total_degree

import AbstractAlgebra.GroupsCore
import AbstractAlgebra.GroupsCore:
    isfiniteorder,
    istrivial

import GAP:
    @gapattribute,
    @gapwrap,
    GapInt,
    GapObj

import Nemo:
    bell,
    binomial,
    denominator,
    divexact,
    divides,
    divisor_sigma,
    euler_phi,
    factorial,
    fibonacci,
    fits,
    FlintIntegerRing,
    FlintRationalField,
    fmpq,
    fmpq_mat,
    fmpz,
    fmpz_mat,
    fq_nmod,
    FractionField,
    height,
    isprime,
    isprobable_prime,
    isqrtrem,
    issquare,
    isunit,
    iszero,
    jacobi_symbol,
    MatrixSpace,
    moebius_mu,
    number_of_partitions,
    numerator,
    primorial,
    QQ,
    rising_factorial,
    root,
    unit,
    ZZ

exclude = [:Nemo, :AbstractAlgebra, :Rational, :change_uniformizer, :genus_symbol, :data,
    :isdefintie, :narrow_class_group]

for i in names(Hecke)
  i in exclude && continue
  eval(Meta.parse("import Hecke." * string(i)))
  eval(Expr(:export, i))
end

import Hecke:
    _two_adic_normal_forms,
    _block_indices_vals,
    _jordan_2_adic,
    _jordan_odd_adic,
    _min_val,
    _normalize,
    _rational_canonical_form_setup,
    _solve_X_ker,
    _val,
    @req,
    abelian_group,
    automorphism_group,
    center,
    cokernel,
    compose,
    defining_polynomial,
    derived_series,
    det,
    direct_product,
    elements,
    field_extension,
    FinField,
    FinFieldElem,
    FqNmodFiniteField,
    free_abelian_group,
    gens,
    gram_matrix,
    gram_matrix_quadratic,
    haspreimage,
    hensel_qf,
    hom,
    id_hom,
    image,
    index,
    IntegerUnion,
    inv!,
    isabelian,
    isbijective,
    ischaracteristic,
    isconjugate,
    iscyclic,
    isinjective,
    isinvertible,
    isisomorphic,
    isnormal,
    isprimitive,
    isregular,
    issimple,
    issubgroup,
    issurjective,
    kernel,
    Map,
    MapHeader,
    math_html,
    mul,
    mul!,
    multiplicative_jordan_decomposition,
    normal_closure,
    nrows,
    one!,
    order,
    perm,
    preimage,
    primitive_element,
    quo,
    radical,
    refine_for_jordan,
    representative,
    small_group,
    sub,
    subsets,
    subgroups,
    TorQuadMod,
    TorQuadModElem,
    TorQuadModMor,
    tr,
    trace

import cohomCalg_jll
