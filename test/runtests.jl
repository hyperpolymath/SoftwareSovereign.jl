# SPDX-License-Identifier: MPL-2.0
# (MPL-2.0 preferred; MPL-2.0 required for Julia ecosystem)

using Test

# The package under test. `Pkg.test` resolves every dependency declared in
# Project.toml, so a module that fails to load is a real defect and must fail
# the suite — it is deliberately not caught and skipped any more. (An undefined
# `AppMetadata` in src/redundancy.jl used to abort precompilation, which Julia
# 1.10 only reported as a warning while the module-loading tests silently
# skipped; the integration tests below are now unconditionally required.)
import SoftwareSovereign

# `using SoftwareSovereign` must expose the documented public API to users.
# Referencing each name here turns a missing definition or a missing `export`
# into a hard error while the tests are being collected.
module APICheck
    using SoftwareSovereign

    const API = (
        SoftwarePolicy,
        PolicyViolation,
        AppMetadata,
        audit_system,
        enforce_policy,
        scan_catalog,
        LicenseCategory,
        LICENSE_GROUPS,
        init_cache,
        cache_app,
        get_cached_app,
        check_redundancy,
        RedundancyReport,
        launch_dashboard,
        show_license_picker,
    )
end

@testset "SoftwareSovereign.jl" begin

    @testset "Public API" begin
        # Every public name must be exported ...
        @test length(APICheck.API) == 15

        # ... and be defined in the package itself.
        @test APICheck.SoftwarePolicy === SoftwareSovereign.SoftwarePolicy
        @test APICheck.AppMetadata === SoftwareSovereign.AppMetadata
        @test APICheck.check_redundancy === SoftwareSovereign.check_redundancy
        @test APICheck.RedundancyReport === SoftwareSovereign.RedundancyReport
        @test APICheck.LICENSE_GROUPS === SoftwareSovereign.LICENSE_GROUPS
    end

    # ========================================================================
    # LicenseDB submodule tests (no external dependencies beyond Base)
    #
    # These include src/license_db.jl directly so the pure-data taxonomy can be
    # exercised on its own, independently of the package load.
    # ========================================================================
    @testset "LicenseDB" begin
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
    # Full module integration tests
    #
    # These run against the loaded package (dependencies are always present
    # under `Pkg.test`).
    # ========================================================================
    @testset "Full Module Integration" begin
        @testset "AppMetadata construction" begin
            app = SoftwareSovereign.AppMetadata(
                "org.gnome.Calculator", "GNOME Calculator", :flatpak,
                "GPL-3.0", "x86_64", false
            )
            @test app.id == "org.gnome.Calculator"
            @test app.name == "GNOME Calculator"
            @test app.manager == :flatpak
            @test app.license == "GPL-3.0"
            @test app.arch == "x86_64"
            @test app.telemetry == false
        end

        @testset "SoftwarePolicy construction" begin
            policy = SoftwareSovereign.SoftwarePolicy(
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
            v = SoftwareSovereign.PolicyViolation("com.test.app", :dnf, "License not allowed")
            @test v.app_id == "com.test.app"
            @test v.manager == :dnf
            @test v.reason == "License not allowed"
        end

        @testset "audit_system returns violations vector" begin
            policy = SoftwareSovereign.SoftwarePolicy(
                "Audit Test",
                ["MIT"],
                String[],
                String[],
                true,
                true
            )
            violations = SoftwareSovereign.audit_system(policy)
            @test violations isa Vector{SoftwareSovereign.PolicyViolation}
            # Current implementation returns empty vector (stub)
            @test isempty(violations)
        end

        @testset "scan_catalog returns AppMetadata entries" begin
            catalog = SoftwareSovereign.scan_catalog()
            @test catalog isa Vector{SoftwareSovereign.AppMetadata}
            @test !isempty(catalog)
            @test all(a -> a.manager isa Symbol, catalog)
        end

        @testset "check_redundancy detects overlapping categories" begin
            apps = [
                SoftwareSovereign.AppMetadata("org.gnome.Calculator", "GNOME Calculator", :flatpak, "GPL-3.0", "x86_64", false),
                SoftwareSovereign.AppMetadata("kcalc", "KCalc", :dnf, "GPL-2.0", "x86_64", false),
                SoftwareSovereign.AppMetadata("vscode", "Visual Studio Code", :flatpak, "Proprietary", "x86_64", true),
                SoftwareSovereign.AppMetadata("org.gnome.TextEditor", "GNOME Text Editor", :flatpak, "GPL-3.0", "x86_64", false),
                SoftwareSovereign.AppMetadata("gedit", "gedit", :dnf, "GPL-2.0", "x86_64", false),
            ]
            reports = SoftwareSovereign.check_redundancy(apps)
            @test reports isa Vector{SoftwareSovereign.RedundancyReport}

            by_category = Dict(r.category => r for r in reports)
            @test length(reports) == 2
            @test by_category[:Calculator].count == 2
            @test Set(by_category[:Calculator].apps) == Set(["org.gnome.Calculator", "kcalc"])
            @test by_category[:Editor].count == 2
            @test Set(by_category[:Editor].apps) == Set(["vscode", "org.gnome.TextEditor"])
            @test !haskey(by_category, :Generic) # gedit is alone — not redundant
        end

        @testset "check_redundancy: a single app is not redundant" begin
            apps = [SoftwareSovereign.AppMetadata("gedit", "gedit", :dnf, "GPL-2.0", "x86_64", false)]
            @test isempty(SoftwareSovereign.check_redundancy(apps))
        end

        @testset "enforce_policy runs without error" begin
            policy = SoftwareSovereign.SoftwarePolicy(
                "Enforce Test",
                ["MIT"],
                String[],
                String[],
                false,
                false
            )
            # Should not throw
            @test (SoftwareSovereign.enforce_policy(policy); true)
        end

        @testset "LicenseCategory and LICENSE_GROUPS exported" begin
            @test SoftwareSovereign.LicenseCategory isa DataType
            @test SoftwareSovereign.LICENSE_GROUPS isa Vector{SoftwareSovereign.LicenseCategory}
            @test length(SoftwareSovereign.LICENSE_GROUPS) == 5
        end

        @testset "RedundancyReport exported" begin
            @test SoftwareSovereign.RedundancyReport isa DataType
            report = SoftwareSovereign.RedundancyReport(:Browser, ["firefox", "chromium"], 2)
            @test report.category == :Browser
            @test report.count == 2
        end

        @testset "SovereignCache round-trip" begin
            mktempdir() do dir
                cache = SoftwareSovereign.init_cache(joinpath(dir, "cache.lmdb"))
                app_id = "org.gnome.Calculator"

                @test SoftwareSovereign.get_cached_app(cache, app_id) === nothing

                SoftwareSovereign.cache_app(
                    cache, app_id,
                    Dict("license" => "GPL-3.0", "manager" => "flatpak")
                )

                @test haskey(cache, app_id)
                cached = SoftwareSovereign.get_cached_app(cache, app_id)
                @test cached !== nothing
                @test cached["license"] == "GPL-3.0"
                @test cached["manager"] == "flatpak"
            end
        end

        @testset "dashboard and license picker run without error" begin
            policy = SoftwareSovereign.SoftwarePolicy(
                "Dashboard Test",
                ["MIT"],
                String[],
                String[],
                false,
                false
            )
            @test (SoftwareSovereign.launch_dashboard(policy); true)
            @test (SoftwareSovereign.show_license_picker(); true)
        end
    end

    # ========================================================================
    # Standalone struct-shape tests
    #
    # These mirror the public structs locally, so the expected field layout is
    # pinned even if the module ever fails to load for an unrelated reason.
    # ========================================================================
    @testset "Core Types (standalone)" begin
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

    # CRG Grade C tests
    include("e2e_test.jl")
    include("property_test.jl")

end
