//
//  GMCSSEditor.h
//  CSS Editor
//
//  Created by Jakub Hampl on 03.07.13.
//  Copyright (c) 2013 Jakub Hampl. All rights reserved.
//

#import "GMAutoCompleteTextView.h"
#import "NoodleLineNumberView.h"
#import "GMSyntaxHighlighter.h"

/**
 GMCodeEditor is a code editing component. In general it is designed to work
 as a drop in replacement for NSTextView with very little furhter configuration
 necessary. However you can tweak it into a fairly complex code editing component.
 
 ### Configuration notes
 
 Since the exact configuration of a code editor mostly depends on the language being edited, the bulk of the
 configuration goes into the [language file](LanguageReference), that GMLanguage is responsible for loading. Therefore 
 the easiest way how to change the behavior of this class is simply to modify these files and then load them with 
 -setLanguage:.
 
 ### Subclassing notes
 
 Notice that this class inherits from GMAutoCompleteTextView since it has autocompletion based on 
 language files. Therefore you can also override any of those methods, although be aware that GMCodeEditor
 provides a custom implementation of all the methods from the "Methods to consider overriding in subclasses" 
 section. Furthermore the class overrides many NSTextView methods as well as many NSTextStorageDelegate methods.
 
 Despite these warnings, the class is intended to be subclassed.
 */
@interface GMCodeEditor : GMAutoCompleteTextView
{
@private
  NoodleLineNumberView	*_lineNumberView;
  GMSyntaxHighlighter *_syntaxHighlighter;
  NSDictionary *_autocompletes;
  NSDictionary *_language;
}

- (NSString *)selectedToken;

/**
 @name Configuration of the editor
 */
/**
 The language definition that is currently being edited.
 @returns A dictionary of a language definition.
 @see GMLanguage
 */
- (NSDictionary *)language;
/**
 Set the language to use for editing and syntax highlighting.
 @param lang Either a string in which case [GMLanguage languageFromBundleWithName:] will be called, otherwise a dictionary which should be the language representation itself (prefferably constructed with GMLanguage class methods).
 */
- (void)setLanguage:(id)lang;
/**
 The number of spaces a tab press will insert and also the amount by which the indent: command will indent the code.
 */
@property NSUInteger tabWidth;

/**
 @name Text Editing Commands
 */
/**
 Indents the selected section of text or the current line.
 */
- (IBAction)indent:(id)sender;
/**
 Dedents the selected section of text or the current line by one level.
 */
- (IBAction)dedent:(id)sender;
/**
 Inspects the current selection and toggles comments.
 
 If all of the lines selected are commented, then the comments will be removed, otherwise comments will be added.
 
 If the selection is zero length, then the current line is considered the selection.
*/
- (IBAction)toggleComments:(id)sender;
/**
 Scrolls the completion view to the line given and sets the insertion point to the begening of that line.
 @param num The line number to scroll to.
*/
- (void)scrollToLine:(NSUInteger)num;

// private
@property (retain) NSString *lastAutoInsert;

  
@end
