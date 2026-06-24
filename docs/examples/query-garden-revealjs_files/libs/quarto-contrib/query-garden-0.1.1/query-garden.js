(function() {
  const isDatabaseReady = (database) => {
    return Boolean(
      database &&
      typeof database.execute === "function" &&
      typeof database.gatherTables === "function" &&
      "db" in database
    );
  };

  const databaseFor = (name) => {
    if (!name || !window.Sqlime || !window.Sqlime.db) {
      return null;
    }
    return window.Sqlime.db[name] || null;
  };

  const gardenDatabaseReady = (garden) => {
    return isDatabaseReady(databaseFor(garden.dataset.queryGardenDb));
  };

  const placeOutput = (garden, output) => {
    if (!garden || !output || output.dataset.queryGardenPlaced === "true") {
      return;
    }

    const location = garden.dataset.queryGardenOutputLocation || "below";
    output.dataset.queryGardenPlaced = "true";
    output.classList.add("query-garden-output");

    if (location === "fragment" || location === "column-fragment") {
      output.classList.add("fragment");
    }

    if (location === "slide") {
      output.classList.add("output-location-slide");
      garden.insertAdjacentElement("afterend", output);
      return;
    }

    if (location === "column" || location === "column-fragment") {
      const outputColumn = document.createElement("div");
      outputColumn.className = "column query-garden-output-column";
      if (location === "column-fragment") {
        outputColumn.classList.add("fragment");
        output.classList.remove("fragment");
      }
      outputColumn.appendChild(output);
      garden.appendChild(outputColumn);
      return;
    }

    garden.appendChild(output);
  };

  const findOutput = (garden) => garden.querySelector("div.sqlime-example");
  const runButtons = (garden) => garden.querySelectorAll(".sqlime-example > div:first-child > button");

  const queryResult = (garden) => {
    const output = findOutput(garden);
    return output ? output.querySelector(":scope > div:nth-child(2)") : null;
  };

  const showLoadingStatus = (garden) => {
    const result = queryResult(garden);
    if (!result || result.dataset.queryGardenLoadingStatus === "true") {
      return;
    }
    result.dataset.queryGardenLoadingStatus = "true";
    result.style.display = "";
    result.textContent = "SQLite is loading. Queries will be available shortly.";
  };

  const clearLoadingStatus = (garden) => {
    const result = queryResult(garden);
    if (!result || result.dataset.queryGardenLoadingStatus !== "true") {
      return;
    }
    result.dataset.queryGardenLoadingStatus = "false";
    result.style.display = "none";
    result.textContent = "";
  };

  const syncGardenReadyState = (garden) => {
    const ready = gardenDatabaseReady(garden);
    garden.classList.toggle("query-garden-db-loading", !ready);
    garden.classList.toggle("query-garden-db-ready", ready);

    runButtons(garden).forEach((button) => {
      button.disabled = !ready;
      button.setAttribute("aria-disabled", String(!ready));
      if (!ready) {
        button.title = "SQLite is still loading";
      } else if (button.title === "SQLite is still loading") {
        button.removeAttribute("title");
      }
    });

    if (ready) {
      clearLoadingStatus(garden);
    }
  };

  const syncAllReadyStates = (dbName) => {
    document.querySelectorAll("div.query-garden").forEach((garden) => {
      if (!dbName || garden.dataset.queryGardenDb === dbName) {
        syncGardenReadyState(garden);
      }
    });
  };

  const gardens = document.querySelectorAll("div.query-garden");

  gardens.forEach((garden) => {
    const existingOutput = findOutput(garden);
    if (existingOutput) {
      placeOutput(garden, existingOutput);
      syncGardenReadyState(garden);
      return;
    }

    const observer = new MutationObserver(() => {
      const output = findOutput(garden);
      if (output) {
        placeOutput(garden, output);
        syncGardenReadyState(garden);
        observer.disconnect();
      }
    });
    observer.observe(garden, { childList: true, subtree: true });
  });

  const revealGardens = document.querySelectorAll(".reveal div.query-garden");
  revealGardens.forEach((garden) => {
    const pre = garden.querySelector("pre.sourceCode");
    const code = garden.querySelector("code.sourceCode");
    if (pre && code && code.hasAttribute("contenteditable")) {
      pre.classList.remove("numberSource");
    }
  });

  document.addEventListener("sqlime-ready", (event) => {
    syncAllReadyStates(event.detail && event.detail.name);
  });

  document.addEventListener(
    "keydown",
    (event) => {
      if (!(event.ctrlKey || event.metaKey) || (event.keyCode !== 10 && event.keyCode !== 13)) {
        return;
      }

      const code = event.target.closest && event.target.closest(".query-garden code.sourceCode");
      if (!code) {
        return;
      }

      const garden = code.closest(".query-garden");
      if (!garden || gardenDatabaseReady(garden)) {
        return;
      }

      event.preventDefault();
      event.stopImmediatePropagation();
      showLoadingStatus(garden);
      syncGardenReadyState(garden);
    },
    true
  );
})();
