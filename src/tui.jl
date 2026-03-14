# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
module SovereignTUI

using ..SoftwareSovereign
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
    println("------------------------------------------------------------")
    
    # 1. Audit for Policy Violations
    violations = audit_system(p)
    if isempty(violations)
        println(" ✅ POLICY COMPLIANT")
    else
        println(" ❌ VIOLATIONS: $(length(violations))")
    end

    # 2. Audit for Redundancy (Bloat)
    # Mock 'installed' list for demo
    installed = scan_catalog()[1:3] 
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
