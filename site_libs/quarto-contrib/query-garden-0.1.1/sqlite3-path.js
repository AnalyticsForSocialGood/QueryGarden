(function() {
  const dependencyDir = "site_libs/quarto-contrib/query-garden-0.1.1/";

  function asDirectory(url) {
    return new URL(url.replace(/[^/]*$/, ""), document.baseURI).href;
  }

  function fromCurrentScript() {
    const currentScript = document.currentScript;
    return currentScript && currentScript.src ? asDirectory(currentScript.src) : null;
  }

  function fromRenderedAsset() {
    const assets = document.querySelectorAll("script[src],link[href]");
    for (const asset of assets) {
      const url = asset.src || asset.href;
      const match = url && url.match(/^(.*\/site_libs\/quarto-contrib\/query-garden-[^/]+\/)/);
      if (match) {
        return match[1];
      }
    }
    return null;
  }

  function fromSqlimeDatabasePath() {
    const db = document.querySelector("sqlime-db[path]");
    const dbPath = db && db.getAttribute("path");
    if (!dbPath || /^[a-z][a-z0-9+.-]*:/i.test(dbPath) || dbPath.startsWith("#")) {
      return null;
    }

    const pathOnly = dbPath.split(/[?#]/)[0];
    const parts = pathOnly.split("/");
    const dataIndex = parts.indexOf("data");
    if (dataIndex < 0) {
      return null;
    }

    const prefix = parts.slice(0, dataIndex).join("/");
    const relativeDir = (prefix ? `${prefix}/` : "") + dependencyDir;
    return new URL(relativeDir, document.baseURI).href;
  }

  function fallbackFromPage() {
    return new URL(dependencyDir, document.baseURI).href;
  }

  function resolveSqlite3Dir() {
    return fromCurrentScript() || fromRenderedAsset() || fromSqlimeDatabasePath() || fallbackFromPage();
  }

  function applySqlite3Dir() {
    const sqlite3Dir = resolveSqlite3Dir();
    if (!sqlite3Dir) {
      return;
    }

    self.sqlite3InitModuleState = self.sqlite3InitModuleState || Object.create(null);
    self.sqlite3InitModuleState.sqlite3Dir = sqlite3Dir;
    self.sqlite3InitModuleState.scriptDir = sqlite3Dir;
  }

  applySqlite3Dir();

  if (typeof self.sqlite3InitModule === "function" && !self.sqlite3InitModule.__queryGardenPathPatched) {
    const sqlite3InitModule = self.sqlite3InitModule;
    const wrappedSqlite3InitModule = function(...args) {
      applySqlite3Dir();
      return sqlite3InitModule.apply(this, args);
    };

    Object.assign(wrappedSqlite3InitModule, sqlite3InitModule);
    wrappedSqlite3InitModule.__queryGardenPathPatched = true;
    self.sqlite3InitModule = wrappedSqlite3InitModule;
  }
})();
