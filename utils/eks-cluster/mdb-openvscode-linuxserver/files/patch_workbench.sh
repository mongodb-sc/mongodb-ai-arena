#!/bin/bash

# Purge stale MongoDB extension connections from the browser-side storage layer.
#
# In web mode, OpenVSCode keeps extension globalState in the *browser*, not on the pod:
#   IndexedDB database "vscode-web-state-db-<id>", object store "ItemTable",
#   key "<publisher>.<name>" (here: mongodb.mongodb-vscode).
# The MongoDB extension saves user-added connections in that blob under
# GLOBAL_SAVED_CONNECTIONS, while their passwords live separately in localStorage.
#
# IndexedDB is keyed by origin, and the origin (<username>.<customer>.mongoarena.com)
# is stable across deployments — so tearing down and reprovisioning the cluster does
# NOT clear it. A connection from a previous deployment reappears, and because its
# metadata and its password sit in two independent stores, it can come back with an
# empty password ("Password cannot be empty").
#
# Fix: rewrite workbench.html so the stale entry is deleted *before* the workbench
# module is imported. The extension then activates with the pre-configured preset
# connection as its only connection.

set -e
set -o pipefail

echo_with_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

CONFIG_FILE="/home/workspace/scenario-config/enhanced-scenario-config.json"
PRECONFIGURE_MDB_CONNECTION="false"
if [ -f "$CONFIG_FILE" ]; then
    PRECONFIGURE_MDB_CONNECTION=$(jq -r '.vscode.preconfigure_mongodb_connection // false' "$CONFIG_FILE")
fi

if [ "$PRECONFIGURE_MDB_CONNECTION" != "true" ]; then
    echo_with_timestamp "Connection pre-configuration disabled, leaving workbench.html untouched"
    exit 0
fi

WORKBENCH_HTML="/app/openvscode-server/out/vs/code/browser/workbench/workbench.html"
MARKER="mdb-arena-purge-stale-connections"

if [ ! -f "$WORKBENCH_HTML" ]; then
    echo_with_timestamp "WARNING: $WORKBENCH_HTML not found, skipping stale-connection purge"
    exit 0
fi

if grep -q "$MARKER" "$WORKBENCH_HTML"; then
    echo_with_timestamp "workbench.html already patched, nothing to do"
    exit 0
fi

# The purge is asynchronous (IndexedDB has no sync API), so it cannot simply be
# injected as a blocking <script> — the workbench would race it. Instead the final
# module <script> is replaced by a classic script that awaits the purge and *then*
# dynamically imports the workbench. Relative script order is preserved: the NLS
# module tags above still execute first, and the workbench import now happens after.
PURGE_JS=$(mktemp)
cat > "$PURGE_JS" <<'PURGE'
	<!-- mdb-arena-purge-stale-connections -->
	<script>
		// Delete the MongoDB extension's persisted globalState so connections left in
		// this browser by a previous deployment of the same hostname cannot reappear.
		// The workbench is imported only once this settles, so the extension can never
		// observe the stale entry. Failures are swallowed on purpose: a broken purge
		// must never stop the IDE from loading.
		(function () {
			var KEY = 'mongodb.mongodb-vscode';
			var STORE = 'ItemTable';
			var DB_PREFIX = 'vscode-web-state-db-';

			function purgeDb(dbName) {
				return new Promise(function (resolve) {
					var req;
					try {
						req = indexedDB.open(dbName);
					} catch (e) {
						return resolve();
					}
					req.onerror = function () { resolve(); };
					req.onblocked = function () { resolve(); };
					req.onsuccess = function () {
						var db = req.result;
						try {
							if (!db.objectStoreNames.contains(STORE)) {
								db.close();
								return resolve();
							}
							var tx = db.transaction(STORE, 'readwrite');
							tx.objectStore(STORE).delete(KEY);
							tx.oncomplete = function () { db.close(); resolve(); };
							tx.onerror = function () { db.close(); resolve(); };
							tx.onabort = function () { db.close(); resolve(); };
						} catch (e) {
							try { db.close(); } catch (e2) {}
							resolve();
						}
					};
				});
			}

			function listDbNames() {
				// indexedDB.databases() is unsupported on some browsers (e.g. Firefox);
				// fall back to the database names the workbench is known to use.
				var fallback = [DB_PREFIX + 'global'];
				if (!indexedDB.databases) {
					return Promise.resolve(fallback);
				}
				return indexedDB.databases().then(function (dbs) {
					var names = dbs.map(function (d) { return d.name; })
						.filter(function (n) { return n && n.indexOf(DB_PREFIX) === 0; });
					return names.length ? names : fallback;
				}, function () {
					return fallback;
				});
			}

			// Give the purge a hard deadline so a hung IndexedDB cannot leave a blank IDE.
			function withTimeout(promise, ms) {
				return Promise.race([
					promise,
					new Promise(function (resolve) { setTimeout(resolve, ms); })
				]);
			}

			window._mdbArenaPurge = withTimeout(
				listDbNames().then(function (names) {
					return Promise.all(names.map(purgeDb));
				}).catch(function () {}),
				5000
			);
		})();
	</script>
	<script>
		// Import the workbench only after the purge settles (see above).
		window._mdbArenaPurge
			.catch(function () {})
			.then(function () {
				var url = new URL(
					'{{WORKBENCH_WEB_BASE_URL}}/out/vs/code/browser/workbench/workbench.js',
					window.location.origin
				).toString();
				return import(url);
			});
	</script>
PURGE

echo_with_timestamp "Patching workbench.html to purge stale MongoDB connections"

# Swap the workbench module tag for the purge + gated dynamic import.
if ! python3 - "$WORKBENCH_HTML" "$PURGE_JS" <<'PYEOF'
import sys

html_path, purge_path = sys.argv[1], sys.argv[2]

anchor = ('<script type="module" src="{{WORKBENCH_WEB_BASE_URL}}'
          '/out/vs/code/browser/workbench/workbench.js"></script>')

with open(html_path) as f:
    html = f.read()

if anchor not in html:
    sys.stderr.write('anchor script tag not found in workbench.html\n')
    sys.exit(1)

with open(purge_path) as f:
    replacement = f.read().rstrip('\n')

with open(html_path, 'w') as f:
    f.write(html.replace(anchor, replacement, 1))
PYEOF
then
    echo_with_timestamp "WARNING: could not patch workbench.html, continuing without stale-connection purge"
    rm -f "$PURGE_JS"
    exit 0
fi

rm -f "$PURGE_JS"
echo_with_timestamp "workbench.html patched successfully"
