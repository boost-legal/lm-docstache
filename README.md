[![Gem Version](https://badge.fury.io/rb/lm_docstache.svg)](http://badge.fury.io/rb/lm_docstache)
![rspec](https://github.com/boost-legal/lm-docstache/workflows/rspec/badge.svg)

# LM-Docstache

Lawmatics' templating utility for generating dynamic docx files.

## Features

* Mustache-like data interpolation into Microsoft Word .docx files
  * This includes loops, and conditional blocks
* Merging together multiple documents (documents are joined by a page break)
* No more hassles with Word splitting up your tags across multiple XML tags. We gotcha.
* Error detection for word documents, just in case we don't gotcha.

## Conditionals

### Truthy
```
{{#true_cond}}
SHOW ME
{{/true_cond}}
```
```
{{#false_cond}}
DONT SHOW ME
{{/false_cond}}
```

### Falsy
```
{{^false_cond}}
SHOW ME
{{/false_cond}}
```
```
{{^true_cond}}
DONT SHOW ME
{{/true_cond}}
```

### If
Assume `classrooom = "Rm 202"`

```
{{#classroom == “Rm 202”}}
SHOW ME
{{/classroom}}
```
```
{{#classroom == "NON EXISTANT"}}
DONT SHOW ME
{{/classroom}}
```

Without Quotes:
```
{{#classroom == Rm 202}}
SHOW ME
{{/classroom}}
```

With Negation
```
{{^classroom == "NON EXISTANT"}}
SHOW ME
{{/classroom}}
```
```
{{^classroom == Rm 202}}
DONT SHOW ME
{{/classroom}}
```
