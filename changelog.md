# Changelog

## 0.0.4

* Rewrite of the Renderer class
* Conditional Blocks now work
* Loops now work

## 0.0.3

* Added ability to have nested tags like `{{purchase_order.number}}` through the
  use of the `Docstache::DataScope` class

## 0.0.2

* Fixed a bug that made appended documents not get appended to the *end* of a
  document
* Fixed a bug that made merged documents not open in Word.  This was caused due
  to the `section properties` tag in the xml getting used more than once, since
  each document had one.  Now only the first `sectPr` tag is kept.

## 0.0.1

* Initial release.  Still not working:
  * Nested tags `{{foo.bar}}`
  * Blocks (loops and conditiontals) `{{#foo}} ... {{/foo}}`
