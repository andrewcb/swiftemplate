# swiftemplate — a compile-time templating engine for Swift

__swiftemplate__ is a templating system which compiles to Swift code, and also a command-line utility for compiling template files. It is intended mainly for use with HTML or XML. The __swiftemplate__ compiler produces a Swift source code file consisting of several functions; each function corresponds to one template, accepts the template's arguments and returns a string containing the formatted output.  __swiftemplate__ was intended for generating HTML in server-side web applications, but its applications extend beyond this.

## The template syntax

Swiftemplate templates are just text files containing content (typically HTML), with additional directives to define templates and allow for iteration and optional sections, as well as inline expressions and Swift code blocks.  An example template is below:

```
%% template listItems(name: String, items: [String])

<h1>Items for <%= name %>
<%
let numItems = items.count
%>

%% if items.isEmpty
  <p>There are no items</p>
%% else if numItems > 50
  <p>There are too many items to list</p>
%% else
  <p>There are \(numItems) items</p>
  <ul>
  %% for item in items
    <li><%= item %></li>
  %% endfor
  </ul>
%% endif

%% endtemplate

```

Note that all content must be within a template; there may not be any content or directives outside of a `%% template` / `%% endtemplate` pair (with the exception of comments).

### Directives

Swiftemplate directives take up one line each, and start with the characters `%%`; there may not be any other content on the line other than whitespace. The directives are:

| Directives | Description |
| --- | --- |
| __%% template__ _name_(_args_) |  Must appear at the start of a template, and defines its name and arguments. This is directly translated to the Swift function the template compiles to. |
| __%% endtemplate__ | Appears at the end of a template definition; optional, though if present, allows multiple templates to be defined in one file. |
| __%% for__ _var_ __in__ _expr_ / __%% endfor__ | Iterates over an array of items (or any Swift `SequenceType`); the text between __for__ and __endfor__ directives is emitted once for each item. |
| __%% if__ _expr_ / __%% else if__ _expr_ / __%% else__ / __%% endif__ | Allows parts of the template to be conditionally evaluated. |

### Inline expressions

You can include the result of any Swift expression in the output by wrapping it in `<%=` (or `<%=!`) and `%>`. Expressions must be on the same line. By default, the template code generated for expressions wrapped in `<%= %>` will apply a transformation to the expression result, replacing HTML special characters with quoted versions (i.e., converting `<` and `>` to `&lt;` and `&gt;`); if you wish to insert the expression's result directly into the output without quoting (i.e., to allow HTML tags to be treated as such), start the expression with `<%=!` (note the exclamation point). HTML quoting can also be turned off globally by running the `swiftemplate` preprocessor with the `--no-htmlquote` command-line option. _Note that, for reasons of security, it is strongly recommended that any user-generated input displayed in a HTML template be HTML quoted._  

You can also use Swift's string interpolation (i.e., `\(expr)`), though this does no HTML quoting, and is restricted by Swift's syntax (for example, quotes are not permitted); if you wish to include more complex expressions in your templates, the `<%= %>` syntax is preferable.

HTML quoting uses an extension to `String` which adds a `.HTMLQuote` property. If your template uses HTML quoting, you will probably need to add the provided `String+HTMLQuote.swift` source file (in the `Runtime` directory of the Swiftemplate distribution) to the project using your compiled templates. See the ‘Runtime dependencies’ section below for more details.

### Code blocks

You may insert arbitrary code blocks in templates by placing them between the character sequences `<%` and `%>` (each of which must be on its own line). Any code in such a block will be inserted verbatim into the Swift function that is generated.  Code blocks may be useful for defining values with `let` or `var`.

### Comments

Comments at the top level (i.e., outside of a template declaration) may begin with a `//`. Any comments within a template declaration must begin with a `%% //`.

## Building the swiftemplate processor

On Linux, or using the Swift build tools, enter `swift build` in the project directory; this will generate an command-line executable at `.build/debug/swiftemplate`.

The enclosed Xcode project file will also build the executable, and additionally will run unit tests. 

## Running the swiftemplate processor

The `swiftemplate` command takes, on its command line, a list of template files to process, as well as an optional output file specified with the `-o` flag. If none is specified, it will emit the generated Swift code to standard output. A typical usage could look like:

```
swiftemplate -o userpage.swift userpage.template
```
or, to convert all templates in a directory to one Swift source file:

```
swiftemplate -o templates.swift Templates/*.template
```

Other optional arguments accepted by the `swiftemplate` command are:

* `--no-htmlquote` Do not quote HTML characters in inline expressions. Code generated with this switch will not require the `String+HTMLQuote.swift` extension to be present; this is probably not recommended if you're generating HTML and there may be any unsanitised user input passed to templates.

## The generated code

For each template, swiftemplate will generate a Swift function; this function has the name and takes the arguments specified in the `%% template` header and returns a `String` containing the formatted output of the template. For example, the following template:

```
%% template showContents(name: String, items: [String])
<h1>Contents of \(name)</h1>
<ul>
%% for item in items
  <li><%= item %></li>
%% endfor
</ul>
%% endtemplate
```

will produce a function that (if indented nicely) would look like:
```
func showContents(name: String, items: [String]) -> String {
    var _ℜ=[String]()
    _ℜ.append("<h1>Contents of \(name)</h1>\n<ul>")
    for item in items {
        _ℜ.append("<li>")
        _ℜ.append(String(item).HTMLQuote)
        _ℜ.append("</li>")
    }
    _ℜ.append("</ul>")
    return _ℜ.joinWithSeparator(" ")
}
```
(The functions internally use the variable `_ℜ` to accumulate the contents of the result; do not use this variable in your templates.)

### Runtime dependencies

If your template uses HTML quoting, you will need to add the `String+HTMLQuote.swift` source file (in the `Runtime` directory of the Swiftemplate distribution) to your code. (If you are using the templates in a [Malimbe](https://github.com/andrewcb/malimbe/) application, you can skip this step, as Malimbe includes the string extension.)

### Attribution

Swiftemplate was written by Andrew Bulhak, and is licenced under the Apache Licence.
