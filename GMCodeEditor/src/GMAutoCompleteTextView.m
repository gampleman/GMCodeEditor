#import "GMAutoCompleteTextView.h"


@implementation GMAutoCompleteTextView

#pragma mark - API

-(void)showAutocomplete
{
  if (![autocompleteWindow isVisible]) {
    NSRect r = [self firstRectForCharacterRange:[self selectedRange]];
    r.origin.y -= autocompleteWindow.frame.size.height + 5;
    [autocompleteWindow setFrameOrigin:r.origin];
    _autocompleteFilter = @"";
    
    filteredList = [NSMutableArray arrayWithArray:[self autocompletionListForTrigger: trigger]];
    
    [[self window] addChildWindow: autocompleteWindow ordered:NSWindowAbove];
  }
  NSRange r  = [self rangeForCurrentPosition];
  _autocompleteFilter = [[self string] substringWithRange: r];
  [self filterAutoCompletionList:_autocompleteFilter];
}


-(void) filterAutoCompletionList: (NSString *)filter
{
  filteredList = [NSMutableArray array];
  filter = [[[filter stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"@" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
  
  NSMutableArray *sortArr = [NSMutableArray array];
  NSUInteger i = 0;
  for (id obj in [self autocompletionListForTrigger:trigger]) {
    double score = [self item: obj matchesFilter: filter];
    if(score > 0.1) {
      
      [sortArr addObject: @{@"score": @(score), @"index": @(i), @"object": obj}];
      i++;
    }
  }
  [sortArr sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]]];
  
  filteredList = [sortArr valueForKey: @"object"];
  if ([filteredList count] == 0) {
    filter = @"";
    [autocompleteWindow orderOut:nil];
    return;
  }
  [autocompleteTable reloadData];
  [autocompleteTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
  NSRect frame = [autocompleteWindow frame];
  NSUInteger num = [filteredList count];
  NSUInteger origHeight = frame.size.height;
  CGFloat height = num * [autocompleteTable rowHeight] + 4;
  CGFloat y = autocompleteWindow.frame.origin.y + origHeight - height;
  
  [autocompleteWindow setFrame:NSMakeRect(frame.origin.x, y, frame.size.width, height) display:YES];
}

- (BOOL)autocompletionIsActive
{
  return [autocompleteWindow isVisible];
}

#pragma mark - Creating the UI

- (void)awakeFromNib
{
  [super awakeFromNib];
  if (! autocompleteWindow) {
    autocompleteWindow = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 280, 190) styleMask:NSUtilityWindowMask | NSNonactivatingPanelMask backing:NSBackingStoreBuffered defer:YES];
    // [autocompleteWindow setHidesOnDeactivate: YES];
    //  [autocompleteWindow setRestorable: YES];
    [autocompleteWindow setReleasedWhenClosed:NO];
    NSScrollView *sw = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 280, 190)];
    autocompleteTable = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 200, 190)];
    NSTableColumn *col1 = [[NSTableColumn alloc] initWithIdentifier:@"main"];
    [col1 setWidth: 280];
    [autocompleteTable addTableColumn: col1];
    [autocompleteTable setDelegate: self];
    [autocompleteTable setDataSource: self];
    [autocompleteTable setHeaderView: nil];
    [autocompleteTable setSelectionHighlightStyle: NSTableViewSelectionHighlightStyleSourceList];
    [sw setDocumentView: autocompleteTable];
    [sw setHasVerticalScroller: YES];
    [autocompleteWindow setContentView: sw];
    [autocompleteTable reloadData];
    //uiCreated = YES;
  }
}

#pragma mark - Table View Delegate


- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
  NSString *identifier = [self cellTypeForTrigger: trigger object: filteredList[row]];
  NSTableCellView *cell = [tableView makeViewWithIdentifier: identifier owner:self];
  if (cell == nil) {
    if ([identifier isEqualToString: @"__defaultCell"]) {
      return [self constructCellViewWithIdentifier: @"__defaultCell"];
    } else {
      NSNib *cellNib = [[NSNib alloc] initWithNibNamed: identifier bundle:nil];
      [autocompleteTable registerNib:cellNib forIdentifier: identifier];
      cell = [tableView makeViewWithIdentifier: identifier owner:self];
      if (cell == nil) {
        //@throw [NSException exceptionWithName:@"Cell not found" reason: [NSString stringWithFormat: @"You need to have a cell called '%@'", identifier] userInfo:nil];
        return [self constructCellViewWithIdentifier: identifier];
      }
      
      [autocompleteTable setRowHeight: [cell bounds].size.height];
    }
    //NSLog(@"tf value: %@, cw.objectValue: %@", cell.textField.value, cell.objectValue);
  }
  return cell;
}

- (NSTableCellView *)constructCellViewWithIdentifier: (NSString *)identifier
{
  NSTableCellView *cw = [[NSTableCellView alloc] initWithFrame: NSMakeRect(0, 0, 280, 30)];
  [cw setIdentifier: identifier];
  NSTextField *tf = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 280, 20)];
  [cw setTextField: tf];
  [tf setEditable: NO];
  [tf setBordered: NO];
  [tf setDrawsBackground: NO];
  [tf bind:@"value" toObject:cw withKeyPath:@"objectValue" options:nil];
  [cw addSubview: tf];
  return cw;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
  NSInteger base = [filteredList count];
  return base;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  return filteredList[row];
}

#pragma mark - Text View Customization

- (void)moveDown:(id)sender
{
  if ([autocompleteWindow isVisible]) {
    [autocompleteTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[autocompleteTable selectedRow] + 1] byExtendingSelection:NO];
    [autocompleteTable scrollRowToVisible:[autocompleteTable selectedRow]];
  } else {
    [super moveDown:sender];
  }
}
- (void)moveUp:(id)sender
{
  if ([autocompleteWindow isVisible]) {
    [autocompleteTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[autocompleteTable selectedRow] - 1] byExtendingSelection:NO];
    [autocompleteTable scrollRowToVisible:[autocompleteTable selectedRow]];
  } else {
    [super moveUp:sender];
  }
}


- (void)insertText:(id)insertString {
  [super insertText:insertString];
  trigger = [self triggerForCurrentPosition];
  if (trigger) {
    [self showAutocomplete];
  } else if ([autocompleteWindow isVisible]) {
    _autocompleteFilter = @"";
    [autocompleteWindow orderOut:nil];
  }
}

- (void)insertNewline:(id)sender {
  if ([autocompleteWindow isVisible]) {
    NSUInteger row = [autocompleteTable selectedRow];
    NSString *completion = [self textForObject: filteredList[row]];
    //NSUInteger pos = [self selectedRange].location;
    //NSString *str = [self string];
    //while (--pos > 0 && ![[str substringWithRange:NSMakeRange(pos, 1)] isEqualToString:@"@"]);
    [self replaceCharactersInRange:[self rangeForCurrentPosition] withString:completion];
    [autocompleteWindow orderOut:nil];
  } else {
    [super insertNewline:sender];
  }
}

- (void)deleteBackward:(id)sender {
  [super deleteBackward:sender];
  trigger = [self triggerForCurrentPosition];
  if (trigger) {
    [self showAutocomplete];
  } else if ([autocompleteWindow isVisible]) {
    _autocompleteFilter = @"";
    [autocompleteWindow orderOut:nil];
  }
}

- (void)cancelOperation:(id)sender
{
  if ([autocompleteWindow isVisible]) {
    _autocompleteFilter = @"";
    [autocompleteWindow orderOut:nil];
  } else if ([self triggerForCurrentPosition] > 0) {
    [self showAutocomplete];
  }
  //[super cancelOperation: sender];
}


#pragma mark - Default Implementations of Methods

- (NSString *)cellTypeForTrigger: (id)trig object: (id)object
{
  return trig;
}

- (id)triggerForCurrentPosition
{
  return @"__defaultCell";
}
- (NSArray *)autocompletionListForTrigger: (id)trigger
{
  return @[@"You should really override autocompletionListForTrigger:"];
}
- (NSRange)rangeForCurrentPosition
{
  NSUInteger pos;
  NSString *str = [self string];
  for (pos = [self selectedRange].location - 1; pos > 0; pos--) {
    NSString *sub = [str substringWithRange:NSMakeRange(pos, 1)];
    if ([sub isEqualToString:@" "] || [sub isEqualToString:@"\n"]) {
      pos++;
      break;
    }
  }
 
//  if ([self selectedRange].location < pos + 2) {
//    return NSMakeRange(pos, 0);
//  }
  return NSMakeRange(pos, [self selectedRange].location - (pos));
}

- (NSString *)textForObject: (id) object
{
  if ([object isKindOfClass: [NSString class]]) {
    return object;
  } else if ([object respondsToSelector:@selector(key)]) {
    return [object key];
  } else {
    return [object description];
  }
}

- (double)item: (id)item matchesFilter: (NSString *)filter
{
  NSString *itemString = [self textForObject: item];
  if ([itemString isEqualToString: filter]) {
    return 0.0;
  }
  if (self.matchingAlgorithm == GMMatchingDiceCoefficient) {
    return [self diceCoefficient: itemString and: filter];
  } else if (self.matchingAlgorithm == GMMatchingSubletters) {
    NSMutableString *re = [NSMutableString string];
    for (int i = 0; i < [filter length]-1; i++) {
      [re appendFormat:@"(%C)[^%C]*", [filter characterAtIndex: i], [filter characterAtIndex: i + 1]];
    }
    [re appendFormat:@"(%C)", [filter characterAtIndex: [filter length] - 1]];
    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern: re options:NSRegularExpressionCaseInsensitive error:nil];

    NSTextCheckingResult * matches = [reg firstMatchInString:itemString options:0 range:NSMakeRange(0, [itemString length])];
    if (matches) {
      NSUInteger score = 1;
      NSUInteger lastPosition = [matches rangeAtIndex: 0].location;
      for (int i = 1; i < [matches numberOfRanges]; i++) {
        score += [matches rangeAtIndex:i].location - lastPosition;
        lastPosition = [matches rangeAtIndex:i].location;
      }
      return (double)[filter length] / (double)score;
    } else {
      return 0.0;
    }

  } else { //GMMatchingPrefix is the default
    if ([itemString hasPrefix: filter]) {
      return 1.0;
    } else {
      return 0.0;
    }
  }
}

#pragma mark - Private Utility

/*
 * @see http://www.catalysoft.com/articles/strikeamatch.html
 */
- (double)diceCoefficient: (NSString *)string1 and: (NSString *)string2
{
  NSMutableArray *pairs1 = [NSMutableArray array];
  for (NSString *s in [string1 componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]) {
    for (int i = 0; i < [s length] - 1; i++) {
      [pairs1 addObject: [s substringWithRange:NSMakeRange(i, 2)]];
    }
  }
  
  NSMutableArray *pairs2 = [NSMutableArray array];
  for (NSString *s in [string2 componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]) {
    for (int i = 0; i < [s length] - 1; i++) {
      [pairs2 addObject: [s substringWithRange:NSMakeRange(i, 2)]];
    }
  }
  double intersection = 0;
  double both = (double)[pairs1 count] + (double)[pairs2 count];
  for (NSString *pair1 in pairs1) {
    for (int j = 0; j < [pairs2 count]; j++) {
      NSString *pair2 = pairs2[j];
      if ([pair1 isEqualToString: pair2]) {
        intersection += 2;
        [pairs2 removeObjectAtIndex: j];
      }
    }
  }
  
  return intersection / both;
}


@end