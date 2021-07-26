module IICGP

using CartesianGeneticProgramming
using Cambrian
using FileIO
using Logging
using Dates
import Formatting
import JSON
import YAML

include("evolution.jl")
include("evaluation.jl")
include("functions.jl")
include("reducer.jl")
include("game.jl")
include("individual.jl")
include("oneplus.jl")
include("config.jl")
include("process.jl")
include("postproc.jl")
include("utils.jl")
include("visual.jl")

end
