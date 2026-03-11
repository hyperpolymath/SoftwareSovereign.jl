# SPDX-License-Identifier: PMPL-1.0-or-later
module Redundancy

using ..SoftwareSovereign

export check_redundancy, RedundancyReport

struct RedundancyReport
    category::Symbol
    apps::Vector{String} # List of app IDs
    count::Int
end

"""
    check_redundancy(installed_apps)
Identifies 'Bloat' by finding multiple apps in the same functional category.
"""
function check_redundancy(installed::Vector{AppMetadata})
    # Group by category
    cats = Dict{Symbol, Vector{String}}()
    for a in installed
        # We'd ideally pull these from the .desktop files or AppStream
        cat = determine_category(a)
        if !haskey(cats, cat) cats[cat] = String[] end
        push!(cats[cat], a.id)
    end
    
    reports = RedundancyReport[]
    for (cat, ids) in cats
        if length(ids) > 1
            push!(reports, RedundancyReport(cat, ids, length(ids)))
        end
    end
    return reports
end

function determine_category(a::AppMetadata)
    # Heuristic for demo purposes
    if occursin("code", lowercase(a.id)) || occursin("text", lowercase(a.id))
        return :Editor
    elseif occursin("calc", lowercase(a.id))
        return :Calculator
    elseif occursin("browser", lowercase(a.id))
        return :Browser
    else
        return :Generic
    end
end

end # module
