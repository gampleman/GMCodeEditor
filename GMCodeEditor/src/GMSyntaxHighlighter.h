//
//  GMSyntaxHighlighter.h
//  CSS Editor
//
//  Created by Jakub Hampl on 04.07.13.
//  Copyright (c) 2013 Jakub Hampl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GMTheme.h"


/**
GMSyntax highlighter is a fast objective C general purpose syntax highlighter. 
 
It generally takes a GMLanguage object, a theme dictionary, and a NSString as input
and produces a NSAttributedString as output.
 
This class is loosely based on the [prism.js](http://prismjs.com) syntax highlighter by [Lea Verou](http://lea.verou.me).

Sample usage:
 
    GMSyntaxHighlighter *highlighter = [[GMSyntaxHighlighter alloc] init];
    highlighter.language = [GMLanguage languageFromBundleWithName: @"css"];
    highlighter.theme = [GMTheme themeFormBundleWithName: @"light"];
    NSAttributedString *result = [highlighter highlight: @"h1 {\nfont: 90% Helvetica;\n}"];
 
The code is designed such, that you can use [NSAttributedString attribute:atIndex:effectiveRange:] with the custom 
attribute `"GMToken"` on the result to find what that part of the string was tokenized as.

 */
@interface GMSyntaxHighlighter : NSObject

/** @name Highlighting code */
/**
 The theme to use as for coloring the code.
 
 Defaults to a theme in the app bundle named `default`.
 */
@property (retain) GMTheme *theme;
/** The language definition to tokenize the code with.
 */
@property (retain) NSDictionary *language;

/**
 Highlights a string of source code.
 
 Make sure you first set an appropriate language and theme, otherwise you might not see much results.
 @param text The code that you wish to highlight.
 @return An attributed string where individual language elements have different formatting (like color) applied.
 */
- (NSAttributedString *)highlight: (NSString *)text;
/**
 Provides a list of tokens.
 
 This is a rather lower level method, which is useful for debuging purposes and also if you wish to do something else
 then just highlight a language, this is a general purpose tokenizer.
 
 Before usage make sure the `language` property has been set, preferably via one of GMLanguage class methods.
 @param text The code you wish to tokenize.
 @return Returns an array that contains NSStrings for pieces of code that were not matched to any token, or GMToken instances that are essentially tuples of a tokenType and a content, which is typically either a string or a list of tokens.
 */
- (NSArray *)tokenize: (NSString *)text;
/**
 Returns an HTML string from a previously highlighted string.
 
 You should use this like this:
 
     GMSyntaxHighlighter *sh = [[GMSyntaxHighlighter alloc] init];
     [sh setLanguage: [GMLanguage languageWithBundleName: @"css"]];
     NSAttributedString *as = [sh highlight: @"h1 { font-family: \"Helvetica\"; }"];
     NSString *html = [sh convertToHTML: as];
     html //=> @"<span class='selector'>h1</span> <span class='punctuation'>{</span> 
                <span class='property'>font-family</span> <span class='punctuation'>:</span>
                <span class='string'>&quot;Helvetica&quot;</span> <span class='punctuation'>;</span>
                <span class='punctuation'>}</span>"

 Note that to see any actual syntax highlighting, you also need to provide an appropriate CSS declaration.
@param as A previously highlighted attributed string.
@return An HTML string where tokens are set as class names on spans.
*/
- (NSString *)convertToHTML: (NSAttributedString *)as;

@end



@interface GMToken : NSObject

@property (retain) NSString *tokenType;
@property (retain) id content;

- (GMToken *)initWithToken: (NSString *)token inside: (id)inside;
- (NSUInteger)contentLength;

+ (NSAttributedString *)stringify: (id)token theme: (GMTheme *)theme;

@end

