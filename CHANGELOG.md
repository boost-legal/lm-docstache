# Changelog

## 3.0.10

#### Bug fixes

* Only try to access and set text node's "xml:space" attribute if the text node
  exists (in `LMDocstache::Document#flatten_text_blocks` private method).

## 3.0.9

#### Bug fixes

* Text nodes merged in paragraphs with problems through `fix_errors` private
  method have now the "xml:space" attribute preserved from now on.

## 3.0.8

#### Bug fixes

* Fix a bug on `usable_tags` method, so it now properly and expectedly
  includes conditional tag names that have its opening tag markup as the sole
  content of paragraphs (which represents conditional blocks where both
  opening and closing tags are in separate parapraghs sorrounding one or more
  paragraphs as its conditional block content).

## 3.0.7

#### Bug fixes

* Fix a bug on `usable_tag_names` method, so it now properly and expectedly
  includes conditional tag names as well, as before.

## 3.0.6

#### Bug fixes

* Fix bug on `LMDocstache::Docstache#unusable_tags` method, where `nil` could be
  passed to `broken_tags.deleted_at` call.

## 3.0.5

#### Bug fixes and improvements

* Improve the way broken tags are detected, making the algorithm wider in terms
  detecting broken tags, specially if the broken tag is the opening part of
  conditional tag blocks (which was being detected before these improvements).
* Improve the way the paragraphs with "unusable" tags are traversed and have
  their same-style texts merged (hence the "unusable" tags becoming usable). So,
  from now, `w:hyperlink` elements, for instance, are properly processed as
  well.

## 3.0.4
* Allow replacement `data` argument to be an `Array`. This feature allow to replace blocks
in a sequentially order following the sequence of matching blocks order.

## 3.0.3

### Bugfix

* Hide custom tags arguments was pushing blocks tags to end of paragraph. There are cases this approach
 doesn't work. I changed to be an ordered replacement when we match hide tags.
* Avoid to merge Tab tags on fix errors methods. This was causing unexpected document changes.  

## 3.0.2

### Bugfix

* Fix replacing tags related to hidden custom tags regexp formats. E.g. tab characters.

## 3.0.1

### Bugfix

* Fix Hide Custom Tag feature when document there is no text inside a w|r we
  can't split content.

## 3.0.0

## Breaking Changes
* Replaced Renderer `hide_custom_tags` options to be a `Hash` instead of `Array`.
  There are are edge cases which we want to replace the content on hide custom tags.
  All documentations can be followed on `Renderer` and `HideCustomTag` classes.

## 2.1.2

### Bugfix

* Giving a document there is no *rPr* tag we should add new *rPr* tag before 
  *t* tag.

## 2.1.1

### Improvements

* Hidden custom tags now follow your document background color. If there is no background defined
  we assume white font color.

## 2.1.0

#### Improvements

* Add new feature which you're able to "hide" matching RegExp rule with white font color.
  This change allows you to keep your content and don't loose locations of hidden tags.
  You can use it just adding `hide_custom_tags` list of RegExp options to `Document#render_file`.
* Added `Document#render_xml` options parameter so you can call it with more documents
  formatting possibilities.

## 2.0.2

### Improvements and bugfixes

* Fix a bug related to a bad empty text nodes handling approach inside
  `Document#flatten_paragraph` logic.

## 2.0.1

### Improvements and bugfixes

* Improve the approach on fixing errors around paragraphs that have tags through
  multiple `w:r` elements, by merging only `w:r` that have same styles.

## 2.0.0

### Breaking changes

* Remove `Document#role_tags` and `Document#unusable_role_tags` methods;
* Remove support for `:loop` block type;
* Delete internal classes `DataScope` and `Block`;
* Third parameter of `Renderer#render_file` has changed: it's not the boolean
  field `remove_role_tags` anymore, but the `render_options` with default set
  to `{}`, where there is only one option for it so far, which is
  `special_variable_replacements` (with default value also set to `{}`). For the
  possible values for this `Hash` check the explanation for it on top of
  `Parser#initialize`.

### Improvements and bugfixes

* Improve overall template parsing and evaluation, which makes conditional
  blocks parsing more stable, reliable and bug free. There were lots of bugs
  happening related to conditional blocks being ignored and not properly parsed.

## 1.3.10
* Fix close tag encoding bug.

## 1.3.9
* Fix bug on Renderer Class remove_role_tags method that was replacing the entire line instead of just the role tag.

## 1.3.8
* Fix bug on Renderer Class remove_role_tags method that wasn't replacing the roles.

## 1.3.7
* Fix bug on renderer returning invalid data.
* Refactor Renderer Class remove_role_tags method to standardize, following other remove methods.

## 1.3.6
* Change remove signature tags to be remove role tags.
* Fix method remove role tags to be following the new regexp rules.
* Remove not necessary unique_role_tag_names method.

## 1.3.5
* Replace signatures by roles. Add unique roles name collector.

## 1.3.4
* Change signature signs identifiers to be braces instead of brackets.

## 1.3.2
* Fix bug replacing signature tags accross xml nodes.

## 1.3.1
* Fix bug searching accross xml nodes for e-signature tags.

## 1.3.0
* Add support for e-signature tags

## 1.2.4
* Add support for pipe character in merge tags so we can use as a modifier for the context of merge tag.

## 1.2.3
* Fix issue where some paragraphs do not contain text as their first block. If this is the case, we just use the first block that does contain text.

## 1.2.2
* Remove uneccessary runtime dependency on active support.

## 1.2.1
* Fix inline conditional issues such as no support for multi conditionals.

## 1.2.0
* Add support for inline conditionals.
* Add some tests.

## 1.0.0
* Fork the Docstache codebase and rename all references to LMDocstache.

## 0.3.2
* [b3b66a0cd7ae67834cdbe7c18cefdb1498bcc5ab] I'm an idiot.  Fixed an error in the `Document#unusable_tags` method

## 0.3.1
* [2228ba727f8a2e3705fe223ce02b5e760c935572] Added `Document#unusable_tags` to list out tags that are not able to be interpolated due to being split across tags in the Document's XML

## 0.3.0
* [c841078f7d340c18323f05f0785e75cd560eed2c] Added ability to do tag interpolation in headers and footers.  The header/footer used is the header or footer from the first document passed into `Document.new()`

## 0.2.1
* [25b4c2e9e3dcb19b6fe9a255fec2c2bfd92029a6] Fixed a bug where a tag with regular expression characters could not be fixed with the `fix_errors` method

## 0.2.0

* [902d9890bee1a20a90377a94c3096a51781e8a24] You can access array elements with `[]`s within a `{{tag}}`
* [a36c4fefed763b6a54d15564e887fbcf3c3421e3] You can use conditions on loops to only loop over specific elements

## 0.1.0

* [08f09d1922e73ccaf17989a568deeb2ce0ebd4b8] Hash keys inside DataScope are symbolized

## 0.0.6

* [f945bc70ebb684f21e2488a3ad30c205bc05ddbb] Fixed a bug When two tags were inside one xml node, it would mistakenly report that there was an error when there wasn't.

## 0.0.5

* Fixed a bug that caused {{^tags}} to always show up as errors

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
