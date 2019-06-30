module CompressedCellValues

using Gridap
using Gridap.CellNumberApply: IndexCellNumberFromKernel, CellNumberFromKernel
using Gridap.CellArrayApply: IndexCellArrayFromKernel, CellArrayFromKernel

export IterCompressedCellValue
export IndexCompressedCellValue
export CompressedCellValue

import Base: iterate
import Base: length
import Base: size
import Base: getindex

import Gridap: apply
import Gridap: reindex
import Gridap: evaluate
import Base: ==, ≈

struct IterCompressedCellValue{T,A} <: IterCellValue{T}
  values::Vector{T}
  ptrs::A

  function IterCompressedCellValue(
    values::Vector{T}, ptrs) where T
    @assert hasmethod(iterate,Tuple{typeof(ptrs)})
    @assert hasmethod(length,Tuple{typeof(ptrs)})
    A = typeof(ptrs)
    new{T,A}(values,ptrs)
  end

end

@inline function iterate(cv::IterCompressedCellValue)
  inext = iterate(cv.ptrs)
  _iterate(cv,inext)
end

@inline function iterate(cv::IterCompressedCellValue,state)
  inext = iterate(cv.ptrs,state)
  _iterate(cv,inext)
end

@inline function _iterate(cv,inext)
  if inext === nothing; return nothing; end
  i, istate = inext
  v = cv.values[i]
  (v,istate)
end

length(cv::IterCompressedCellValue) = length(cv.ptrs)

struct IndexCompressedCellValue{T,A} <: IndexCellValue{T,1}
  values::Vector{T}
  ptrs::A

  function IndexCompressedCellValue(
    values::Vector{T}, ptrs::AbstractArray) where T
    A = typeof(ptrs)
    new{T,A}(values,ptrs)
  end

end

function IndexCompressedCellValue(cv::ConstantCellValue)
  values = [cv.value,]
  ptrs = ConstantCellValue(1,length(cv))
  IndexCompressedCellValue(values,ptrs)
end

function getindex(
  cv::IndexCompressedCellValue{T,A}, i::Integer) where {T,A}
  j = cv.ptrs[i]
  cv.values[j]
end

size(cv::IndexCompressedCellValue) = (length(cv.ptrs),)

const CompressedCellValue{T} = Union{
  IterCompressedCellValue{T},IndexCompressedCellValue{T}}

function CompressedCellValue(values::Vector{T},ptrs::AbstractArray) where T
  IndexCompressedCellValue(values,ptrs)
end

function CompressedCellValue(values::Vector{T},ptrs) where T
  IterCompressedCellValue(values,ptrs)
end

function (==)(a::CompressedCellValue,b::CompressedCellValue)
  _eq_kernel(==,a,b)
end

function (≈)(a::CompressedCellValue,b::CompressedCellValue)
  _eq_kernel(≈,a,b)
end

function _eq_kernel(op,a,b)
  !(op(a.values,b.values)) && return false
  !( a.ptrs == b.ptrs ) && return false
  length(a) != length(b) && return false
  return true
end

function apply(k::NumberKernel,v::Vararg{<:CompressedCellValue})
  optim = _is_optimizable(v...)
  _apply(Val(optim),k,v...)
end

function apply(k::ArrayKernel,v::Vararg{<:CompressedCellValue})
  optim = _is_optimizable(v...)
  _apply(Val(optim),k,v...)
end

function _is_optimizable(v...)
  @assert length(v) > 0
  v1, = v
  all( [ _is_compatible_data(vi,v1) for vi in v] )
end

function _is_compatible_data(a,b)
  if length(a.values) != length(b.values)
    return false
  end
  if a.ptrs === b.ptrs
    return true
  end
  if a.ptrs == b.ptrs
    return true
  end
  false
end

function _apply(::Val{true},k,v...)
  v1, = v
  n = length(v1.values)
  input_values = [ [ vi.values[i] for vi in v] for i in 1:n]
  values = [ compute_value(k,vals...) for vals in input_values ]
  CompressedCellValue(values,v1.ptrs)
end

function _apply(::Val{false},k::NumberKernel,v::Vararg{<:IndexCompressedCellValue})
    IndexCellNumberFromKernel(k,v...)
end

function _apply(::Val{false},k::NumberKernel,v::Vararg{<:CompressedCellValue})
    CellNumberFromKernel(k,v...)
end

function _apply(::Val{false},k::ArrayKernel,v::Vararg{<:IndexCompressedCellValue})
    IndexCellArrayFromKernel(k,v...)
end

function _apply(::Val{false},k::ArrayKernel,v::Vararg{<:CompressedCellValue})
    CellArrayFromKernel(k,v...)
end

end # module
