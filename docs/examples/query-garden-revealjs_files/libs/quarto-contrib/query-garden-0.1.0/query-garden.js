(function() {
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

  const gardens = document.querySelectorAll("div.query-garden");

  gardens.forEach((garden) => {
    const existingOutput = findOutput(garden);
    if (existingOutput) {
      placeOutput(garden, existingOutput);
      return;
    }

    const observer = new MutationObserver(() => {
      const output = findOutput(garden);
      if (output) {
        placeOutput(garden, output);
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
})();
