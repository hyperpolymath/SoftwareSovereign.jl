# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# Property-based invariant tests for SoftwareSovereign.jl

using Test

include(joinpath(@__DIR__, "..", "src", "license_db.jl"))
using .LicenseDB

@testset "Property-Based Tests" begin

    @testset "Invariant: all LICENSE_GROUPS have non-empty names and descriptions" begin
        for _ in 1:20   # deterministic, but loop confirms stability
            for group in LICENSE_GROUPS
                @test !isempty(group.name)
                @test !isempty(group.description)
            end
        end
    end

    @testset "Invariant: LicenseCategory identifiers are unique within group" begin
        for group in LICENSE_GROUPS
            @test length(group.identifiers) == length(unique(group.identifiers))
        end
    end

    @testset "Invariant: LicenseCategory with random identifiers preserves them" begin
        for _ in 1:50
            n = rand(1:10)
            ids = ["LIC-$(rand(1:9999))-$(i)" for i in 1:n]
            cat = LicenseCategory("Group-$(rand(1:9999))", "Description", ids)
            @test length(cat.identifiers) == n
            @test all(id -> id in cat.identifiers, ids)
        end
    end

    @testset "Invariant: total license count is stable across calls" begin
        counts = [sum(length(g.identifiers) for g in LICENSE_GROUPS) for _ in 1:20]
        @test length(unique(counts)) == 1
    end

    @testset "Invariant: each group name is unique" begin
        for _ in 1:20
            names = [g.name for g in LICENSE_GROUPS]
            @test length(names) == length(unique(names))
        end
    end

end
