//
//  GMLanguage.h
//  Code Editor
//
//  Created by Jakub Hampl on 13.07.13.
//  Copyright (c) 2013 Jakub Hampl. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 GMLanguage is a class that loads a language used by the other components in this kit. Typically languages
 are stored in plist files with the extension `.language` and the language name as the name of the file.
 
 Languages are (currently) simple dictionaries, so it is easy to build them programatically. It is recomended to
 pass them through languageWithDictionary:, as this will do some processing steps and also allows for using more
 literals rather than allocating objects yourself (as some strings will be automatically compiled into regular 
 expression objects).
 
 @see LanguageReference
 */
@interface GMLanguage : NSObject

/** 
 @name Creating a language from a filesystem representation
 */
/** 
 Loads a language plist from a given URL.
 @param url The accessible url where to find the language declaration.
 @return Returns a new language dictionary instance if the file was found and parsed properly, otherwise nil.
 */
+ (NSDictionary *)languageAtURL: (NSURL *)url;
/**
 Loads a language plist from a given path.
 @param path The accessible filesystem path where to find the language declaration.
 @return Returns a new language dictionary instance if the file was found and parsed properly, otherwise nil.
 */
+ (NSDictionary *)languageAtPath: (NSString *)path;
/**
 Loads a language plist from the application bundle.
 
 This is a useful shorthand method when using the provided language bundlers as these will by default reside 
 in the applications resource folder and have the `.language` extension. This method thus allows to find such
 bundles simply by their language name.
 @param name The name of the language.
 @return Returns a new language dictionary instance if the file was found and parsed properly, otherwise nil.
 */
+ (NSDictionary *)languageFromBundleWithName: (NSString *)name;
/**
 @name Creating a language programatically
 */
/**
 Processes a dictionary, turning certain strings into regular expressions and also turning arrays of dictionaries
 into [ordered dictionaries](GMOrderedDictionary).
 
 Example of creating a language programatically:
 
     NSDictionary *css = @{
        @"grammar": @[
          @{@"comment": @"/\/\*[\w\W]*?\*\//"},
          @{@"atrule": @{
              @"pattern": @"/@[\w-]+?.*?(;|(?=\s*\{))/i",
              @"inside": @[
                  @{@"punctuation": @"/[;:]/g"}
              ]
          }}
        ]
     };
     NSDictionary *cssLanguage = [GMLanguage languageWithDictionary: css];
 
 Which would be roughly equivalent to doing (although this is implementation specific and may change):
    
     NSError *err;
     GMOrderedDictionary *grammar = [GMOrderedDictionary dictionary];
     [grammar setObject: [NSRegularExpression regularExpressionWithPattern: @"/\*[\w\W]*?\*\/" 
                                              options: 0 error: &err] forKey: @"comment"];
     [grammar setObject: @{@"pattern": [NSRegularExpression regularExpressionWithPattern: @"@[\w-]+?.*?(;|(?=\s*\{))" 
                                                            options: NSRegularExpressionCaseInsensitive error: &err] 
     // (I think you get the idea...)
     
     NSDictionary *cssLanguage = @{
        @"grammar" : grammar;
     }
 
 @param dict The language definition dictionary.
 @return Returns a new language dictionary.
 */
+ (NSDictionary *)languageWithDictionary: (NSDictionary *)dict;

@end

//------------------------------------------
// GMLanguage
//  Created by Matt Gallagher on 19/12/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software. Permission is granted to anyone to
//  use this software for any purpose, including commercial applications, and to
//  alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source
//     distribution.
//
// This class was altered by Jakub Hampl by adding a class prefix and made it ARC
// compatible.

#import <Cocoa/Cocoa.h>

@interface GMOrderedDictionary : NSMutableDictionary
{
	NSMutableDictionary *dictionary;
	NSMutableArray *array;
}

- (void)insertObject:(id)anObject forKey:(id)aKey atIndex:(NSUInteger)anIndex;
- (id)keyAtIndex:(NSUInteger)anIndex;
- (NSEnumerator *)reverseKeyEnumerator;

@end

