export read_config

using Dates
using YAML

"""
Overrides `Cambrian.get_config(::Dict)``
Converts function names to functions and tracks arity

Warning: copy of `CartesianGeneticProgramming.get_config(::Dict)`
and `Cambrian.get_config(::String; kwargs...)`
CartesianGeneticProgramming could have a generic way to add CGP functions and
adapt the get_config function to multiple function sources
"""
function read_config(config_filename::String; kwargs...)

    # Retrieve cfg dict
    config = YAML.load_file(config_filename)
    for (k, v) in kwargs
        config[String(k)] = v
    end
    # generate id, use date if no existing id
    if ~(:id in keys(config))
        config["id"] = string(Dates.now())
    end

    # parse all function names, assign to function value
    two_arity = falses(length(config["functions"]))
    functions = Array{Function}(undef, length(config["functions"]))
    for i in eachindex(config["functions"])
        fname = config["functions"][i]
        if IPCGPFunctions.arity[fname] == 2
            two_arity[i] = true
        end
        functions[i] = eval(Meta.parse(string("IPCGPFunctions.", fname)))
    end
    config["two_arity"] = two_arity
    config["functions"] = functions
    return (; (Symbol(k)=>v for (k, v) in config)...)
end
