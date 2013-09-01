//
//  GMDocument.m
//  CSS Editor
//
//  Created by Jakub Hampl on 03.07.13.
//  Copyright (c) 2013 Jakub Hampl. All rights reserved.
//

#import "GMDocument.h"

@implementation GMDocument

- (id)init
{
    self = [super init];
    if (self) {
    // Add your subclass-specific initialization here.
    }
    return self;
}

- (NSString *)windowNibName
{
  // Override returning the nib file name of the document
  // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
  return @"GMDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
  [super windowControllerDidLoadNib:aController];
  if(_loadedText) [textView.textStorage setAttributedString: _loadedText];
  [textView setLanguage: @"css"];
  // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
  return [textView.textStorage.string dataUsingEncoding:NSUTF8StringEncoding];

}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
  NSMutableString *str = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  _loadedText = [[NSAttributedString alloc] initWithString: str];
  //[textView.textStorage setAttributedString: ];
  return YES;
}

@end
