# SPDX-License-Identifier: PMPL-1.0-or-later
module LicenseDB

export LicenseCategory, LICENSE_GROUPS

struct LicenseCategory
    name::String
    description::String
    identifiers::Vector{String}
end

const LICENSE_GROUPS = [
    LicenseCategory("Strong Copyleft", "Must share source code under same license (GPL family).", ["GPL-3.0", "AGPL-3.0", "GPL-2.0"]),
    LicenseCategory("Weak Copyleft", "Allows linking with non-free software (LGPL/MPL).", ["LGPL-2.1", "LGPL-3.0", "MPL-2.0"]),
    LicenseCategory("Permissive", "Minimal restrictions, very flexible (MIT/Apache).", ["MIT", "Apache-2.0", "BSD-3-Clause", "ISC"]),
    LicenseCategory("Public Domain / Unlicense", "Total freedom, no copyright retained.", ["Unlicense", "CC0-1.0", "WTFPL"]),
    LicenseCategory("Proprietary", "Restricted, commercial, or closed-source.", ["Proprietary"])
]

end # module
