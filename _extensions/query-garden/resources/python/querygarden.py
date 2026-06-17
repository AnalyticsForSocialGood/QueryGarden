from pathlib import Path


def _option_line(name, value):
    if value is None:
        return None
    if isinstance(value, bool):
        value = "true" if value else "false"
    return f"#| {name}: {value}"


def _fence(sql):
    fence = "```"
    while fence in sql:
        fence += "`"
    return fence


def sql_block(
    sql,
    *,
    db,
    sql_file_path=None,
    dialect=None,
    editable=None,
    output_location=None,
):
    """Return a Query Garden SQL block as markdown."""
    sql = str(sql).strip()
    fence = _fence(sql)
    options = [
        _option_line("query-garden", True),
        _option_line("db", db),
        _option_line("sql-file-path", sql_file_path),
        _option_line("editable", editable),
        _option_line("dialect", dialect),
        _option_line("output-location", output_location),
    ]
    option_text = "\n".join(option for option in options if option is not None)
    return f"{fence}{{.sql}}\n{option_text}\n{sql}\n{fence}"


def sql_block_from_file(query_file_path, **kwargs):
    """Read SQL from a file and return a Query Garden SQL block."""
    sql = Path(query_file_path).read_text(encoding="utf-8")
    return sql_block(sql, **kwargs)


def emit_sql_block(sql, **kwargs):
    """Print a Query Garden SQL block for Quarto cells using output: asis."""
    print(sql_block(sql, **kwargs))


def emit_sql_block_from_file(query_file_path, **kwargs):
    """Print a file-backed Query Garden SQL block for Quarto output: asis."""
    print(sql_block_from_file(query_file_path, **kwargs))

