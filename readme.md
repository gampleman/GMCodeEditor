# GMCodeEditor

This project is a code editing component for objective-C applications. My main motivation in writing this, was that for projects that need to edit code, but editing code isn't their sole purpose (i.e. you are not building an IDE), there should be a simple package that you link into your project, specify the class in interface builder and bam, you have something which is decent for writing code. This is the purpose of GMCodeEditor and its design philosophy.

## Features

- Syntax highlighted code
- Context-aware (somewhat) code completion
- Parenthesis matching
- Paired character support (e.g. type in `[`, get `]` typed automatically)
- Indentation commands
- Commands for toggling comments
- Line numbers
- Theme-able
- Well documented

## Subcomponents

GMCodeEditor has two subcomponents that are independent and may be used individually without anything else. The first is **GMSyntaxHighlighter**, a lightweight syntax highlighter written in objective-C and inspired by [prism.js](http://prismjs.com). It takes a string, a language description  and a theme and produces an NSAttributedString with appropriate attributes for syntax highlighting. It can also optionally produce html.

The other is **GMAutoCompleteTextView**, which is an NSTextView subclass that allows rather sophisticated autocompletion.

## Installation

GMCodeEditor is designed to be used with [CocoaPods](http://cocoapods.org). You can install it by adding `pod 'GMCodeEditor'` into your Podfile and running `$ pod install`. You can install the language files that are included in the project by adding `pod 'GMCodeEditor/LanguageSupport` to your pod file.

To install only GMSyntaxHighlighter put `pod 'GMCodeEditor/GMSyntaxHighlighter'` into your Podfile. To install GMAutoCompleteTextView add `pod 'pod 'GMCodeEditor/GMAutoCompleteTextView'`.

## Usage

The easiest way to use GMCodeEditor is to add a NSTextView somewhere in Interface Builder. Then change the class to GMCodeEditor. Finally in `awakeFromNib` call `setLanguage:` with the name of the language you want to be editing. No step three.

Well kind of. You need to have the appropriate language file included in your project, the initial release only contains one for CSS and one for Ruby. Writing a language file isn't difficult, but hopefully more will become available over time.

## Documentation

The aim of this project is to have well written documentation, which you can find at http://code.gampleman.eu/GMCodeEditor.

## Contributing

Contributions are very welcome, please use the issue tracker to file bugs or feature requests. Pull requests are especially welcome. I hope that people will contribute language files to this project which then everyone can use.

## License

The author of this project is [Jakub Hampl](http://gampleman.eu). 

The project is licensed under the MIT license. Attribution is welcome.