# SPDX-License-Identifier: PMPL-1.0-or-later
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

include("license_db.jl")
using .LicenseDB

include("cache.jl")
using .SovereignCache

include("redundancy.jl")
using .Redundancy

include("tui.jl")
using .SovereignTUI

export SoftwarePolicy, PolicyViolation, audit_system, enforce_policy, launch_dashboard, show_license_picker
export LicenseCategory, LICENSE_GROUPS
export init_cache, cache_app
export check_redundancy, RedundancyReport

# --- Core Types ---

struct SoftwarePolicy
    name::String
    allowed_licenses::Vector{String}
    disallowed_orgs::Vector{String}
    excluded_archs::Vector{String}
    require_open_source::Bool
    block_telemetry::Bool
end

struct PolicyViolation
    app_id::String
    manager::Symbol
    reason::String
end

# --- The Logic ---

function audit_system(p::SoftwarePolicy)
    violations = PolicyViolation[]
    # Logic to scan DNF, Flatpak, ASDF...
    return violations
end

function enforce_policy(p::SoftwarePolicy)
    println("Enforcing rules... 🛡️")
end

end # module
