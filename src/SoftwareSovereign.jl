# SPDX-License-Identifier: MPL-2.0
# (MPL-2.0 preferred; MPL-2.0 required for Julia ecosystem)
"""
    SoftwareSovereign

Software sovereignty assessment and digital autonomy metrics. Audits installed
software against configurable policies covering allowed licenses, blocked
organisations, architecture constraints, open-source requirements, and telemetry
controls. Includes license classification, redundancy checking, and a TUI dashboard.

# Key Features
- Policy-based system audit across DNF, Flatpak, and ASDF package managers
- License category database with sovereignty-aware groupings
- Application redundancy detection and reporting
- Interactive terminal dashboard via `launch_dashboard`

# Example
```julia
using SoftwareSovereign
policy = SoftwarePolicy("strict", ["MIT", "MPL-2.0"], [], [], true, true)
violations = audit_system(policy)
```
"""
module SoftwareSovereign

using DataFrames
using JSON3

# ---------------------------------------------------------------------------
# Core types and logic
#
# These are defined (and exported) *before* the submodule includes below.
# `Redundancy` and `SovereignTUI` refer to them in method signatures, and Julia
# resolves those names while the submodule is loaded — so a type or function
# defined further down the file is an `UndefVarError` at precompile time.
# ---------------------------------------------------------------------------

"""
    AppMetadata(id, name, manager, license, arch, telemetry)

Everything the policy engine, the redundancy check and the cache need to know
about one installed application.

# Fields
- `id::String`: package identifier (`"org.gnome.Calculator"`, `"gcc"`, …)
- `name::String`: human-readable name
- `manager::Symbol`: owning package manager (`:dnf`, `:flatpak`, `:asdf`, `:apt`, …)
- `license::String`: SPDX identifier, or `"Proprietary"` for closed source
- `arch::String`: architecture the package was built for (`"x86_64"`, `"aarch64"`, …)
- `telemetry::Bool`: whether the application reports usage by default
"""
struct AppMetadata
    id::String
    name::String
    manager::Symbol
    license::String
    arch::String
    telemetry::Bool
end

"""
    SoftwarePolicy(name, allowed_licenses, disallowed_orgs, excluded_archs, require_open_source, block_telemetry)

A declarative statement of what the user is willing to run: which licences are
acceptable, which organisations are not, which architectures are out of scope,
and whether open source and no-telemetry are hard requirements.
"""
struct SoftwarePolicy
    name::String
    allowed_licenses::Vector{String}
    disallowed_orgs::Vector{String}
    excluded_archs::Vector{String}
    require_open_source::Bool
    block_telemetry::Bool
end

"""
    PolicyViolation(app_id, manager, reason)

One installed application that does not satisfy a `SoftwarePolicy`, together
with the manager it came from and the human-readable reason it was flagged.
"""
struct PolicyViolation
    app_id::String
    manager::Symbol
    reason::String
end

"""
    DEMO_CATALOG

Built-in placeholder catalogue returned by [`scan_catalog`](@ref). The
dnf/flatpak/asdf backends (ROADMAP v0.2.0) are not implemented yet, so the
dashboard works against this fixed list instead of a real scan of the machine.
"""
const DEMO_CATALOG = AppMetadata[
    AppMetadata("org.gnome.Calculator", "GNOME Calculator", :flatpak, "GPL-3.0", "x86_64", false),
    AppMetadata("kcalc", "KCalc", :dnf, "GPL-2.0", "x86_64", false),
    AppMetadata("org.gnome.TextEditor", "GNOME Text Editor", :flatpak, "GPL-3.0", "x86_64", false),
    AppMetadata("gedit", "gedit", :dnf, "GPL-2.0", "x86_64", false),
    AppMetadata("org.mozilla.firefox", "Firefox", :flatpak, "MPL-2.0", "x86_64", true),
    AppMetadata("code", "Visual Studio Code", :dnf, "Proprietary", "x86_64", true),
]

"""
    scan_catalog() -> Vector{AppMetadata}

Returns the applications that [`audit_system`](@ref) and
[`launch_dashboard`](@ref) work on.

**Placeholder:** the real package-manager queries (`dnf`, `flatpak`, `asdf`) are
not implemented yet, so this returns a copy of the built-in demo catalogue
([`DEMO_CATALOG`](@ref)) rather than scanning the machine.
"""
scan_catalog() = copy(DEMO_CATALOG)

"""
    audit_system(policy::SoftwarePolicy) -> Vector{PolicyViolation}

Checks the installed applications against `policy` and returns one
`PolicyViolation` per non-compliant application.

**Stub:** the audit logic is not implemented yet, so this currently always
returns an empty vector; the interface and the violation type are final.
"""
function audit_system(p::SoftwarePolicy)
    violations = PolicyViolation[]
    # TODO(v0.2.0): scan DNF/Flatpak/ASDF, then compare each AppMetadata against
    # the policy — licence allow-list, disallowed organisations, excluded
    # architectures, open-source requirement, telemetry — pushing one
    # PolicyViolation per hit.
    return violations
end

"""
    enforce_policy(policy::SoftwarePolicy)

Applies `policy` to the system, removing, replacing or exempting the packages
that violate it.

**Stub:** reports that enforcement ran; the package-manager commands are not
wired up yet (see ROADMAP v0.2.0).
"""
function enforce_policy(p::SoftwarePolicy)
    println("Enforcing rules... 🛡️")
end

export SoftwarePolicy, PolicyViolation, AppMetadata
export audit_system, enforce_policy, scan_catalog

# ---------------------------------------------------------------------------
# Submodules
# ---------------------------------------------------------------------------

include("license_db.jl")
using .LicenseDB

include("cache.jl")
using .SovereignCache

include("redundancy.jl")
using .Redundancy

include("tui.jl")
using .SovereignTUI

# Re-export the public API provided by the submodules.
export LicenseCategory, LICENSE_GROUPS
export init_cache, cache_app, get_cached_app
export check_redundancy, RedundancyReport
export launch_dashboard, show_license_picker

end # module
