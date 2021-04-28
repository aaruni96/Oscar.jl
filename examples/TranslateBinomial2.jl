import Oscar.Singular.lib4ti2_jll
using DelimitedFiles

"""
    isbinomial(f::MPolyElem)

Returns true if f is a binomial, i.e. it consists of at most 2 terms,
false otherwise.
"""
function isbinomial(f::MPolyElem)
  return length(f) <= 2
end


"""
    isbinomial(I::MPolyIdeal)

Returns true if I is a binomial ideal, i.e. it can be generated by binomials.
"""
function isbinomial(I::MPolyIdeal)
  if all(isbinomial, gens(I))
    return true
  end
  return all(isbinomial, groebner_basis(I))
end

function iscellular(I::MPolyIdeal)
  if isbinomial(I) 
    return _iscellular(I)
  else
    error("Not yet implemented")
  end
end

function _iscellular(I::MPolyIdeal)
  #input: binomial ideal in a polynomial ring
  #output: the decision true/false whether I is cellular or not
  #if it is cellular, return true and the cellular variables, otherwise return the
  #index of a variable which is a zerodivisor but not nilpotent modulo I
  if iszero(I)
    return false, Int[-1]
  elseif isone(I)
    return false, Int[-1]
  end
  Delta = Int64[]
  Rxy = base_ring(I)
  variables = gens(Rxy)
  helpideal = ideal(Rxy, zero(Rxy))

  for i = 1:ngens(Rxy)
    J = ideal(Rxy, variables[i])
    sat = saturation(I, J)
    if !isone(sat)
      push!(Delta, i)
    end
  end

  #compute product of ring variables in Delta
  prodRingVar = prod(variables[i] for i in Delta; init = one(Rxy))
  prodRingVarIdeal = ideal(Rxy, prodRingVar)
  J = saturation(I, prodRingVarIdeal)

  if issubset(J, I)
    #then I==J
    #in this case I is cellular with respect to Delta
    return true, Delta
  end

  for i in Delta
    J = quotient(I, ideal(Rxy, variables[i]))
    if !issubset(J, I)
      return false, Int[i]
    end
  end
  error("Something went wrong")
end


"""
    cellular_decomposition(I::MPolyIdeal)

Given a binomial ideal I, returns a cellular decomposition of I.
"""
function cellular_decomposition(I::MPolyIdeal)
  #with less redundancies
  #input: binomial ideal I
  #output: a cellular decomposition of I
  @assert !iszero(I) && !isone(I)
  @assert isbinomial(I)

  fl, v = _iscellular(I)
  if fl
    return typeof(I)[I]
  end
  #choose a variable which is a zero divisor but not nilptent modulo I -> A[2] (if not dummer fall)
  #determine the power s s.t. (I:x_i^s)==(I:x_i^infty)
  Rxy = base_ring(I)
  variables = gens(Rxy)
  J = ideal(Rxy, variables[v[1]])
  I1, ksat = saturation_with_index(I, J)
  #now compute the cellular decomposition of the binomial ideals (I:x_i^s) and I+(x_i^s)
  #by recursively calling the algorithm
  decomp = typeof(I)[]
  I2 = I+ideal(Rxy, variables[v[1]]^ksat)

  DecompI1 = cellular_decomposition(I1)
  DecompI2 = cellular_decomposition(I2)

  #now check for redundancies
  redTest = ideal(Rxy, one(Rxy))
  redTestIntersect = ideal(Rxy, one(Rxy))
  for i = 1:length(DecompI1)
    redTestIntersect = intersect(redTest, DecompI1[i])
    if !issubset(redTest, redTestIntersect)
      push!(decomp, DecompI1[i])
    end
    redTest = redTestIntersect
  end
  for i = 1:length(DecompI2)
    redTestIntersect = intersect(redTest, DecompI2[i])
    if !issubset(redTest, redTestIntersect)
      push!(decomp, DecompI2[i])
    end
    redTest = redTestIntersect
  end
  return decomp
end


function isunital(I::MPolyIdeal)
  #check if I is a unital ideal
  #(i.e. if it is generated by pure difference binomials and monomials)
  if !isbinomial(I)
    return false
  end
  gB = groebner_basis(I, complete_reduction = true)
  Rxy = base_ring(I)
  R = base_ring(Rxy)
  for i = 1:ngens(I)
    if length(I[i]) <= 1
      continue
    end
    c = collect(coefficients(I[i]))::Vector{elem_type(R)}
    if isone(c[1])
      if !isone(-c[2])
        return false
      end
    elseif isone(-c[1])
      if !isone(c[2])
        return false
      end
    else
      return false
    end
  end
  return true
end


function _remove_redundancy(A::Vector{Tuple{T, T}}) where T <: MPolyIdeal
  #input:two Array of ideals, the first are primary ideals, the second the corresponding associated primes
  #output:Arrays of ideals consisting of some ideals less which give the same interseciton as
  #all ideals before
  fa = _find_minimal([x[1] for x in A])
  return A[fa]
end

function inclusion_minimal_ideals(A::Vector{T}) where T <: MPolyIdeal
  #returns all ideals of A which are minimal with respect to inclusion
  fa = _find_minimal(A)
  return A[fa]
end

function _find_minimal(A::Vector{T}) where T <: MPolyIdeal
  isminimal = trues(length(A))
  for i = 1:length(A)
    if !isminimal[i]
      continue
    end
    for j = 1:length(A)
      if i == j || !isminimal[j]
        continue
      end
      if issubset(A[i], A[j])
        minimal[j] = false
      elseif issubset(A[j], A[i])
        minimal[i] = false
        break
      end
    end
  end
  fa = findall(isminimal)
  return fa
end

function cellular_decomposition_macaulay(I::MPolyIdeal)
  #algorithm after Macaulay2 implementation for computing a cellular decomposition of a binomial ideal
  #seems to be faster than cellularDecomp, but there are still examples which are really slow

  if !isbinomial(I)
    error("Input ideal is not binomial")
  end

  R = base_ring(I)
  n = nvars(R)
  intersectAnswer = ideal(R, one(R))
  res = typeof(I)[]
  todo = Tuple{Vector{elem_type(R)}, Vector{elem_type(R)}, typeof(I)}[(elem_type(R)[], gens(R), I)]
  #every element in the todo list has three dedicated data:
  #1: contains a list of variables w.r.t. which it is already saturated
  #2: conatains variables to be considered for cell variables
  #3: is the ideal to decompose

  while !isempty(todo)
    L = popfirst!(todo)
    if issubset(intersectAnswer, L[3])
      #found redundant component
      continue
    elseif isempty(L[2])
      #no variables remain to check -> we have an answer
      newone = L[3] #ideal
      push!(res, newone)
      intersectAnswer = intersect(intersectAnswer, newone)
      if issubset(intersectAnswer, I)
        return inclusion_minimal_ideals(res)
      end
    else
      #there are remaining variables
      L2 = copy(L[2])
      i = popfirst!(L2) #variable under consideration
      J, k = saturation_with_index(L[3], ideal(R, i))
      if k > 0
        #if a division was needed we add the monomial i^k to the ideal
        #under consideration
        J2 = L[3] + ideal(R, [i^k])
        #compute product of all variables in L[1]
        r = prod(L[1], init = one(R))
        J2 = saturation(J2, ideal(R, r))
        if !isone(J2)
          #we have to decompose J2 further
          push!(todo, (copy(L[1]), L2, J2))
        end
      end
      #continue with the next variable and add i to L[1]
      if !isone(J)
        L1 = copy(L[1])
        push!(L1, i)
        push!(todo, (L[1], L2, J))
      end
    end
  end
  return inclusion_minimal_ideals(res)
end

###################################################################################
#
#       Partial characters and ideals
#
###################################################################################

function ideal_from_character(P::QabModule.PartialCharacter, R::MPolyRing)
  #input: partial character P and a polynomial ring R
  #output: the ideal $I_+(P)=\langle x^{u_+}- P(u)x^{u_-} \mid u \in P.A \rangle$

  @assert ncols(P.A) == nvars(R)
  #test if the domain of the partial character is the zero lattice
  if isone(nrows(P.A)) && QabModule.have_same_span(P.A, zero_matrix(FlintZZ, 1, ncols(P.A)))
    return ideal(R, zero(R))
  end

  #now case if P.A is the identity matrix
  #then the ideal generated by the generators of P.A suffices and gives the whole ideal I_+(P)
  #note that we can only compare the matrices if P.A is a square matrix
  if ncols(P.A) == nrows(P.A) && isone(P.A)
    return _make_binomials(P, R)
  end

  #now check if the only values of P taken on the generators of the lattice is one
  #then we can use markov bases
  #simple test
  test = true
  i = 1
  Variables = gens(R)
  I = ideal(R, zero(R))

  while test && i <= length(P.b)
    if !isone(P.b[i])
      #in this case there is a generator g for which P(g)!=1
      test = false
    end
    i=i+1
  end

  if test
    #then we can use markov bases to get the ideal
    A = markov4ti2(P.A)
    #now get the ideal corresponding to the computed markov basis
    #-> we have nr generators for the ideal
    #for each row vector compute the corresponding binomial
    for k = 1:nrows(A)
      monomial1 = one(R)
      monomial2 = one(R)
      for s = 1:ncols(A)
        expn = A[k,s]
        if expn < 0
          monomial2=monomial2*Variables[s]^(-expn)
        elseif expn > 0
          monomial1=monomial1*Variables[s]^expn
        end
      end
      #the new generator for the ideal is monomial1-minomial2
      I += ideal(R, monomial1-monomial2)
    end
    return I
  end

  #now consider the last case where we have to saturate
  I = _make_binomials(P, R)
  #now we have to saturate the ideal by the product of the ring variables
  varProduct = prod(Variables)
  return saturation(I, ideal(R, varProduct))
end

function _make_binomials(P::QabModule.PartialCharacter, R::MPolyRing)
  #output: ideal generated by the binomials corresponding to the generators of the domain P.A of the partial character P
  #Note: This is not the ideal I_+(P)!!
  @assert ncols(P.A) == nvars(R)
  Variables = gens(R)
  #-> we have nr binomial generators for the ideal
  I = ideal(R, zero(R))

  for k = 1:nrows(P.A)
    monomial1 = one(R)
    monomial2 = one(R)
    for s = 1:ncols(P.A) 
      expn = P.A[k,s]
      if expn < 0
        monomial2 *= Variables[s]^(-expn)
      elseif expn > 0
        monomial1 *= Variables[s]^expn
      end
    end
    #the new generator for the ideal is monomial1-P.b[k]*monomial2
    I += ideal(R, monomial1-(coeff(P.b[k].data, 0))*monomial2)
  end
  return I
end

function partial_character_from_ideal(I::MPolyIdeal, R::MPolyRing)
  #input: cellular binomial ideal
  #output: the partial character corresponding to the ideal I \cap k[\mathbb{N}^\Delta]

  #first test if the input ideal is really a cellular ideal
  if !isbinomial(I)
    error("Input ideal is not binomial")
  end
  cell = iscellular(I)
  if !cell[1]
    error("input ideal is not cellular")
  end

  Delta = cell[2]   #cell variables
  if isempty(Delta)
    return QabModule.partial_character(zero_matrix(FlintZZ, 1, nvars(R)), [one(QabModule.QabField())], Set{Int64}())
  end

  #now consider the case where Delta is not empty
  #fist compute the intersection I \cap k[\Delta]
  #for this use eliminate function from Singular. We first have to compute the product of all
  #variables not in Delta
  Variables = gens(R)
  J = eliminate(I, elem_type(R)[Variables[i] for i = 1:nvars(R) if !(i in Delta)])
  if iszero(J)
    return QabModule.partial_character(zero_matrix(FlintZZ, 1, nvars(R)), [one(QabModule.QabField())], Set{Int64}())
  end
  #now case if J \neq 0
  #let ts be a list of minimal binomial generators for J
  gb = groebner_basis(J, complete_reduction = true)
  vs = zero_matrix(FlintZZ, 0, nvars(R))
  images = QabModule.QabElem[]
  Qabcl = QabModule.QabField()
  for t in gb
    #TODO: Once tail will be available, use it.
    lm = leading_monomial(t)
    tl = t - lm
    u = exponent_vector(lm, 1)
    v = exponent_vector(tl, 1)
    #now test if we need the vector uv
    uv = matrix(FlintZZ, 1, nvars(R), Int[u[j]-v[j] for j  =1:length(u)]) #this is the vector of u-v
    #TODO: It can be done better by saving the hnf...
    if !can_solve(vs, uv, side = :left)[1]
      push!(images, -Qabcl(leading_coefficient(tl)))
      vs = vcat(vs, uv)#we have to save u-v as generator for the lattice
    end
  end
  #delete zero rows in the hnf of vs so that we do not get problems when considering a
  #saturation
  hnf!(vs)
  i = nrows(vs)
  while iszero_row(vs, i)
    i -= 1
  end
  vs = view(vs, 1:i, 1:nvars(R))
  return QabModule.partial_character(vs, images, Set{Int64}(Delta))
end

###################################################################################
#
#   Embedded associated lattice witnesses and hull
#
###################################################################################
"""
    cellular_standard_monomials(I::MPolyIdeal)

Given a cellular ideal I, it returns the standard monomials of the ideal.
"""
function cellular_standard_monomials(I::MPolyIdeal)
  
#=`I `\cap `k[`\mathbb{N}`^`{`\Delta`^`c`}]` (these are only finitely many).=#

  cell = iscellular(I)
  if !cell[1]
    error("Input ideal is not cellular")
  end
  R = base_ring(I)

  #now we start computing the standard monomials
  #first determine the set Delta^c of noncellular variables
  DeltaC = Int[i for i = 1:nvars(R) if !(i in cell[2])]

  #eliminate the variables in Delta
  Variables=Singular.gens(R)
  prodDelta = elem_type(R)[Variables[i] for i in cell[2]]
  if isempty(prodDelta)
    J = I
  else
    J = eliminate(I, prodDelta)
  end

  bas = Vector{elem_type(R)}[]
  for i in DeltaC
    mon = elem_type(R)[] #this will hold set of standard monomials
    flag = true
    push!(mon, one(R))
    x = Variables[i]
    while !(x in I)
      push!(mon, x)
      x *= Variables[i]
    end
    push!(bas, mon)
  end

  leadIdeal = leading_ideal(J)
  res = elem_type(R)[]
  it = Hecke.cartesian_product_iterator(UnitRange{Int}[1:length(x) for x in bas], inplace = true)
  for I in it
    testmon = prod(bas[i][I[i]] for i = 1:length(I))
    if !(testmon in leadIdeal)
      push!(res, testmon)
    end
  end
  return res
end

"""
    witness_monomials(I::MPolyIdeal)

Given a cellular binomial ideal I, it returns a set of monomials generating M_{emb}(I)
"""
function witness_monomials(I::MPolyIdeal)
  #test if input ideal is cellular
  cell = iscellular(I)
  if !cell[1]
    error("input ideal is not cellular")
  end

  R = base_ring(I)
  Delta = cell[2]
  #compute the PartialCharacter corresponding to I and the standard monomials of I \cap k[N^Delta]
  P = partial_character_from_ideal(I, R)
  M = cellular_standard_monomials(I)  #array of standard monomials, this is our to-do list
  witnesses = elem_type(R)[]   #this will hold our set of witness monomials

  for i = 1:length(M)
    el = M[i]
    Iquotm = quotient(I, ideal(R, el))
    Pquotm = partial_character_from_ideal(Iquotm, R)
    if rank(Pquotm.A) > rank(P.A)
      push!(witnesses, el)
    end
    #by checking for divisibility of the monomials in M by M[1] respectively of M[1]
    #by monomials in M, some monomials in M necessarily belong to Memb, respectively can
    #be directly excluded from being elements of Memb
    #todo: implement this for improvement
  end
  return witnesses
end

"""
    cellular_hull(I::MPolyIdeal)

Given a cellular binomial ideal I, it returns a hull(I), i.e. the the intersection 
of all minimal primary components of I.
"""
function cellular_hull(I::MPolyIdeal)
  #by theorems we know that Hull(I)=M_emb(I)+I
  cell = iscellular(I)
  if !cell[1]
    error("input ideal is not cellular")
  end
  #now construct the ideal M_emb with the above algorithm witnessMonomials
  R = base_ring(I)
  M = witness_monomials(I)
  if isempty(M)
    return I
  end
  return I + ideal(R, M)
end

###################################################################################
#
#       Associated primes
#
###################################################################################

function cellular_associated_primes(I::MPolyIdeal)
  #input: cellular binomial ideal
  #output: the set of associated primes of I

  if !isunital(I)
    error("Input ideal has to be a unital ideal")
  end
  cell = iscellular(I)
  if !cell[1]
    error("Input ideal is not cellular")
  end

  associated_primes = Vector{typeof(I)}()  #this will hold the set of associated primes of I
  R = base_ring(I)
  Variables = gens(R)
  U = cellular_standard_monomials(I)  #set of standard monomials

  #construct the ideal (x_i \mid i \in \Delta^c)
  gi = elem_type(R)[Variables[i] for i = 1:nvars(R) if !(i in cell[2])]
  idealDeltaC = ideal(R, gi)

  for m in U
    Im = quotient(I, ideal(R, m))
    Pm = partial_character_from_ideal(Im, R)
    #now compute all saturations of the partial character Pm
    PmSat = QabModule.saturations(Pm)
    for P in PmSat
      push!(associated_primes, ideal_from_character(P, R) + idealDeltaC)
    end
  end

  #now check if there are superflous elements in Ass
  res = Vector{typeof(I)}() 
  for i = 1:length(associated_primes)
    found = false
    for j = 1:length(res)
      if associated_primes[i] == res[j]
        found = true
        break
      end
    end
    if !found
      push!(res, associated_primes[i])
    end
  end
  return res
end

function cellular_minimal_associated_primes(I::MPolyIdeal)
  #input: cellular unital ideal
  #output: the set of minimal associated primes of I

  if !isunital(I)
    error("Input ideal is not a unital ideal")
  end
  cell = iscellular(I)
  if !cell[1]
    error("Input ideal is not cellular")
  end
  R = base_ring(I)
  P = partial_character_from_ideal(I, R)
  PSat = QabModule.saturations(P)
  minimal_associated = Vector{typeof(I)}() #this will hold the set of minimal associated primes

  #construct the ideal (x_i \mid i \in \Delta^c)
  Variables = gens(R)
  gs = [Variables[i] for i = 1:nvars(R) if !(i in cell[2])]
  idealDeltaC = ideal(R, gs)

  for Q in PSat
    push!(minimal_associated, ideal_from_character(Q, R)+idealDeltaC)
  end
  return minimal_associated
end

function binomial_associated_primes(I::MPolyIdeal)
  #input:unital ideal
  #output: the associated primes, but only implemented effectively in the cellular case
  #in the noncellular case compute a primary decomp and take radicals

  if !isunital(I)
    error("input ideal is not a unital ideal")
  end
  cell = iscellular(I)
  if cell[1]
    return cellular_associated_primes(I)
  end

  #now consider the case when I is not cellular and compute a primary decomposition
  PD = binomial_primary_decomposition(I)
  return typeof(I)[x[2] for x in PD]
end

###################################################################################
#
#   Primary decomposition
#
###################################################################################

function cellular_primary_decomposition(I::MPolyIdeal)    
  #algorithm from macaulay2
  #input: unital cellular binomial ideal in k[x]
  #output: binomial primary ideals which form a minimal primary decomposition of I 
  #        and the corresponding associated primes in a second array

  if !isunital(I)
    error("Input ideal is not a unital ideal")
  end

  cell = iscellular(I)
  if !cell[1]
    error("Input ideal is not cellular")
  end

  #compute associated primes
  cell_ass = cellular_associated_primes(I)
  cell_primary = typeof(I)[]     #this will hold the set of primary components

  #compute product of all non cellular variables and the product of all cell variables
  R = base_ring(I)
  Variables = gens(R)
  prodDeltaC = elem_type(R)[Variables[i] for i = 1:nvars(R) if !(i in cell[2])]
  prodDelta = elem_type(R)[Variables[i] for i in cell[2]]

  J = ideal(R, prodDelta)
  res = Vector{Tuple{typeof(I), typeof(I)}}()
  for P in cell_ass
    helpIdeal = I + eliminate(P, prodDeltaC)
    #now saturate the ideal with respect to the cellular variables
    helpIdeal = saturation(helpIdeal, J)
    push!(res, (cellular_hull(helpIdeal), P))
  end
  return res
end

function binomial_primary_decomposition(I::MPolyIdeal)
  #input: a binomial ideal such that the ideals in its cellular
  #       decomposition are unital 
  #output: binomial primary ideals which form a not necessarily
  #         minimal primary decomposition of I, together with its corresponding associated primes 
  #         in the same order as the primary components

  #first compute a cellular decomposition of I
  cell_comps = cellular_decomposition_macaulay(I)

  res = Vector{Tuple{typeof(I), typeof(I)}}() #This will hold the set of primary components
  #now compute a primary decomposition of each cellular component
  for J in cell_comps
    resJ = cellular_primary_decomposition(J)
    append!(res, resJ)
  end
  return _remove_redundancy(res)
end

function markov4ti2(L::fmpz_mat)
  #sanity checks noch einbauen!!
  nc = ncols(L)
  nr = nrows(L)
  #have to prepare an input file for 4ti2
  #create the file julia4ti2.lat
  name = tempname()
  mkdir(name)
  name = joinpath(name, "julia4ti2")
  f=open("$name.lat","w")
  write(f,"$nr ")
  write(f,"$nc \n")

  for i=1:nr
    for j=1:nc
      write(f,"$(L[i,j]) ")
    end
    write(f,"\n")
  end
  close(f)

  #now we have the file julia4ti2.lat in the current working directory
  #can run 4ti2 with this input file to get a markov basis
  lib4ti2_jll.exe4ti2gmp() do x 
    run(ignorestatus(`$x markov -q $name`))
  end

#        run(`$(lib4ti2_jll.markov) -q $name`)
  #this creates the file julia4ti2.mar with the markov basis

  #now we have to get the matrix from julia4ti2.mat in julia
  #this is an array of thype Any
  helpArray=readdlm("$name.mar")
  sizeHelpArray=size(helpArray)

  #the size of the markov basis matrix is
  nColMarkov=Int(helpArray[1,2])
  nRowMarkov=Int(helpArray[1,1])

  #now we have convert the lower part of the array helpArray into an Array of type Int64
  helpArrayInt = zeros(Int64,nRowMarkov,nColMarkov)

  for i=2:(nRowMarkov+1)
    for j=1:nColMarkov
      helpArrayInt[i-1,j]=helpArray[i,j]
    end
  end

  ##remove constructed files
  #run(`rm julia4ti2.lat`)
  #run(`rm julia4ti2.mar`)
  return helpArrayInt
end