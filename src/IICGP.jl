module IICGP

import YAML
using CartesianGeneticProgramming
using Cambrian
import JSON

include("evolution.jl")
include("evaluation.jl")
include("functions.jl")
include("reducer.jl")
include("individual.jl")
include("process.jl")
include("utils.jl")
include("visual.jl")

end
