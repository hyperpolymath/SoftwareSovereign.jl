# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# E2E pipeline tests for SoftwareSovereign.jl

using Test

# Test the standalone LicenseDB submodule (no LMDB dependency)
include(joinpath(@__DIR__, "..", "src", "license_db.jl"))
using .LicenseDB

@testset "E2E Pipeline Tests" begin

    @testset "License group lookup pipeline" begin
        # Iterate all groups and verify structural integrity
        @test length(LICENSE_GROUPS) == 5

        all_ids = String[]
        for group in LICENSE_GROUPS
            @test group.name isa String
            @test !isempty(group.name)
            @test group.description isa String
            @test group.identifiers isa Vector{String}
            append!(all_ids, group.identifiers)
        end

        # No license should appear in more than one group
        @test length(all_ids) == length(unique(all_ids))
    end

    @testset "Known license classification lookup" begin
        known = Dict(
            "GPL-3.0"    => "Strong Copyleft",
            "AGPL-3.0"   => "Strong Copyleft",
            "MPL-2.0"    => "Weak Copyleft",
            "MIT"        => "Permissive",
            "Apache-2.0" => "Permissive",
            "Unlicense"  => "Public Domain / Unlicense",
            "Proprietary" => "Proprietary",
        )

        for (license, expected_group) in known
            group = first(filter(g -> license in g.identifiers, LICENSE_GROUPS))
            @test group.name == expected_group
        end
    end

    @testset "LicenseCategory construction and field types" begin
        cat = LicenseCategory("Test Group", "A test group for E2E", ["MIT", "Apache-2.0"])
        @test cat.name == "Test Group"
        @test cat.description isa String
        @test length(cat.identifiers) == 2
        @test "MIT" in cat.identifiers
    end

    @testset "Error handling: filter on empty license group" begin
        empty_group = LicenseCategory("Empty", "No licenses here", String[])
        @test isempty(empty_group.identifiers)
        matches = filter(id -> id == "MIT", empty_group.identifiers)
        @test isempty(matches)
    end

end
