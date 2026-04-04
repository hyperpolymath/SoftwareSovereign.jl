# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# BenchmarkTools benchmarks for SoftwareSovereign.jl

using BenchmarkTools

include(joinpath(@__DIR__, "..", "src", "license_db.jl"))
using .LicenseDB

const SUITE = BenchmarkGroup()

SUITE["license_db"] = BenchmarkGroup()

SUITE["license_db"]["access_groups"] = @benchmarkable LICENSE_GROUPS

SUITE["license_db"]["iterate_groups"] = @benchmarkable begin
    for g in LICENSE_GROUPS
        length(g.identifiers)
    end
end

SUITE["license_db"]["lookup_strong_copyleft"] = @benchmarkable begin
    filter(g -> g.name == "Strong Copyleft", LICENSE_GROUPS)
end

SUITE["license_db"]["all_ids_flat"] = @benchmarkable begin
    vcat([g.identifiers for g in LICENSE_GROUPS]...)
end

SUITE["license_db"]["construct_category"] = @benchmarkable begin
    LicenseCategory("Test", "Description", ["MIT", "Apache-2.0", "GPL-3.0"])
end

SUITE["license_db"]["unique_check"] = @benchmarkable begin
    all_ids = vcat([g.identifiers for g in LICENSE_GROUPS]...)
    length(all_ids) == length(unique(all_ids))
end

if abspath(PROGRAM_FILE) == @__FILE__
    tune!(SUITE)
    results = run(SUITE, verbose=true)
    BenchmarkTools.save("benchmarks_results.json", results)
end
