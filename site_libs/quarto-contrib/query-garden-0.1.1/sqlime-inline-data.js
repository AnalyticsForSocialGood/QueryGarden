(function() {
  if (!self.SqlimeDb || !self.SqlimeDb.prototype || self.SqlimeDb.prototype.__queryGardenInlinePatched) {
    return;
  }

  const tablesQuery = `
select "name", "type", "sql"
from "sqlite_schema"
where "sql" not null
  and "type" == 'table'
order by "name"
`;
  const moduleOptions = { print: console.log, printErr: console.error };
  let sqlite3Promise = null;

  class InlineSqlDatabase {
    constructor(name, capi, db) {
      this.name = name;
      this.capi = capi;
      this.db = db;
      this.query = "";
      this.tables = [];
    }

    execute(sql) {
      if (!sql) {
        return null;
      }

      this.query = sql;
      const rows = [];
      this.db.exec({ sql, rowMode: "object", resultRows: rows });
      if (!rows.length) {
        return null;
      }

      return {
        columns: Object.getOwnPropertyNames(rows[0]),
        values: rows.map((row) => Object.values(row))
      };
    }

    each(sql, callback) {
      this.db.exec({ sql, rowMode: "object", callback });
    }

    gatherTables() {
      const rows = [];
      this.db.exec({ sql: tablesQuery, rowMode: "array", resultRows: rows });
      this.tables = rows.map((row) => row[0]);
      return this.tables;
    }
  }

  function sqlite3Module() {
    sqlite3Promise = sqlite3Promise || self.sqlite3InitModule(moduleOptions);
    return sqlite3Promise;
  }

  function inlineSqlFor(name, path) {
    const scripts = document.querySelectorAll('script[type="application/sql"][data-query-garden-db]');
    for (const script of scripts) {
      if (script.dataset.queryGardenDb === name) {
        return script.textContent || "";
      }
    }

    for (const script of scripts) {
      if (path && script.dataset.queryGardenPath === path) {
        return script.textContent || "";
      }
    }

    return null;
  }

  function databaseName(element, path) {
    if (element.getAttribute("name")) {
      return element.getAttribute("name");
    }

    if (!path) {
      return "untitled";
    }

    const parts = path.split("/");
    return parts[parts.length - 1] || "untitled";
  }

  function normalizeSql(sql) {
    return sql
      .replace(/\r\n?/g, "\n")
      .replace(/^CREATE\s+DATABASE\b.*;\s*$/gim, "")
      .replace(/^USE\b.*;\s*$/gim, "")
      .replace(/^LOCK\s+TABLES\b.*;\s*$/gim, "")
      .replace(/^UNLOCK\s+TABLES\s*;\s*$/gim, "")
      .replace(/^\/\*!\d+\s+.*?\*\/;\s*$/gm, "")
      .replace(/^\/\*!\d+\s+.*?\*\/\s*$/gm, "")
      .replace(/\\'/g, "''")
      .replace(/\bAUTO_INCREMENT\b/gi, "")
      .replace(/^\s*(UNIQUE\s+)?KEY\s+`?[^`(]+`?\s*\([^)]+\),?\s*$/gim, "")
      .replace(/\)\s*ENGINE\s*=\s*[^;]+;/gi, ");")
      .replace(/,\s*\n\s*\)/g, "\n)");
  }

  async function loadInlineDatabase(name, sql) {
    const sqlite3 = await sqlite3Module();
    const db = new sqlite3.oo1.DB();
    const database = new InlineSqlDatabase(name, sqlite3.capi, db);
    database.execute(normalizeSql(sql));
    database.query = "";
    database.gatherTables();
    return database;
  }

  const originalLoad = self.SqlimeDb.prototype.load;
  self.SqlimeDb.prototype.load = async function() {
    const path = this.getAttribute("path") || "";
    const name = databaseName(this, path);
    const sql = inlineSqlFor(name, path);

    if (sql == null) {
      return originalLoad.call(this);
    }

    this.loading(name);
    try {
      const database = await loadInlineDatabase(name, sql);
      this.success(database);
      return true;
    } catch (error) {
      this.error(name, error);
      throw error;
    }
  };

  self.SqlimeDb.prototype.__queryGardenInlinePatched = true;
})();
