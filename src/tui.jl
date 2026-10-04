# SPDX-License-Identifier: MPL-2.0
# (MPL-2.0 preferred; MPL-2.0 required for Julia ecosystem)
module SovereignTUI

# Core names come from the parent module, which defines them before this file is
# included; explicit imports keep the dependency visible and load-order safe.
using ..SoftwareSovereign: SoftwarePolicy, audit_system, scan_catalog
import ..LicenseDB: LICENSE_GROUPS
import ..Redundancy: check_redundancy

export launch_dashboard, show_license_picker

"""
    launch_dashboard(policy)
Starts an interactive terminal dashboard to view system health and violations.
"""
function launch_dashboard(p::SoftwarePolicy)
    println("\033[2J") # Clear screen
    println("╔══════════════════════════════════════════════════════════╗")
    println("║             SOFTWARE SOVEREIGN DASHBOARD                 ║")
    println("╚══════════════════════════════════════════════════════════╝")
    println(" Active Policy: $(p.name)")
    println(" Catalog: built-in demo data (scan_catalog() is a stub)")
    println("------------------------------------------------------------")

    # 1. Audit for Policy Violations
    violations = audit_system(p)
    if isempty(violations)
        println(" ✅ POLICY COMPLIANT")
    else
        println(" ❌ VIOLATIONS: $(length(violations))")
    end

    # 2. Audit for Redundancy (Bloat)
    # `scan_catalog` returns the built-in demo catalogue for now; `first` keeps
    # the dashboard working when that catalogue is empty or shorter than 3.
    installed = first(scan_catalog(), 3)
    redundancies = check_redundancy(installed)

    if !isempty(redundancies)
        println("\n ⚠️ REDUNDANCY ALERT (Bloat Detected):")
        for r in redundancies
            println("   • You have $(r.count) apps for $(r.category):")
            println("     ($(join(r.apps, ", ")))")
            println("     Suggestion: Do you really need all of these? 🤔")
        end
    end

    println("\n [A]udit Now  [E]nforce Policy  [L]icense Picker  [Q]uit")
end

"""
    show_license_picker()
Displays a menu of license categories to help the user build their policy.
"""
function show_license_picker()
    println("\n--- SELECT LICENSE CATEGORIES ---")
    for (i, cat) in enumerate(LICENSE_GROUPS)
        println(" [$i] $(cat.name) - $(cat.description)")
    end
    println(" [0] Finish Selection")

    println("\n(Pick multiple categories to automatically include all their licenses)")
end

end # module
