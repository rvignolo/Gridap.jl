module OperationsTests

using Test
using Numa
using Numa.CellValues
using Numa.CellValues.ConstantCellValues
using Numa.Maps
using Numa.CellMaps
using Numa.CellMaps.ConstantCellMaps
using Numa.CellMaps.Testers
using Numa.CellMaps.CellMapValues
using Numa.FieldValues

import Numa: gradient

include("../MapsTests/MockMap.jl")
include("../MapsTests/MockBasis.jl")
include("Mocks.jl")

l = 10

p1 = Point(1.0,2.0)
p2 = Point(1.1,2.0)
p3 = Point(1.1,2.3)
ps = [p1,p2,p3]
cv = TestCellArray(ps,l)

p0 = Point(1.4,2.0)
m = MockMap(p0)
@test isa(m,Field)
cm = TestCellMap(m,l)
@test isa(cm,CellField)

rs = evaluate(m,ps)
grs = evaluate(gradient(m),ps)
crs = [ rs for i in 1:l]
gcrs = [ grs for i in 1:l]
test_cell_map_with_gradient(cm,cv,crs,gcrs)

for op in (:+, :-)
  @eval begin
    ucm = $op(cm)
    test_cell_map_without_gradient(ucm,cv,$op(crs))
  end
end

m1 = MockMap(p1)
m2 = MockMap(p2)
cm1 = TestCellMap(m1,l)
cm2 = TestCellMap(m2,l)
rs1 = evaluate(m1,ps)
rs2 = evaluate(m2,ps)
crs1 = [ rs1 for i in 1:l]
crs2 = [ rs2 for i in 1:l]

for op in (:+, :-, :(inner), :(outer))
  @eval begin
    ucm = $op(cm1,cm2)
    ucrs = [ $op.(rs1,rs2)  for i in 1:l ]
    test_cell_map_without_gradient(ucm,cv,ucrs)
  end
end

# compose

f(p::Point{2}) = 2*p
gradf(p::Point{2}) = VectorValue(2.0,2.0)
gradient(::typeof(f)) = gradf

ucm = compose(f,cm)
rs = evaluate(m,ps)
crs = [ f.(rs) for i in 1:l]
gcrs = [ gradf.(rs) for i in 1:l]
cv = TestCellArray(ps,l)
test_cell_map_with_gradient(ucm,cv,crs,gcrs)

# varinner

bas = MockBasis(p1,3)
fie = MockMap(p2)
cbas = TestCellMap(bas,l)
cfie = TestCellMap(fie,l)

ucm = varinner(cfie,cfie)
rs = evaluate(varinner(fie,fie),ps)
crs = [rs for i in 1:l]
test_cell_map_without_gradient(ucm,cv,crs)

ucm = varinner(cbas,cfie)
rs = evaluate(varinner(bas,fie),ps)
crs = [rs for i in 1:l]
test_cell_map_without_gradient(ucm,cv,crs)

ucm = varinner(cbas,cbas)
rs = evaluate(varinner(bas,bas),ps)
crs = [rs for i in 1:l]
test_cell_map_without_gradient(ucm,cv,crs)

# lincomb

coefs = [1.0,1.0,1.0]
ccoefs = TestCellArray(coefs,l)
ucm = lincomb(cbas,ccoefs)
ffe = lincomb(bas,coefs)
rs  = evaluate(ffe,ps)
grs  = evaluate(gradient(ffe),ps)
crs = [rs for i in 1:l]
cgrs = [grs for i in 1:l]
test_cell_map_with_gradient(ucm,cv,crs,cgrs)

end # module OperationsTests
