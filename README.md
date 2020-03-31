[![Gem Version](https://badge.fury.io/rb/lm_docstache.svg)](http://badge.fury.io/rb/lm_docstache)

#LM-Docstache

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
```
{{#classroom when classroom == “Rm 202”}}
SHOW ME
{{/classroom}}
```
