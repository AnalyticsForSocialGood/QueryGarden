(function() {
  const currentScript = document.currentScript;
  if (!currentScript || !currentScript.src) {
    return;
  }

  const sqlite3Dir = currentScript.src.replace(/[^/]*$/, "");
  self.sqlite3InitModuleState = self.sqlite3InitModuleState || Object.create(null);
  self.sqlite3InitModuleState.sqlite3Dir = sqlite3Dir;
  self.sqlite3InitModuleState.scriptDir = sqlite3Dir;
})();
