# RubyComp

Compile HTML Templates using Ruby. This tool can be used to compile multiple separate vanilla HTML, CSS and JS files and codes into fully functioning vanilla websites.

# Setup

- Make sure you have installed Ruby.

- Install the following dependencies

```
gem install sassc
gem install listen
gem install colorize
```

- Run RubyComp

```
$ ./rubycomp
```

- Open up the `build/` directory in Live Share.

# Structure

| Directory/File Name | Purpose                             |
| ------------------- | ----------------------------------- |
| `html/`             | Contains individual HTML pages.     |
| `js/`               | Contains individual JS code.        |
| `scss/`             | Contains individual stylesheets.    |
| `components/`       | Contains the individual components. |
| `main.rb`           | Ruby executable.                    |
| `build/`            | The output website.                 |

# Usage

## HTML

- Import JS files using `<JS>filename</JS>`
- Import SCSS using `<SCSS>filename</SCSS>`
- Import templates using `<C>filename</C>`
- Execute ruby using `<R>Code</R>`

## JS

- Import JS files using `import("filename")`
- Execute ruby using `ruby("code")`

## SCSS

- SCSS gets compiled to CSS.

## Components

- Components must have the extension `.xhtml`
