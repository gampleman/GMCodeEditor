//
//  GMCSSEditor.m
//  CSS Editor
//
//  Created by Jakub Hampl on 03.07.13.
//  Copyright (c) 2013 Jakub Hampl. All rights reserved.
//

#import "GMCodeEditor.h"
#import "GMLanguage.h"
#import "TETextUtils.h"


@implementation NSString (GMStringUtils)

+ (NSString *)stringWithRepetitions: (NSUInteger)rep ofString: (NSString *)s
{
  NSMutableString *ret = [NSMutableString stringWithCapacity: rep * s.length];
  for (uint i = 0; i < rep; i++) {
    [ret appendString: s];
  }
  return ret;
}

@end

@implementation GMCodeEditor

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self performSelector:@selector(setupLineViewAndStuff) withObject:nil afterDelay:0];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  
  self = [super initWithCoder:aDecoder];
	if (self != nil) {
    // what's the right way to do this?
    [self performSelector:@selector(setupLineViewAndStuff) withObject:nil afterDelay:0];
  }
  
  return self;
}

- (void)setupLineViewAndStuff {
  _lineNumberView = [[NoodleLineNumberView alloc] initWithScrollView:[self enclosingScrollView]];
  [[self enclosingScrollView] setVerticalRulerView:_lineNumberView];
  [[self enclosingScrollView] setHasHorizontalRuler:NO];
  [[self enclosingScrollView] setHasVerticalRuler:YES];
  [[self enclosingScrollView] setRulersVisible:YES];
  
  [[self textStorage] setDelegate:self];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChangeSelection:) name:NSTextViewDidChangeSelectionNotification object:self];
  
  
  //[self parseCode:nil];
  
  _syntaxHighlighter = [GMSyntaxHighlighter new];
  _syntaxHighlighter.language =  [GMLanguage languageFromBundleWithName: @"css"];
  GMTheme *theme = [GMTheme themeFromBundleWithName: @"okaida"];
  _syntaxHighlighter.theme = theme;
  [self setBackgroundColor: theme.defaultAttributes[NSBackgroundColorDocumentAttribute]];
  [self setInsertionPointColor: theme.defaultAttributes[NSForegroundColorAttributeName]];
  [[self textStorage] setAttributedString: [_syntaxHighlighter highlight: [self string]]];
  _tabWidth = 4;
  
}

- (void)autoInsertText:(NSString*)text {
  
  [super insertText:text];
  [self setLastAutoInsert:text];
  
}

#pragma mark - API

- (void)highlight
{
  //NSRange r = [self selectedRange];
//  NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithAttributedString: ];
//  [s addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Monaco" size:13] range:NSMakeRange(0, [s length])];
  NSAttributedString *s = [_syntaxHighlighter highlight: [self string]];
  [[self textStorage] setAttributedString: s];
  //[self setSelectedRange: r];
}

- (NSString *)selectedToken
{
  if ([[self string] length] > NSMaxRange(self.selectedRange) - 1) {
    return [self.attributedString attribute: @"GMToken" atIndex: NSMaxRange(self.selectedRange) - 1 effectiveRange: nil];
  } else {
    return nil;
  }
  
}

- (void)setLanguage:(id)lang
{
  if ([lang isKindOfClass: [NSString class]]) {
    _language = [GMLanguage languageFromBundleWithName: lang];
  } else {
    _language = lang;
  }
}

-(NSDictionary *)language
{
  return _language;
}


#pragma mark - UI Commands

-(IBAction)indent:(id)sender
{
  [self userIndentByNumberOfLevels: 1];
}

-(IBAction)dedent:(id)sender
{
  [self userIndentByNumberOfLevels: -1];
}

- (NSMutableString *)commentRange: (NSRange)r
{
  NSString *startMarker = _language[@"comments"][@"start"], *endMarker = _language[@"comments"][@"end"];
  NSString *commentString = [[self.textStorage string] substringWithRange:r];
  NSString *replacementString;
  // Find if it is already commented
  if ([commentString hasPrefix: startMarker]) {
    replacementString = [commentString substringFromIndex: [startMarker length]];
    if ([replacementString characterAtIndex: 0] == ' ') { // strip extra space
      replacementString = [replacementString substringFromIndex: 1];
    }
    if ([replacementString hasSuffix: endMarker]) {
      NSUInteger repI = replacementString.length - 2;
      if ([replacementString characterAtIndex: repI - 1] == ' ') {
        repI--;
      }
      replacementString = [replacementString substringToIndex: repI];
    }
  } else {
    replacementString = [NSString stringWithFormat:@"%@ %@ %@", startMarker, commentString, endMarker];
  }
  return [replacementString mutableCopy];
}

- (NSMutableString *)commentLine: (NSRange)r
{
  //NSRange r = [self selectionRangeForProposedRange:s granularity:NSSelectByParagraph];
  NSRange g = r;
  unsigned spaces = TE_numberOfLeadingSpacesFromRangeInString([self string], &g, (unsigned)_tabWidth);
  r.length -= spaces + 1;
  r.location += spaces;
  NSString *line = [[self string] substringWithRange: r];
  if ([line hasPrefix: _language[@"comments"][@"line"]]) {
    return [NSMutableString stringWithFormat: @"%@%@", [NSString stringWithRepetitions:spaces - 1 ofString:@" "], [line substringFromIndex: 2]];
  }
  return [NSMutableString stringWithFormat: @"%@%@ %@", [NSString stringWithRepetitions:spaces ofString:@" "], _language[@"comments"][@"line"], line];
}

-(IBAction)toggleComments:(id)sender
{
  NSRange s = [self selectedRange];
  NSTextStorage *textStorage = [self textStorage];
  NSMutableString *replacementString;
  NSRange r = s;
  if (s.length == 0) { // toggle current line
    // get current line
    r = [self selectionRangeForProposedRange:s granularity:NSSelectByParagraph];
    if (_language[@"comments"] && _language[@"comments"][@"line"]) {
      replacementString = [self commentLine: r];
      [replacementString appendString: @"\n"];
    } else if (_language[@"comments"] && _language[@"comments"][@"start"]) {
      NSRange g = r;
      unsigned spaces = TE_numberOfLeadingSpacesFromRangeInString([self string], &g, (unsigned)_tabWidth);
      r.length -= spaces + 1;
      r.location += spaces;
      replacementString = [self commentRange: r];
    }
  } else {
    if (_language[@"comments"] && _language[@"comments"][@"start"]) {
      replacementString = [self commentRange: r];
      s.length = replacementString.length;
    } else if (_language[@"comments"] && _language[@"comments"][@"line"]) {
      replacementString = [NSMutableString string];
      [[textStorage string] enumerateSubstringsInRange: s options: NSStringEnumerationByLines usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        [replacementString appendFormat:@"%@\n", [self commentLine: substringRange]];
      }];
    }
  }
  
  if ([self shouldChangeTextInRange:r replacementString:replacementString]) {
    [[textStorage mutableString] replaceCharactersInRange:r withString: replacementString];
    //[textStorage replaceCharactersInRange:charRange withAttributedString:newText];
    [self setSelectedRange:s];
    [self didChangeText];
  }

}

-(void)scrollToLine:(NSUInteger)num
{
  __block NSUInteger line = 0;
  __block NSUInteger charCount = 0;
  [[self string] enumerateSubstringsInRange: NSMakeRange(0, self.string.length) options:NSStringEnumerationByLines usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
    if (++line == num) {
      [self setSelectedRange:NSMakeRange(charCount,0)];
      [self scrollRangeToVisible:NSMakeRange(charCount,0)];
      *stop = YES;
    }
    charCount += enclosingRange.length;
  }];
}


#pragma mark - Text Utils Stuff
- (void)userIndentByNumberOfLevels:(int)levels {
  // Because of the way paragraph ranges work we will add spaces a final paragraph separator only if the selection is an insertion point at the end of the text.
  // We ask for rangeForUserTextChange and extend it to paragraph boundaries instead of asking rangeForUserParagraphAttributeChange because this is not an attribute change and we don't want it to be affected by the usesRuler setting.
  NSRange charRange = [[self string] lineRangeForRange:[self rangeForUserTextChange]];
  NSRange selRange = [self selectedRange];
  if (charRange.location != NSNotFound) {
    NSTextStorage *textStorage = [self textStorage];
    NSAttributedString *newText;
    
    unsigned indentWidth = (unsigned)_tabWidth;
    BOOL usesTabs = NO;
    
    selRange.location -= charRange.location;
    newText = TE_attributedStringByIndentingParagraphs([textStorage attributedSubstringFromRange:charRange], levels,  &selRange, [self typingAttributes], (unsigned)_tabWidth, indentWidth, usesTabs);
    
    selRange.location += charRange.location;
    if ([self shouldChangeTextInRange:charRange replacementString:[newText string]]) {
      [[textStorage mutableString] replaceCharactersInRange:charRange withString:[newText string]];
      //[textStorage replaceCharactersInRange:charRange withAttributedString:newText];
      [self setSelectedRange:selRange];
      [self didChangeText];
    }
  }
}





#pragma mark - GMAutoCompleteTextView overrides

- (id)triggerForCurrentPosition
{
  return [self selectedToken];
}

- (NSArray *)autocompletionListForTrigger: (id)trigger
{
  if(_autocompletes) {
    return _autocompletes[trigger];
  } else {
    _autocompletes = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"css" ofType: @"autocomplete"]];
    return _autocompletes[trigger];
  }
}

- (NSString *)textForObject: (id) object
{
  return object[@"title"];
}

-(NSString *)cellTypeForTrigger:(id)trigger object:(id)object
{
  return @"completionItem";
}

#pragma mark - NSTextView Overrides

- (void)insertTab:(id)sender {
  [self insertText: [NSString stringWithRepetitions: _tabWidth ofString: @" "]];
}

- (void) textStorageDidProcessEditing:(NSNotification *)note {
  [self highlight];
}


// Code partially adapted from JSTalk
- (void)insertText:(id)insertString {
  
  // make sure we're not doing anything fancy in a quoted string.
  if (NSMaxRange([self selectedRange]) < [[self textStorage] length] && [[[self textStorage] attribute:@"GMToken" atIndex:self.selectedRange.location effectiveRange: nil] isEqualToString: @"string"]) {
    [super insertText:insertString];
    return;
  }
  
  if ([[_language[@"paired_characters"] allValues] containsObject: insertString] && [_lastAutoInsert isEqualToString:insertString]) {
    
    NSRange nextRange   = [self selectedRange];
    nextRange.length = 1;
    
    if (NSMaxRange(nextRange) <= [[self textStorage] length]) {
      
      NSString *next = [[[self textStorage] mutableString] substringWithRange:nextRange];
      
      if ([[_language[@"paired_characters"] allValues] containsObject: next]) {
        // just move our selection over.
        nextRange.length = 0;
        nextRange.location++;
        [self setSelectedRange:nextRange];
        return;
      }
    }
  }
  [self setLastAutoInsert:nil];
  [super insertText:insertString];
  NSRange currentRange = [self selectedRange];
  NSRange r = [self selectionRangeForProposedRange:currentRange granularity:NSSelectByParagraph];
  BOOL atEndOfLine = (NSMaxRange(r) - 1 == NSMaxRange(currentRange));
  
  NSArray *keys = [_language[@"paired_characters"] allKeys];
  NSRange ir = [_language[@"indent_characters"] rangeOfString: insertString];
  
  if (atEndOfLine && ir.length == 1) {
    
    r = [self selectionRangeForProposedRange:currentRange granularity:NSSelectByParagraph];
    NSString *myLine = [[[self textStorage] mutableString] substringWithRange:r];
    
    NSMutableString *indent = [NSMutableString string];
    
    int j = 0;
    
    while (j < [myLine length] && ([myLine characterAtIndex:j] == ' ' || [myLine characterAtIndex:j] == '\t')) {
      [indent appendFormat:@"%C", [myLine characterAtIndex:j]];
      j++;
    }
    NSString *pair = @"";
    if ([keys containsObject: insertString]) {
      pair = _language[@"paired_characters"][insertString];
    }
    
    [self autoInsertText:[NSString stringWithFormat:@"\n%@%@\n%@%@", indent, [NSString stringWithRepetitions: _tabWidth ofString:@" "], indent, pair]];
    
    currentRange.location += [indent length] + 5;
    
    [self setSelectedRange:currentRange];
  } else if (atEndOfLine && [keys containsObject: insertString]) {
    
    [self autoInsertText:_language[@"paired_characters"][insertString]];
    [self setSelectedRange:currentRange];
    
  }
}
// Code partially adapted from JSTalk
- (void)insertNewline:(id)sender {
  if([self autocompletionIsActive]) {
    [super insertNewline:sender];
  } else {
    [super insertNewline:sender];
    NSRange r = [self selectedRange];
    if (r.location > 0) {
      r.location --;
    }
    
    r = [self selectionRangeForProposedRange:r granularity:NSSelectByParagraph];
    
    NSString *previousLine = [[[self textStorage] mutableString] substringWithRange:r];
    
    int j = 0;
    
    while (j < [previousLine length] && ([previousLine characterAtIndex:j] == ' ' || [previousLine characterAtIndex:j] == '\t')) {
      j++;
    }
    
    if (j > 0) {
      NSString *foo = [[[self textStorage] mutableString] substringWithRange:NSMakeRange(r.location, j)];
      [self insertText:foo];
    }

  }
  
}


- (BOOL)changeSelectedNumberByDelta:(NSInteger)d {
  NSRange r   = [self selectedRange];
  NSString *token = [self.attributedString attribute: @"GMToken" atIndex:r.location longestEffectiveRange:&r inRange:NSMakeRange(0, self.attributedString.length)];
  if ([token isEqualToString: @"number"]) {
    NSString *s = [[[self textStorage] mutableString] substringWithRange:r];
    NSInteger i = [s integerValue];
    NSString *newString = [NSString stringWithFormat:@"%ld", (long)(i+d)];
    
    if ([self shouldChangeTextInRange:r replacementString:newString]) { // auto undo.
      [[self textStorage] replaceCharactersInRange:r withString:newString];
      [self didChangeText];
      
      r.length = 0;
      [self setSelectedRange:r];
    }
    return YES;
  }
  return NO;
}


- (void)moveDown:(id)sender
{
  if (![self autocompletionIsActive]) {
    if ([self changeSelectedNumberByDelta: -1]) {
      return;
    }
  }
  [super moveDown:sender];
}
- (void)moveUp:(id)sender
{
  if (![self autocompletionIsActive]) {
    if ([self changeSelectedNumberByDelta: 1]) {
      return;
    }
  } 
  [super moveUp:sender];
}



/**
 Implements that wrong spelling is only checked in comments and strings.
 */
-(void)setSpellingState:(NSInteger)value range:(NSRange)charRange
{
  NSRange r;
  NSNumber *v = [self.attributedString attribute:@"GMSpellCheck" atIndex: charRange.location longestEffectiveRange: &r inRange:charRange];
  BOOL spellCheck = [v boolValue];
  if (spellCheck && NSEqualRanges(r, charRange)) {
    [super setSpellingState: value range:charRange];
  }
}

#pragma mark - Braces highlighting

#define IS_OPENING_BRACE(str) ([[_language[@"paired_characters"] allKeys] containsObject: [NSString stringWithCharacters: &str length: 1]])

#define IS_CLOSING_BRACE(str) ([[_language[@"paired_characters"] allValues] containsObject: [NSString stringWithCharacters: &str length: 1]])


// Code partially adapated from TextExtras
- (NSRange)findMatchingBraceForBraceRange: (NSRange)r
{
  NSRange matchRange = NSMakeRange(NSNotFound, 0);
  unichar selChar = [self.string characterAtIndex:r.location];
  unichar matchBrace;
  NSString *selString = [self.string substringWithRange:NSMakeRange(r.location, 1)];
  BOOL backwards;
  if ([[_language[@"paired_characters"] allKeys] containsObject: selString]) {
    backwards = NO;
    matchBrace = [_language[@"paired_characters"][selString] characterAtIndex: 0];
  } else if ([[_language[@"paired_characters"] allValues] containsObject: selString]) {
    backwards = YES;
    matchBrace = [[_language[@"paired_characters"] allKeysForObject: selString][0] characterAtIndex: 0];
  } else {
    return matchRange;
  }
  
  NSRange searchRange;
  if (backwards) {
    searchRange = NSMakeRange(0, r.location);
  } else {
    searchRange = NSMakeRange(NSMaxRange(r), [self.string length] - NSMaxRange(r));
  }
  
  BOOL done = NO;
  NSInteger stack = 1;
  NSInteger i;
  // Fill the buffer with a chunk of the searchRange
  // This loops over all the characters in buffRange, going either backwards or forwards.
  for (i = (backwards ? (searchRange.length - 1) : 0); (!done && (backwards ? (i >= 0) : (i < searchRange.length))); (backwards ? i-- : i++)) {
    unichar curString = [self.string characterAtIndex: i];
    // Now do the push or pop, if any
    if (curString == matchBrace) {
      if (--stack < 0) {
        // Might want to beep here?
        done = YES;
      } else if (stack == 0) {
        matchRange = NSMakeRange(i, 1);
        done = YES;
      }
    } else if (curString == selChar) {
      stack++;
    }
  }
  return matchRange;
}



                  
                  

- (void)textViewDidChangeSelection:(NSNotification *)notification {
  NSTextView *textView = [notification object];
  NSRange selRange = [textView selectedRange];
  //TEPreferencesController *prefs = [TEPreferencesController sharedPreferencesController];
  
  //if ([prefs selectToMatchingBrace]) {
//  if (YES) {
//    // The NSTextViewDidChangeSelectionNotification is sent before the selection granularity is set.  Therefore we can't tell a double-click by examining the granularity.  Fortunately there's another way.  The mouse-up event that ended the selection is still the current event for the app.  We'll check that instead.  Perhaps, in an ideal world, after checking the length we'd do this instead: ([textView selectionGranularity] == NSSelectByWord).
//    if ((selRange.length == 1) && ([[NSApp currentEvent] type] == NSLeftMouseUp) && ([[NSApp currentEvent] clickCount] == 2)) {
//      NSRange matchRange = TE_findMatchingBraceForRangeInString(selRange, [textView string]);
//      
//      if (matchRange.location != NSNotFound) {
//        selRange = NSUnionRange(selRange, matchRange);
//        [textView setSelectedRange:selRange];
//        [textView scrollRangeToVisible:matchRange];
//      }
//    }
//  }
//  
  //if ([prefs showMatchingBrace]) {
  if (YES) {
    NSRange oldSelRangePtr;
    
    [[[notification userInfo] objectForKey:@"NSOldSelectedCharacterRange"] getValue:&oldSelRangePtr];
    
    // This test will catch typing sel changes, also it will catch right arrow sel changes, which I guess we can live with.  MF:??? Maybe we should catch left arrow changes too for consistency...
    if ((selRange.length == 0) && (selRange.location > 0) && ([[NSApp currentEvent] type] == NSKeyDown) && (oldSelRangePtr.location == selRange.location - 1)) {
      NSRange origRange = NSMakeRange(selRange.location - 1, 1);
      unichar origChar = [[textView string] characterAtIndex:origRange.location];
      if (IS_CLOSING_BRACE(origChar)) {
        NSRange matchRange = [self findMatchingBraceForBraceRange: origRange];
        if (matchRange.location != NSNotFound) {
          
          // do this with a delay, since for some reason it only works when we use the arrow keys otherwise.
          dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
              [self showFindIndicatorForRange:matchRange];
            });
          });
        }
      }
    }
  }
}

@end


