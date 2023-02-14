################################################################################
# Bool
@registerSerializationType(Bool)

function save_internal(s::SerializerState, b::Bool)
    return string(b)
end

function load_internal(s::DeserializerState, ::Type{Bool}, str::String)
  if str == "true"
    return true
  end

  if str == "false"
    return false
  end

  throw(ErrorException("Error parsing boolean string: $str"))
end

################################################################################
# fmpz
@registerSerializationType(fmpz)

function save_internal(s::SerializerState, z::fmpz)
    return string(z)
end

function load_internal(s::DeserializerState, ::Type{fmpz}, str::String)
    return fmpz(str)
end

function load_internal_with_parent(s::DeserializerState,
                                   ::Type{fmpz},
                                   str::String,
                                   parent::FlintIntegerRing)
    return parent(fmpz(str))
end

################################################################################
# fmpq
@registerSerializationType(fmpq)

function save_internal(s::SerializerState, q::fmpq)
    return string(q)
end

function load_internal(s::DeserializerState, ::Type{fmpq}, q::String)
    # TODO: simplify the code below once https://github.com/Nemocas/Nemo.jl/pull/1375
    # is merged and in a Nemo release
    fraction_parts = collect(map(String, split(q, "//")))
    fraction_parts = [fmpz(s) for s in fraction_parts]

    return fmpq(fraction_parts...)
end

function load_internal_with_parent(s::DeserializerState,
                                   ::Type{fmpq},
                                   str::String,
                                   parent::FlintRationalField)
    return parent(load_internal(s, fmpq, str))
end


################################################################################
# Number
@registerSerializationType(Int8)
@registerSerializationType(Int16)
@registerSerializationType(Int32)
@registerSerializationType(Int64, "Base.Int")
@registerSerializationType(Int128)

@registerSerializationType(UInt8)
@registerSerializationType(UInt16)
@registerSerializationType(UInt32)
@registerSerializationType(UInt64)
@registerSerializationType(UInt128)

@registerSerializationType(BigInt)

@registerSerializationType(Float16)
@registerSerializationType(Float32)
@registerSerializationType(Float64)

function save_internal(s::SerializerState, z::Number)
    return string(z)
end

function load_internal(s::DeserializerState, ::Type{T}, str::String) where {T<:Number}
    return parse(T, str)
end


################################################################################
# Strings
@registerSerializationType(String)

function save_internal(s::SerializerState, str::String)
    return str
end

function load_internal(s::DeserializerState, ::Type{String}, str::String)
    return str
end


################################################################################
# Symbol
@registerSerializationType(Symbol)

function save_internal(s::SerializerState, sym::Symbol)
   return string(sym)
end

function load_internal(s::DeserializerState, ::Type{Symbol}, str::String)
   return Symbol(str)
end