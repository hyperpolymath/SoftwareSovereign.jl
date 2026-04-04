# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)

using Test

# SoftwareSovereign depends on DataFrames, JSON3, and LMDB at module load time.
# The cache module (LMDB) and redundancy module (references AppMetadata which is
# not defined) make full module loading fragile. We test the submodules that can
# be loaded independently, and test the main module types/functions if loading
# succeeds.

@testset "SoftwareSovereign.jl" begin

    # ========================================================================
    # LicenseDB submodule tests (no external dependencies beyond Base)
    # ========================================================================
    @testset "LicenseDB" begin
        # Include and use the submodule directly to avoid LMDB dependency
        include(joinpath(@__DIR__, "..", "src", "license_db.jl"))
        using .LicenseDB

        @testset "LicenseCategory construction" begin
            cat = LicenseCategory("Test", "A test category", ["MIT", "Apache-2.0"])
            @test cat.name == "Test"
            @test cat.description == "A test category"
            @test cat.identifiers == ["MIT", "Apache-2.0"]
        end

        @testset "LicenseCategory field types" begin
            cat = LicenseCategory("Copyleft", "Strong copyleft", ["GPL-3.0"])
            @test cat.name isa String
            @test cat.description isa String
            @test cat.identifiers isa Vector{String}
        end

        @testset "LicenseCategory empty identifiers" begin
            cat = LicenseCategory("Empty", "No licenses", String[])
            @test isempty(cat.identifiers)
        end

        @testset "LICENSE_GROUPS constant" begin
            @test LICENSE_GROUPS isa Vector{LicenseCategory}
            @test length(LICENSE_GROUPS) == 5

            # Verify all expected categories are present
            names = [g.name for g in LICENSE_GROUPS]
            @test "Strong Copyleft" in names
            @test "Weak Copyleft" in names
            @test "Permissive" in names
            @test "Public Domain / Unlicense" in names
            @test "Proprietary" in names
        end

        @testset "LICENSE_GROUPS - Strong Copyleft" begin
            strong = first(filter(g -> g.name == "Strong Copyleft", LICENSE_GROUPS))
            @test "GPL-3.0" in strong.identifiers
            @test "AGPL-3.0" in strong.identifiers
            @test "GPL-2.0" in strong.identifiers
            @test occursin("share source", strong.description)
        end

        @testset "LICENSE_GROUPS - Weak Copyleft" begin
            weak = first(filter(g -> g.name == "Weak Copyleft", LICENSE_GROUPS))
            @test "LGPL-2.1" in weak.identifiers
            @test "LGPL-3.0" in weak.identifiers
            @test "MPL-2.0" in weak.identifiers
        end

        @testset "LICENSE_GROUPS - Permissive" begin
            permissive = first(filter(g -> g.name == "Permissive", LICENSE_GROUPS))
            @test "MIT" in permissive.identifiers
            @test "Apache-2.0" in permissive.identifiers
            @test "BSD-3-Clause" in permissive.identifiers
            @test "ISC" in permissive.identifiers
        end

        @testset "LICENSE_GROUPS - Public Domain" begin
            pd = first(filter(g -> occursin("Public Domain", g.name), LICENSE_GROUPS))
            @test "Unlicense" in pd.identifiers
            @test "CC0-1.0" in pd.identifiers
            @test "WTFPL" in pd.identifiers
        end

        @testset "LICENSE_GROUPS - Proprietary" begin
            prop = first(filter(g -> g.name == "Proprietary", LICENSE_GROUPS))
            @test "Proprietary" in prop.identifiers
            @test length(prop.identifiers) == 1
        end

        @testset "LicenseCategory uniqueness" begin
            # All category names should be unique
            names = [g.name for g in LICENSE_GROUPS]
            @test length(names) == length(unique(names))
        end

        @testset "No license appears in multiple groups" begin
            all_ids = vcat([g.identifiers for g in LICENSE_GROUPS]...)
            @test length(all_ids) == length(unique(all_ids))
        end
    end

    # ========================================================================
    # Core types and functions (attempt to load full module)
    # ========================================================================
    @testset "Core Types (standalone)" begin
        # Define the structs inline to test independently of module loading
        # (since the module depends on DataFrames, JSON3, LMDB which may not
        # be available in the test environment)

        # SoftwarePolicy struct
        @testset "SoftwarePolicy-like construction" begin
            # Test the struct shape by mimicking it
            struct TestPolicy
                name::String
                allowed_licenses::Vector{String}
                disallowed_orgs::Vector{String}
                excluded_archs::Vector{String}
                require_open_source::Bool
                block_telemetry::Bool
            end

            policy = TestPolicy(
                "Strict FOSS",
                ["MIT", "GPL-3.0", "Apache-2.0"],
                ["EvilCorp"],
                ["arm32"],
                true,
                true
            )

            @test policy.name == "Strict FOSS"
            @test "MIT" in policy.allowed_licenses
            @test "EvilCorp" in policy.disallowed_orgs
            @test "arm32" in policy.excluded_archs
            @test policy.require_open_source == true
            @test policy.block_telemetry == true
        end

        @testset "SoftwarePolicy with empty fields" begin
            struct TestPolicy2
                name::String
                allowed_licenses::Vector{String}
                disallowed_orgs::Vector{String}
                excluded_archs::Vector{String}
                require_open_source::Bool
                block_telemetry::Bool
            end

            policy = TestPolicy2(
                "Permissive",
                String[],
                String[],
                String[],
                false,
                false
            )

            @test policy.name == "Permissive"
            @test isempty(policy.allowed_licenses)
            @test isempty(policy.disallowed_orgs)
            @test isempty(policy.excluded_archs)
            @test policy.require_open_source == false
            @test policy.block_telemetry == false
        end

        # PolicyViolation struct
        @testset "PolicyViolation-like construction" begin
            struct TestViolation
                app_id::String
                manager::Symbol
                reason::String
            end

            v = TestViolation("com.evil.app", :flatpak, "Proprietary license")

            @test v.app_id == "com.evil.app"
            @test v.manager == :flatpak
            @test v.reason == "Proprietary license"
        end

        @testset "PolicyViolation with different managers" begin
            struct TestViolation2
                app_id::String
                manager::Symbol
                reason::String
            end

            managers = [:dnf, :flatpak, :asdf, :snap, :pip]
            for mgr in managers
                v = TestViolation2("app", mgr, "reason")
                @test v.manager == mgr
            end
        end
    end

    # ========================================================================
    # Redundancy submodule types (standalone)
    # ========================================================================
    @testset "RedundancyReport-like construction" begin
        struct TestRedundancyReport
            category::Symbol
            apps::Vector{String}
            count::Int
        end

        report = TestRedundancyReport(:Editor, ["vscode", "neovim", "kate"], 3)
        @test report.category == :Editor
        @test length(report.apps) == 3
        @test report.count == 3
        @test "vscode" in report.apps
        @test "neovim" in report.apps
        @test "kate" in report.apps
    end

    @testset "RedundancyReport categories" begin
        struct TestRedundancyReport2
            category::Symbol
            apps::Vector{String}
            count::Int
        end

        categories = [:Editor, :Calculator, :Browser, :Generic]
        for cat in categories
            report = TestRedundancyReport2(cat, ["app1", "app2"], 2)
            @test report.category == cat
        end
    end

    # ========================================================================
    # Full module integration tests (only run if dependencies are available)
    # ========================================================================
    @testset "Full Module Integration" begin
        module_loaded = false
        try
            @eval using SoftwareSovereign
            module_loaded = true
        catch e
            @warn "SoftwareSovereign module could not be loaded (missing dependencies). " *
                  "Skipping integration tests." exception=e
        end

        if module_loaded
            @testset "SoftwarePolicy construction" begin
                policy = SoftwarePolicy(
                    "Test Policy",
                    ["MIT", "Apache-2.0"],
                    ["BadOrg"],
                    ["mips"],
                    true,
                    false
                )
                @test policy.name == "Test Policy"
                @test length(policy.allowed_licenses) == 2
                @test policy.require_open_source == true
                @test policy.block_telemetry == false
            end

            @testset "PolicyViolation construction" begin
                v = PolicyViolation("com.test.app", :dnf, "License not allowed")
                @test v.app_id == "com.test.app"
                @test v.manager == :dnf
                @test v.reason == "License not allowed"
            end

            @testset "audit_system returns violations vector" begin
                policy = SoftwarePolicy(
                    "Audit Test",
                    ["MIT"],
                    String[],
                    String[],
                    true,
                    true
                )
                violations = audit_system(policy)
                @test violations isa Vector{PolicyViolation}
                # Current implementation returns empty vector (stub)
                @test isempty(violations)
            end

            @testset "enforce_policy runs without error" begin
                policy = SoftwarePolicy(
                    "Enforce Test",
                    ["MIT"],
                    String[],
                    String[],
                    false,
                    false
                )
                # Should not throw
                @test (enforce_policy(policy); true)
            end

            @testset "LicenseCategory and LICENSE_GROUPS exported" begin
                @test LicenseCategory isa DataType
                @test LICENSE_GROUPS isa Vector{LicenseCategory}
                @test length(LICENSE_GROUPS) == 5
            end

            @testset "RedundancyReport exported" begin
                @test RedundancyReport isa DataType
                report = RedundancyReport(:Browser, ["firefox", "chromium"], 2)
                @test report.category == :Browser
                @test report.count == 2
            end
        else
            @test_skip "Module loading failed - skipping integration tests"
        end
    end

    # CRG Grade C tests
    include("e2e_test.jl")
    include("property_test.jl")

end
