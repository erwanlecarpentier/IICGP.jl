using IICGP
using Cambrian
using CartesianGeneticProgramming
using Test

import Cambrian.mutate # function extension


function get_elites(e::DualCGPGAEvo)
    elite_echr = Vector{Vector{Float64}}()
    elite_cchr = Vector{Vector{Float64}}()
    ci = CartesianIndices(e.elites_matrix)
    for i in eachindex(e.elites_matrix)
        if e.elites_matrix[i]
            row, col = ci[i][1], ci[i][2]
            echr = e.encoder_sympop[row].chromosome
            cchr = e.controller_sympop[col].chromosome
            if !(echr in elite_echr)
                push!(elite_echr, echr)
            end
            if !(cchr in elite_cchr)
                push!(elite_cchr, cchr)
            end
        end
    end
    elite_echr, elite_cchr
end

function test_newpop(
    e::DualCGPGAEvo,
    elite_echr::Vector{Vector{Float64}},
    elite_cchr::Vector{Vector{Float64}}
)
    @test length(e.encoder_sympop) == e.encoder_config.n_population
    @test length(e.controller_sympop) == e.controller_config.n_population
    @test sum(e.elites_matrix) == e.n_elite
    # Test that elites are kept between generations (same chromosomes)
    for i in eachindex(elite_echr)
        @test elite_echr[i] == e.encoder_sympop[i].chromosome
    end
    for j in eachindex(elite_cchr)
        @test elite_cchr[j] == e.controller_sympop[j].chromosome
    end
    # Test that non elites have a close parent in previous generation
    matsize = size(e.fitness_matrix)
    @test e.fitness_matrix == -Inf * ones(matsize...)
end

function test_tournaments_ind(
    e::DualCGPGAEvo,
    elite_echr::Vector{Vector{Float64}},
    elite_cchr::Vector{Vector{Float64}},
    prev_echr::Vector{Vector{Float64}},
    prev_cchr::Vector{Vector{Float64}},
    comptype::String
)
    for esym in e.encoder_sympop
        if comptype == "in"
            # current chromosome was in previous pop
            @test esym.chromosome in prev_echr
        elseif comptype == "notin"
            if esym.chromosome in elite_echr
                # current chromosome was in previous pop
                @test esym.chromosome in prev_echr
            else
                # current chromosome was NOT in previous pop
                @test esym.chromosome ∉ prev_echr
            end
        end
    end
    for csym in e.controller_sympop
        if comptype == "in"
            @test csym.chromosome in prev_cchr
        elseif comptype == "notin"
            if csym.chromosome in elite_cchr
                @test csym.chromosome in prev_cchr
            else
                @test csym.chromosome ∉ prev_cchr
            end
        end
    end
end

cfg_filename = string(@__DIR__, "/dualcgpga_test.yaml")
game = "gravitar"
mcfg, ecfg, ccfg, reducer, bootstrap = IICGP.dualcgp_config(
    cfg_filename, game
)
logid = "2021-test-logid"
resdir = dirname(@__DIR__)
function mutate(ind::CGPInd, ind_type::String)
    if ind_type == "encoder"
        return goldman_mutate(ecfg, ind, init_function=IPCGPInd)
    elseif ind_type == "controller"
        return goldman_mutate(ccfg, ind)
    end
end
fit(e::CGPInd, c::CGPInd) = [e.chromosome[1] * c.chromosome[1]]
n_iter = 3

@testset "CGP GA Populate" begin
    for i in 1:n_iter
        evo = IICGP.DualCGPGAEvo(mcfg, ecfg, ccfg, fit, logid, resdir)
        evaluate(evo)
        elite_echr, elite_cchr = get_elites(evo)
        prev_echr = [esym.chromosome for esym in evo.encoder_sympop]
        prev_cchr = [csym.chromosome for csym in evo.controller_sympop]
        populate(evo)
        test_newpop(evo, elite_echr, elite_cchr)
        test_tournaments_ind(evo, elite_echr, elite_cchr, prev_echr, prev_cchr, "notin")
    end
end

function mutate(ind::CGPInd, ind_type::String)
    ind
end

@testset "CGP GA Populate without mutation" begin
    for i in 1:n_iter
        evo = IICGP.DualCGPGAEvo(mcfg, ecfg, ccfg, fit, logid, resdir)
        evaluate(evo)
        elite_echr, elite_cchr = get_elites(evo)
        prev_echr = [esym.chromosome for esym in evo.encoder_sympop]
        prev_cchr = [csym.chromosome for csym in evo.controller_sympop]
        populate(evo)
        test_newpop(evo, elite_echr, elite_cchr)
        test_tournaments_ind(evo, elite_echr, elite_cchr, prev_echr, prev_cchr, "in")
    end
end
