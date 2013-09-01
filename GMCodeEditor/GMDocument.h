//
//  GMDocument.h
//  CSS Editor
//
//  Created by Jakub Hampl on 03.07.13.
//  Copyright (c) 2013 Jakub Hampl. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GMCodeEditor.h"

@interface GMDocument : NSDocument
{
  IBOutlet GMCodeEditor *textView;
  NSAttributedString *_loadedText;
}

@end
