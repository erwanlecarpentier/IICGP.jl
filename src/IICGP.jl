module IICGP

using CartesianGeneticProgramming
using Cambrian
using FileIO
using Logging
using Dates
import Formatting
import JSON
import YAML

include("individual.jl") # before evolution.jl
include("evolution.jl")
include("evaluation.jl")
include("functions.jl")
include("reducer.jl")
include("game.jl")
include("populate.jl")
include("config.jl")
include("process.jl")
include("postproc.jl")
include("utils.jl")
include("init.jl")
include("saving.jl")
include("visual.jl")

end
