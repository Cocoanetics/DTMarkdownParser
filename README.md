DTMarkdownParser
================

[![Build Status](https://travis-ci.org/Cocoanetics/DTMarkdownParser.png?branch=develop)](https://travis-ci.org/Cocoanetics/DTMarkdownParser) [![Coverage Status](https://coveralls.io/repos/Cocoanetics/DTMarkdownParser/badge.png?branch=develop)](https://coveralls.io/r/Cocoanetics/DTMarkdownParser?branch=develop) 

This is a parser for Markdown-formatted text. It follows the following design guidelines:

- No C-library dependency
- Event-based, similar to `NSXMLParser`
- Fully unit-tested (incl. code coverage)
- Supporting OS X and iOS

It’s a goal for this project to be developed using “test-driven development” (TDD). This is fancy talk for “write the unit test first, then code the implementation”.

Another is to, at some point in the not-too-distant future, provide input for DTCoreText to allow generating `NSAttributedString`s directly from Markdown. Therefore the delegate protocol uses metaphors similar to those found in `DTHTMLParser`.


Contributing to the Project
---------------------------

Contributions are welcome, provided you use the following workflow:

1. Create new unit tests for features you add (see  `DTMarkdownparserTest` for examples)
2. All submissions are unit tested on Travis-CI and are only merged if all existing unit tests pass
3. Please create an issue on GitHub before starting to code
4. Work on a feature branch named like **your_name/issue_123**.
5. Only submit pull requests against the develop branch
6. When in doubt, just ask

License
-------

This project is covered by a BSD 2-clause license. If you use it in a published app, you have to give some form of credit to Cocoanetics (like on your About screen). This requirement is lifted if you procure a Non-Attribution License from us.

Implemented
-----------

- Basic Text
- Emphasis (strong, em)
- Strikethrough
- Inline Code
- Indented Code
- Fenced Code (GitHub-style)
- Horizontal Rule
- Headers
- Hyperlinks (inline and reference)
- Images (inline and reference)
- Linebreaks Handling (GitHub versus Gruber)
- Lists (ordered or unordered)
- Lists (stacked)
- Forced linking via angle brackets
- Automatic Linking of URLs (web and mail)

To Do
-----

- Character Escaping
- Inline HTML (? should we ever do this ?)
- Multi-level Quoting and Code Blocks
- Additional Useful Markdown Extensions:
	- MultiMarkdown Table support
- Proper Reporting of applicable processed range of text, e.g. to use for syntax highlighting

Markdown References
-------------------

- John Gruber’s [Markdown Syntax Documentation](http://daringfireball.net/projects/markdown/syntax)
- Stack Overflow’s [Markdown Editing Help](http://stackoverflow.com/editing-help)
- Fletcher T. Penney’s [MultiMarkdown Syntax Guide](https://github.com/fletcher/MultiMarkdown/wiki/MultiMarkdown-Syntax-Guide)
