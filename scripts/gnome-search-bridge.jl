#!/usr/bin/env julia
# scripts/gnome-search-bridge.jl
# This script is called by the GNOME Shell extension to get search results.

using LicensePicker

if length(ARGS) < 1
    println("[]")
    exit(0)
end

query = ARGS[1]
println(search_apps_json(query))
