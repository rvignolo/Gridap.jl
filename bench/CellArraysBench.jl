

let

  N = 1000000

  using Numa.CellArrays
  using Numa.FieldValues

  println("+++ CellArraysBench ( length = $N ) +++")

  function doloop(a)
    for ai in a
    end
  end

  aa = [1.0,2.0,2.1]
  a = ConstantCellArray(aa,N)
  aa2 = [0.0,2.1,1.1]
  a2 = ConstantCellArray(aa2,N)
  bb = [aa';aa']
  z = ConstantCellArray(bb,N)
  vv = VectorValue(0.0,1.0,2.0)
  vvv = [vv, -2.0*vv, 4*vv]
  v = ConstantCellArray(vvv,N)

  print("ConstantCellArray ->"); @time doloop(a)
  print("ConstantCellArray ->"); @time doloop(a)

  eval(quote

    struct DummyCellArray{C} <: CellArrayFromUnaryOp{C,Float64,2}
      a::C
    end

    import Numa.CellArrays: inputcellarray
    import Numa.CellArrays: computesize
    import Numa.CellArrays: computevals!
    
    inputcellarray(self::DummyCellArray) = self.a
    
    computesize(self::DummyCellArray,asize) = (2,asize[1])
    
    function computevals!(self::DummyCellArray,a,v)
      @inbounds for j in 1:size(a,1)
        for i in 1:2
          v[i,j] = a[j]
        end
      end
    end

  end)

  b = DummyCellArray(a)

  print("CellArrayFromUnaryOp ->"); @time doloop(b)
  print("CellArrayFromUnaryOp ->"); @time doloop(b)


  tv = TensorValue{2,4}(0.0,1.0,2.0,2.0)
  tt = [tv, tv, 4*tv, -1*tv]
  t = ConstantCellArray(tt,N)
  c = Numa.CellArrays.CellArrayFromDet{typeof(t),Float64,1}(t)

  print("CellArrayFromDet ->"); @time doloop(c)
  print("CellArrayFromDet ->"); @time doloop(c)

  d = Numa.CellArrays.CellArrayFromInv{typeof(t),typeof(tv),1}(t)

  print("CellArrayFromInv ->"); @time doloop(d)
  print("CellArrayFromInv ->"); @time doloop(d)

  e = Numa.CellArrays.CellArrayFromSum{typeof(a),typeof(a2),Float64,1}(a,a2)

  print("CellArrayFromSum ->"); @time doloop(e)
  print("CellArrayFromSum ->"); @time doloop(e)

  f = Numa.CellArrays.CellArrayFromCellSum{2,1,typeof(z),Float64}(z)

  print("CellArrayFromCellSum ->"); @time doloop(f)
  print("CellArrayFromCellSum ->"); @time doloop(f)

  g = d + t

  print("NestedLazyCellArray ->"); @time doloop(g)
  print("NestedLazyCellArray ->"); @time doloop(g)

  ls = length(size(bb))+1
  h = Numa.CellArrays.CellArrayFromCellNewAxis{2,typeof(z),Float64,ls}(z)

  print("CellArrayFromCellNewAxis ->"); @time doloop(h)
  print("CellArrayFromCellNewAxis ->"); @time doloop(h)

  m = Numa.CellArrays.CellArrayFromOuter{typeof(a),typeof(v),VectorValue{3},1}(a,v)

  print("CellArrayFromOuter ->"); @time doloop(m)
  print("CellArrayFromOuter ->"); @time doloop(m)

  n = Numa.CellArrays.CellArrayFromInner{typeof(v),typeof(v),Float64,1}(v,v)

  print("CellArrayFromInner ->"); @time doloop(n)
  print("CellArrayFromInner ->"); @time doloop(n)

end