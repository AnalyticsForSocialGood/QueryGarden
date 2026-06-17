# Query Garden

Query Garden is a Quarto extension for interactive SQL examples. It is a
Nakul R. Padalkar port of the MIT-licensed
[`interactive-sql`](https://github.com/shafayetShafee/interactive-sql)
extension by Shafayet Khan Shafee, wrapping the excellent
[`sqlime`](https://sqlime.org/about.html) browser SQL runtime.

## Installing

Install the extension into a Quarto project with:

```bash
quarto add AnalyticsForSocialGood/QueryGarden
```

This installs Query Garden under the `_extensions` directory. If your Quarto
project uses version control, check in that directory so the extension is
available anywhere the document is rendered.

Use a recent Quarto release. Query Garden requires Quarto `>=1.3.0`.

## Using

Add the filter and register one or more SQL databases:

```yaml
filters:
  - query-garden
query-garden:
  databases:
    - name: hr
      sql-file-path: "hr.sql"
```

The preferred form is a normal SQL code fence with Query Garden behavior in
chunk options:

````markdown
```{.sql}
#| query-garden: true
#| db: hr
#| dialect: postgresql
select * from regions;
```
````

This keeps the fence standardized across Quarto documents whose main engine is
R, Python, or plain markdown. The SQL block is not executed by the R/Python
engine; it is rendered as SQL and wired to sqlime in the browser.

You can also register a database directly on a chunk:

````markdown
```{.sql}
#| query-garden: true
#| db: hr-preview
#| sql-file-path: hr.sql
#| editable: false
#| dialect: mysql
select first_name, last_name
from employees
limit 5;
```
````

Use `#| dialect:` to ask Quarto/Pandoc for dialect-specific SQL highlighting.
Supported values are `sql`, `sqlite`, `mysql`, `mariadb`, `postgresql`,
`postgres`, and `pgsql`. Query execution still uses sqlime's SQLite runtime;
the dialect option controls syntax highlighting and display styling.

`sql-file-path` is preferred over the older `path` option so Query Garden does
not collide with more general Quarto or engine-level path settings. The older
`path`, `db-path`, and `database-path` spellings are still accepted as aliases.

For revealjs presentations, Query Garden also accepts Quarto's
`output-location` option. Supported values are `below`, `fragment`, `column`,
`column-fragment`, and `slide`:

````markdown
```{.sql}
#| query-garden: true
#| db: hr
#| output-location: column
select * from regions;
```
````

Quarto's native `output-location` processing applies to executable cells with
echoed code. Query Garden mirrors the revealjs classes and layout in the
browser because sqlime creates the SQL result interactively at runtime.

## Python And R Wrappers

Query Garden SQL blocks can also be generated from Python or R chunks. This is
useful when a notebook's main engine is Python or R, or when you want to keep
SQL snippets in separate files and emit them into the document.

The wrappers do not require PySpark, SparkR, or rspark. They only emit Query
Garden markdown; sqlime still runs SQLite in the browser after render.

Python:

````markdown
```{python}
#| output: asis
import sys
sys.path.append("_extensions/query-garden/resources/python")
from querygarden import emit_sql_block

emit_sql_block(
    "select * from regions;",
    db="hr",
    dialect="postgresql",
)
```
````

Python from a SQL file:

````markdown
```{python}
#| output: asis
from querygarden import emit_sql_block_from_file

emit_sql_block_from_file(
    "queries/regions.sql",
    db="hr",
    output_location="column",
)
```
````

R:

````markdown
```{r}
#| output: asis
source("_extensions/query-garden/resources/r/querygarden.R")

query_garden_emit_sql_block(
  "select * from regions;",
  db = "hr",
  dialect = "postgresql"
)
```
````

R from a SQL file:

````markdown
```{r}
#| output: asis
query_garden_emit_sql_block_from_file(
  "queries/regions.sql",
  db = "hr",
  output_location = "column"
)
```
````

The original class-based form remains supported for compatibility:

````markdown
```{.sql .interactive .hr}
select * from regions;
```
````

## Example

Render the included example from the repository root:

```bash
quarto render examples/query-garden.qmd
```

Because sqlime loads SQLite in the browser, preview the rendered HTML through a
local web server rather than opening it directly from the filesystem.

## Book Demo

The repository is configured as a Quarto book that renders to `docs/`, which
matches the GitHub Pages "deploy from a branch, `/docs` folder" publishing
mode:

```bash
quarto render
quarto render examples/query-garden-revealjs.qmd
```

The generated book includes `docs/index.html`, HTML examples, Python and R
wrapper chapters, a book chapter that links to the standalone revealjs deck, and
the sample SQL resources needed by the browser runtime. The publish workflow
copies the standalone revealjs deck into `docs/examples/` before deploying.

## Acknowledgements

Query Garden began as a port of `interactive-sql` and keeps its core idea:
wire Quarto SQL code blocks to sqlime so readers can run queries in the browser.
