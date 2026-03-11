# SPDX-License-Identifier: PMPL-1.0-or-later
module SovereignCache

using LMDB
using JSON3

export init_cache, cache_app, get_cached_app

const CACHE_PATH = joinpath(homedir(), ".local/share/sovereign/cache.lmdb")

"""
    init_cache()
Initializes the LMDB environment for fast software metadata lookup.
"""
function init_cache()
    mkpath(dirname(CACHE_PATH))
    env = LMDB.Environment(CACHE_PATH)
    return env
end

"""
    cache_app(env, app_data)
Stores application metadata in the LMDB cache.
"""
function cache_app(env, id::String, data::Dict)
    txn = LMDB.Transaction(env)
    db = LMDB.Database(txn, "apps")
    put!(txn, db, id, JSON3.write(data))
    commit!(txn)
    println("Cached: $id ⚡")
end

end # module
