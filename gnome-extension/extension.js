// extension.js
const { Gio, GLib, St } = imports.gi;
const Main = imports.ui.main;

class SovereignSearchProvider {
    constructor() {
        this.appInfo = Gio.AppInfo.create_from_commandline(
            'julia', 'Sovereign Search', Gio.AppInfoCreateFlags.NONE
        );
    }

    getInitialResultSet(terms, callback, cancellable) {
        let query = terms.join(' ');
        let [success, stdout, stderr] = GLib.spawn_command_line_sync(
            `julia --project=/var/mnt/eclipse/repos/julia-ecosystem/packages/SoftwareSovereign.jl /var/mnt/eclipse/repos/julia-ecosystem/packages/SoftwareSovereign.jl/scripts/gnome-search-bridge.jl "${query}"`
        );

        if (success) {
            let results = JSON.parse(new TextDecoder().decode(stdout));
            callback(results.map(r => r.id));
        } else {
            callback([]);
        }
    }

    getResultMetas(ids, callback) {
        // In a real implementation, we'd cache the metadata from the search step
        callback(ids.map(id => ({
            id: id,
            name: id,
            description: 'License-Aware Software',
            createIcon: (size) => new St.Icon({ icon_name: 'system-software-install', icon_size: size })
        })));
    }

    activateResult(id) {
        // Open the app in Discover or Terminal
        GLib.spawn_command_line_async(`flatpak install ${id}`);
    }
}

function init() {}

function enable() {
    this._provider = new SovereignSearchProvider();
    Main.overview.viewSelector._searchResults._registerProvider(this._provider);
}

function disable() {
    Main.overview.viewSelector._searchResults._unregisterProvider(this._provider);
}
