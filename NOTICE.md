# Notices

Query Garden is derived from the MIT-licensed `interactive-sql` Quarto
extension by Shafayet Khan Shafee.

Query Garden vendors browser runtime assets from `sqlime@0.1.3` and
`@antonz/sqlite@3.40.0` so rendered documents can run SQLite without depending
on a CDN. The bundled SQLite WebAssembly JavaScript glue includes code from
Emscripten and SQLite; its upstream license notice is retained in
`_extensions/query-garden/resources/vendor/sqlite3.js`.

The original copyright notice is:

```text
MIT License

Copyright (c) 2023 Shafayet Khan Shafee

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
