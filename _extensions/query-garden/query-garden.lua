local stringify = pandoc.utils.stringify

local function trim(value)
  return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalize_key(key)
  return tostring(key or ""):gsub("-", "_")
end

local function strip_quotes(value)
  value = trim(value)
  local first = value:sub(1, 1)
  local last = value:sub(-1)
  if (first == '"' and last == '"') or (first == "'" and last == "'") then
    return value:sub(2, -2)
  end
  return value
end

local function html_attr(value)
  return tostring(value or "")
    :gsub("&", "&amp;")
    :gsub('"', "&quot;")
    :gsub("<", "&lt;")
    :gsub(">", "&gt;")
end

local function css_ident(value)
  return tostring(value or ""):gsub("[^%w_-]", "-")
end

local function read_bool(value, default)
  if value == nil or value == "" then
    return default
  end

  local normalized = trim(stringify(value)):lower()
  if normalized == "false" or normalized == "no" or normalized == "0" then
    return false
  end
  return true
end

local function read_meta_value(meta, key)
  if meta == nil then
    return nil
  end
  return meta[key]
end

local function read_text(value)
  if value == nil then
    return nil
  end
  local text = trim(stringify(value))
  if text == "" then
    return nil
  end
  return text
end

local function read_sql_file_path(value)
  if value == nil then
    return nil
  end

  return read_text(read_meta_value(value, "sql-file-path"))
    or read_text(read_meta_value(value, "sql_file_path"))
    or read_text(read_meta_value(value, "path"))
end

local function dirname(path)
  if path == nil then
    return nil
  end

  local dir = tostring(path):match("^(.*)[/\\][^/\\]*$")
  if dir == nil or dir == "" then
    return nil
  end
  return dir
end

local function join_path(dir, path)
  if dir == nil or dir == "" then
    return path
  end
  return dir .. "/" .. path
end

local function is_remote_path(path)
  return tostring(path or ""):match("^https?://") ~= nil
end

local function read_local_file(path)
  if path == nil or path == "" or is_remote_path(path) then
    return nil
  end

  local candidates = { path }
  if PANDOC_STATE ~= nil and PANDOC_STATE.input_files ~= nil and PANDOC_STATE.input_files[1] ~= nil then
    table.insert(candidates, join_path(dirname(PANDOC_STATE.input_files[1]), path))
  end

  for _, candidate in ipairs(candidates) do
    local file = io.open(candidate, "rb")
    if file ~= nil then
      local contents = file:read("*a")
      file:close()
      return contents
    end
  end

  quarto.log.warning("Query Garden could not inline SQL file '" .. path .. "'; falling back to URL loading.")
  return nil
end

local function html_script_text(value)
  return tostring(value or ""):gsub("</script", "<\\/script")
end

local function inline_sql_block(db)
  local sql = read_local_file(db.sql_file_path)
  if sql == nil then
    return nil
  end

  return '<script type="application/sql" data-query-garden-db="'
    .. html_attr(db.name)
    .. '" data-query-garden-path="'
    .. html_attr(db.sql_file_path)
    .. '">'
    .. html_script_text(sql)
    .. '</script>'
end

local function parse_chunk_options(text)
  local options = {}
  local kept = {}
  local reading_options = true

  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    local key = nil
    local value = nil

    if reading_options then
      key, value = line:match("^%s*#%|%s*([%w_-]+)%s*:%s*(.-)%s*$")
      if key == nil then
        key, value = line:match("^%s*%-%-%|%s*([%w_-]+)%s*:%s*(.-)%s*$")
      end
    end

    if key ~= nil then
      options[normalize_key(key)] = strip_quotes(value)
    else
      if trim(line) ~= "" then
        reading_options = false
      end
      table.insert(kept, line)
    end
  end

  return options, table.concat(kept, "\n")
end

local function option_value(attrs, options, names)
  for _, name in ipairs(names) do
    local normalized = normalize_key(name)
    if options[normalized] ~= nil then
      return options[normalized]
    end
    if attrs[name] ~= nil then
      return attrs[name]
    end
    if attrs[normalized] ~= nil then
      return attrs[normalized]
    end
  end
  return nil
end

local function has_class(classes, name)
  for _, class in ipairs(classes) do
    if class == name then
      return true
    end
  end
  return false
end

local function append_class(classes, class)
  if class == nil or class == "" or has_class(classes, class) then
    return
  end
  table.insert(classes, class)
end

local reserved_classes = {
  sql = true,
  sqlmysql = true,
  sqlpostgresql = true,
  interactive = true,
  ["query-garden"] = true,
  ["interactive-sql"] = true,
  sourceCode = true,
  cell = true,
  ["cell-code"] = true
}

local function database_class(classes, databases)
  local fallback = nil
  for _, class in ipairs(classes) do
    if databases.by_name[class] ~= nil then
      return class
    end
    if reserved_classes[class] ~= true and fallback == nil then
      fallback = class
    end
  end
  return fallback
end

local dialects = {
  mysql = {
    name = "mysql",
    label = "MySQL",
    language = "sqlmysql"
  },
  mariadb = {
    name = "mysql",
    label = "MySQL",
    language = "sqlmysql"
  },
  postgresql = {
    name = "postgresql",
    label = "PostgreSQL",
    language = "sqlpostgresql"
  },
  postgres = {
    name = "postgresql",
    label = "PostgreSQL",
    language = "sqlpostgresql"
  },
  pgsql = {
    name = "postgresql",
    label = "PostgreSQL",
    language = "sqlpostgresql"
  },
  sql = {
    name = "sql",
    label = "SQL",
    language = "sql"
  },
  sqlite = {
    name = "sqlite",
    label = "SQLite",
    language = "sql"
  }
}

local function read_dialect(attrs, options)
  local value = option_value(attrs, options, {
    "dialect",
    "sql-dialect",
    "sql_dialect",
    "query-garden-dialect",
    "query_garden_dialect"
  })

  if value == nil then
    return dialects.sql
  end

  local normalized = trim(value):lower():gsub("[^%w]", "")
  local dialect = dialects[normalized]
  if dialect == nil then
    quarto.log.warning("Query Garden does not recognize SQL dialect '" .. value .. "'; using generic SQL highlighting.")
    return dialects.sql
  end
  return dialect
end

local function apply_dialect_classes(cb, dialect)
  if dialect.language ~= "sql" then
    table.insert(cb.classes, 1, dialect.language)
  end
  append_class(cb.classes, "query-garden-sql")
  append_class(cb.classes, "query-garden-dialect-" .. dialect.name)
end

local output_locations = {
  below = "below",
  default = "below",
  fragment = "fragment",
  column = "column",
  columnfragment = "column-fragment",
  ["column-fragment"] = "column-fragment",
  slide = "slide"
}

local function read_output_location(attrs, options)
  local value = option_value(attrs, options, {
    "output-location",
    "output_location",
    "query-garden-output-location",
    "query_garden_output_location"
  })

  if value == nil then
    return "below"
  end

  local normalized = trim(value):lower()
  local compact = normalized:gsub("[_%s]+", "-")
  local location = output_locations[compact] or output_locations[compact:gsub("-", "")]
  if location == nil then
    quarto.log.warning("Query Garden does not recognize output-location '" .. value .. "'; using below.")
    return "below"
  end
  return location
end

local function ensure_html_deps()
  quarto.doc.add_html_dependency({
    name = "query-garden",
    version = "0.1.1",
    scripts = {
      {
        path = "resources/vendor/sqlite3.js"
      },
      {
        path = "resources/vendor/sqlite3-wasm-binary.js"
      },
      {
        path = "resources/vendor/sqlite3-path.js"
      },
      {
        path = "resources/vendor/sqlime-db.js"
      },
      {
        path = "resources/vendor/sqlime-inline-data.js"
      },
      {
        path = "resources/vendor/sqlime-examples.js"
      },
      {
        path = "resources/js/query-garden.js",
        afterBody = true
      }
    },
    stylesheets = { "resources/css/query-garden.css" },
    resources = { "resources/vendor/sqlite3.wasm" }
  })
end

local function add_database(databases, db)
  if db.name == nil or db.name == "" then
    return nil
  end

  local existing = databases.by_name[db.name]
  if existing ~= nil then
    if (existing.sql_file_path == nil or existing.sql_file_path == "") and db.sql_file_path ~= nil then
      existing.sql_file_path = db.sql_file_path
    end
    if db.editable ~= nil then
      existing.editable = db.editable
    end
    return existing
  end

  db.class = db.class or css_ident(db.name)
  if db.editable == nil then
    db.editable = true
  end

  databases.by_name[db.name] = db
  table.insert(databases.list, db)
  return db
end

local function add_meta_databases(databases, source)
  if source == nil then
    return
  end

  for _, value in ipairs(source) do
    add_database(databases, {
      name = read_text(read_meta_value(value, "name")),
      sql_file_path = read_sql_file_path(value),
      class = read_text(read_meta_value(value, "class")),
      editable = read_bool(read_meta_value(value, "editable"), true)
    })
  end
end

local function collect_databases(meta)
  local databases = { list = {}, by_name = {} }

  add_meta_databases(databases, read_meta_value(meta, "databases"))

  local query_garden = read_meta_value(meta, "query-garden") or read_meta_value(meta, "query_garden")
  add_meta_databases(databases, read_meta_value(query_garden, "databases"))

  return databases
end

local function should_transform(cb, options)
  if has_class(cb.classes, "interactive") or has_class(cb.classes, "query-garden") then
    return true
  end

  local enabled = option_value(cb.attributes, options, {
    "query-garden",
    "query_garden",
    "interactive"
  })
  if enabled ~= nil then
    return read_bool(enabled, false)
  end

  local has_database_option = option_value(cb.attributes, options, {
    "db",
    "database",
    "query-garden-db",
    "query_garden_db",
    "sql-file-path",
    "sql_file_path",
    "path",
    "db-path",
    "db_path",
    "database-path",
    "database_path"
  }) ~= nil

  return has_class(cb.classes, "sql") and has_database_option
end

local function transform_code_blocks(databases, examples)
  local example_count = 0

  return {
    CodeBlock = function(cb)
      local options, clean_text = parse_chunk_options(cb.text)

      if not should_transform(cb, options) then
        return nil
      end

      cb.text = clean_text

      local db_name = option_value(cb.attributes, options, {
        "db",
        "database",
        "query-garden-db",
        "query_garden_db"
      }) or database_class(cb.classes, databases)

      local sql_file_path = option_value(cb.attributes, options, {
        "sql-file-path",
        "sql_file_path",
        "path",
        "db-path",
        "db_path",
        "database-path",
        "database_path"
      })

      if db_name == nil then
        quarto.log.warning("Query Garden skipped an interactive SQL block without a database name.")
        return nil
      end

      local db = databases.by_name[db_name]
      if sql_file_path ~= nil then
        db = add_database(databases, {
          name = db_name,
          sql_file_path = sql_file_path,
          editable = read_bool(option_value(cb.attributes, options, { "editable" }), true)
        })
      end

      if db == nil or db.sql_file_path == nil then
        quarto.log.warning("Query Garden database '" .. db_name .. "' does not have a sql-file-path.")
      end

      local editable = read_bool(option_value(cb.attributes, options, { "editable" }), db == nil and true or db.editable)
      local dialect = read_dialect(cb.attributes, options)
      local output_location = read_output_location(cb.attributes, options)
      apply_dialect_classes(cb, dialect)

      example_count = example_count + 1
      local id = "query-garden-sql-" .. tostring(example_count)
      table.insert(examples, {
        id = id,
        db = db_name,
        editable = editable,
        dialect = dialect.name,
        output_location = output_location
      })

      local classes = {
        "query-garden",
        "interactive-sql",
        "query-garden-dialect-" .. dialect.name,
        "query-garden-output-location-" .. output_location
      }
      if output_location == "column" or output_location == "column-fragment" then
        table.insert(classes, "columns")
        table.insert(classes, "column-output-location")
      end

      local content = { cb }
      if output_location == "column" or output_location == "column-fragment" then
        content = {
          pandoc.Div(
            { cb },
            pandoc.Attr("", { "column", "query-garden-code-column" })
          )
        }
      end

      return pandoc.Div(
        content,
        pandoc.Attr(id, classes, {
          ["data-query-garden-db"] = db_name,
          ["data-query-garden-dialect"] = dialect.label,
          ["data-query-garden-output-location"] = output_location
        })
      )
    end
  }
end

local function append_sqlime_blocks(doc, databases, examples)
  for _, db in ipairs(databases.list) do
    local inline_sql = inline_sql_block(db)
    if inline_sql ~= nil then
      table.insert(doc.blocks, pandoc.RawBlock("html", inline_sql))
    end

    local db_html = '<sqlime-db name="'
      .. html_attr(db.name)
      .. '" path="'
      .. html_attr(db.sql_file_path)
      .. '"></sqlime-db>'
    table.insert(doc.blocks, pandoc.RawBlock("html", db_html))
  end

  for _, example in ipairs(examples) do
    local editable = example.editable and " editable" or ""
    local example_html = '<sqlime-examples db="'
      .. html_attr(example.db)
      .. '" selector="#'
      .. html_attr(example.id)
      .. ' pre code"'
      .. ' data-query-garden-target="'
      .. html_attr(example.id)
      .. '"'
      .. ' data-query-garden-output-location="'
      .. html_attr(example.output_location)
      .. '"'
      .. editable
      .. '></sqlime-examples>'
    table.insert(doc.blocks, pandoc.RawBlock("html", example_html))
  end
end

if quarto.doc.is_format("html:js") then
  function Pandoc(doc)
    local databases = collect_databases(doc.meta)
    local examples = {}

    doc = doc:walk(transform_code_blocks(databases, examples))

    if #examples > 0 then
      ensure_html_deps()
      append_sqlime_blocks(doc, databases, examples)
    end

    return doc
  end
end
