DTMarkdownParser
================

[![Build Status](https://travis-ci.org/Cocoanetics/DTMarkdownParser.png?branch=develop)](https://travis-ci.org/Cocoanetics/DTMarkdownParser) [![Coverage Status](https://coveralls.io/repos/Cocoanetics/DTMarkdownParser/badge.png?branch=develop)](https://coveralls.io/r/Cocoanetics/DTMarkdownParser?branch=develop) 

This is a parser for markdown text that has the following design guidelines:

- No C-library dependency
- Event based similar to `NSXMLParser`
- Fully unit tested (incl. code coverage)
- Supporting Mac and iOS

The goal of this project is to be developed using test-driven development (TDD). This is fancy talk for "write the unit test first, then code the implementation".

At some not too distant time in the future to provide input for DTCoreText to allow generating `NSAttributedString`s from markdown. Therefore the delegate protocol uses metaphors similar to `DTHTMLParser`.


Contributing to the Project
---------------------------

Contributions are welcome provided you use the following work flow:

1. Create new unit tests for features you add, refer to `DTMarkdownparserTest`
2. All submissions as unit tested on Travis-CI and only merged if all existing unit tests pass
3. Please create an issue on GitHub before starting to code
4. Work on a feature branch named like **od/issue_123**.
5. Only submit pull requests against the develop branch
6. When in doubt, just ask

License
-------

This project is covered by a BSD 2-clause license. If you use it in a published app you have to either give credit to Cocoanetics in some sort of About screen. This requirement is lifted if you produre a Non-Attribution License from us.

Implemented
-----------

- Basic Text
- Emphasis (strong, em)
- Strikethrough
- Inline Code
- Indented Code
- Fenced Code
- Horizontal Rule
- Headers
- Hyperlinks (inline and reference)
- Images (inline and reference)
- Linebreaks Handling (GitHub versus Gruber)
- lists (ordered or unordered)
- lists (stacked)
- forced linking via angle brackets

To Do
-----

- auto linking of http URLs
- character escaping
- inline HTML (? should we ever do this ?)
- multiple-level quoting and code blocks
- additional useful markdown extensions
- proper reporting of applicable processed range of text, e.g. to use for syntax highlighting

Markdown References
-------------------

- John Gruber's [Markdown Syntax Documentation](http://daringfireball.net/projects/markdown/syntax)
- Stack Overflow's [Markdown Editing Help](http://stackoverflow.com/editing-help)
- Fletcher T. Penney's [MultiMarkdown Syntax Guide](https://github.com/fletcher/MultiMarkdown/wiki/MultiMarkdown-Syntax-Guide)
