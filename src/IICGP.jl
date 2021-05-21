module IICGP

using CartesianGeneticProgramming
using Cambrian
using FileIO
using Logging
import JSON
import YAML

include("evolution.jl")
include("evaluation.jl")
include("functions.jl")
include("reducer.jl")
include("game.jl")
include("individual.jl")
include("oneplus.jl")
include("process.jl")
include("utils.jl")
include("visual.jl")

end
