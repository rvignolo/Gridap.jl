module VtkTests

using Gridap.Geometry: ConformingTrianMock
using Gridap.Geometry: DiscreteModelMock
using Gridap.TensorValues
using Gridap.Arrays
using Gridap.Fields
using Gridap.ReferenceFEs
using Gridap.Geometry
using Gridap.Visualization

d = mktempdir()
f = joinpath(d,"trian")

trian = ConformingTrianMock()

node_ids = collect(1:num_nodes(trian))
cell_ids = collect(1:num_cells(trian))

mean(x) = sum(x)/length(x)

cell_center = apply(mean, get_cell_coordinates(trian) )

write_vtk_file(
  trian,f,
  nodaldata=["nodeid"=>node_ids],
  celldata=["cellid"=>cell_ids,"centers"=>cell_center])

writevtk(trian,f)

writevtk(
  trian,f,
  nodaldata=["nodeid"=>node_ids],
  celldata=["cellid"=>cell_ids,"centers"=>cell_center])

reffe = LagrangianRefFE(VectorValue{3,Float64},WEDGE,(3,3,4))
f = joinpath(d,"reffe")
writevtk(reffe,f)

f = joinpath(d,"poly")
writevtk(HEX,f)

domain = (0,1,0,1,0,1)
partition = (3,4,2)
grid = CartesianGrid(domain,partition)
model = UnstructuredDiscreteModel(grid)

f = joinpath(d,"model")
writevtk(model,f)


f = joinpath(d,"model")
model = DiscreteModelMock()
writevtk(model,get_face_labeling(model),f)

rm(d,recursive=true)

end # module
