export display_buffer

using CartesianGeneticProgramming

"""
    function display_buffer(ind::CGPInd)

Display the images contained in each node in the input IPCGP individual.
"""
function display_buffer(ind::CGPInd)
    for i in eachindex(ind.buffer)
        println(i)
    end
end
