# SPDX-License-Identifier: MPL-2.0
# (MPL-2.0 preferred; MPL-2.0 required for Julia ecosystem)
module SovereignCache

using LMDB
using JSON3

export init_cache, cache_app, get_cached_app

const CACHE_PATH = joinpath(homedir(), ".local", "share", "sovereign", "cache.lmdb")

"""
    init_cache([path]) -> LMDBDict{String,String}

Opens the LMDB environment used as the local software metadata cache, creating
the directory if needed. Defaults to `CACHE_PATH`
(`~/.local/share/sovereign/cache.lmdb`); pass `path` to use another location.
"""
function init_cache(path::AbstractString = CACHE_PATH)
    dir = String(path)
    mkpath(dir)
    return LMDBDict{String,String}(dir)
end

"""
    cache_app(cache, id, data)

Stores the metadata `data` (any `AbstractDict`) for the application `id` in the
LMDB cache, encoded as JSON.
"""
function cache_app(cache::LMDBDict{String,String}, id::String, data::AbstractDict)
    cache[id] = JSON3.write(data)
    return nothing
end

"""
    get_cached_app(cache, id) -> Union{Nothing, JSON3.Object}

Returns the cached metadata for `id`, decoded from JSON, or `nothing` when the
application is not in the cache.
"""
function get_cached_app(cache::LMDBDict{String,String}, id::String)
    json = get(cache, id, nothing)
    json === nothing && return nothing
    return JSON3.read(json)
end

end # module
