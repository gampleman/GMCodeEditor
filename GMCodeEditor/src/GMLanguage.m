//
//  GMLanguage.m
//  Code Editor
//
//  Created by Jakub Hampl on 13.07.13.
//  Copyright (c) 2013 Jakub Hampl. All rights reserved.
//

#import "GMLanguage.h"

@implementation GMLanguage

+ (NSDictionary *)languageAtURL:(NSURL *)url
{
  NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL: url];
  return [self languageWithDictionary: dict];
}

+ (NSDictionary *)languageAtPath:(NSString *)path
{
  NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
  return [self languageWithDictionary: dict];
}

+ (NSDictionary *)languageFromBundleWithName:(NSString *)name
{
  return [self languageAtPath: [[NSBundle mainBundle] pathForResource: name ofType: @"language"]];
}

+ (NSDictionary *)languageWithDictionary:(NSDictionary *)dict
{
  NSMutableDictionary *lang = [NSMutableDictionary dictionaryWithDictionary: dict];
  if (lang[@"grammar"]) {
    [lang setObject: [self processGrammarItem: lang[@"grammar"]] forKey: @"grammar"];
  }
  if (lang[@"paired_characters"]) {
    [lang setValue: [self processPairedCharacters: lang[@"paired_characters"]] forKey:@"paired_characters"];
  }
  return lang;
}

+ (id)processGrammarItem: (id)item
{
  if ([item isKindOfClass: [NSString class]]) {
    NSUInteger indexOfLastSeparator = [item rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString:@"/"] options: NSBackwardsSearch | NSLiteralSearch].location - 1;
    NSCharacterSet *opts = [NSCharacterSet characterSetWithCharactersInString: [item substringWithRange:NSMakeRange(indexOfLastSeparator, [item length] - indexOfLastSeparator)]];
    NSUInteger options = 0;
    if ([opts characterIsMember: 'i']) {
      //options = options | NSRegularExpressionCaseInsensitive;
    }
    if ([opts characterIsMember: 'x']) {
      options = options | NSRegularExpressionAllowCommentsAndWhitespace;
    }
    if ([opts characterIsMember: 's']) {
      options = options | NSRegularExpressionDotMatchesLineSeparators;
    }
    NSError *err;
    NSRegularExpression *ret = [NSRegularExpression regularExpressionWithPattern: [item substringWithRange: NSMakeRange(1, indexOfLastSeparator)] options: options error: &err];
    if (ret) {
      return ret;
    } else {
      NSLog(@"ERROR: %@", err);
      @throw err;
      return nil;
    }
  }
  if ([item isKindOfClass: [NSArray class]]) {
    GMOrderedDictionary *ret = [GMOrderedDictionary dictionary];
    for (id dict in item) {
      for (id key in dict) {
        [ret setValue: [self processGrammarItem: dict[key]] forKey: key];
      }
    }
    return ret;
  }
  if ([item isKindOfClass: [NSDictionary class]]) {
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    for (id key in item) {
      [ret setValue: [self processGrammarItem: item[key]] forKey: key];
    }
    return ret;
  }
  return item;
}

+ (NSDictionary *)processPairedCharacters: (NSString *)str
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity: [str length] / 2];
  for (int i = 0; i < [str length]; i += 2) {
    [dict setValue:[str substringWithRange:NSMakeRange(i + 1, 1)] forKey:[str substringWithRange:NSMakeRange(i, 1)]];
  }
  return dict;
}


@end



//
//  OrderedDictionary.m
//  OrderedDictionary
//
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

//#import "GMOrderedDictionary.h"

NSString *DescriptionForObject(NSObject *object, id locale, NSUInteger indent)
{
	NSString *objectString;
	if ([object isKindOfClass:[NSString class]])
	{
    //		objectString = (NSString *)[[object retain] autorelease];
    objectString = (NSString *)object;
	}
	else if ([object respondsToSelector:@selector(descriptionWithLocale:indent:)])
	{
		objectString = [(NSDictionary *)object descriptionWithLocale:locale indent:indent];
	}
	else if ([object respondsToSelector:@selector(descriptionWithLocale:)])
	{
		objectString = [(NSSet *)object descriptionWithLocale:locale];
	}
	else
	{
		objectString = [object description];
	}
	return objectString;
}

@implementation GMOrderedDictionary

- (id)init
{
	return [self initWithCapacity:0];
}

- (id)initWithCapacity:(NSUInteger)capacity
{
	self = [super init];
	if (self != nil)
	{
		dictionary = [[NSMutableDictionary alloc] initWithCapacity:capacity];
		array = [[NSMutableArray alloc] initWithCapacity:capacity];
	}
	return self;
}

//- (void)dealloc
//{
//	[dictionary release];
//	[array release];
//	[super dealloc];
//}

- (id)copy
{
	return [self mutableCopy];
}

- (void)setObject:(id)anObject forKey:(id)aKey
{
	if (![dictionary objectForKey:aKey])
	{
		[array addObject:aKey];
	}
	[dictionary setObject:anObject forKey:aKey];
}

- (void)removeObjectForKey:(id)aKey
{
	[dictionary removeObjectForKey:aKey];
	[array removeObject:aKey];
}

- (NSUInteger)count
{
	return [dictionary count];
}

- (id)objectForKey:(id)aKey
{
	return [dictionary objectForKey:aKey];
}

- (NSEnumerator *)keyEnumerator
{
	return [array objectEnumerator];
}

- (NSEnumerator *)reverseKeyEnumerator
{
	return [array reverseObjectEnumerator];
}

- (void)insertObject:(id)anObject forKey:(id)aKey atIndex:(NSUInteger)anIndex
{
	if ([dictionary objectForKey:aKey])
	{
		[self removeObjectForKey:aKey];
	}
	[array insertObject:aKey atIndex:anIndex];
	[dictionary setObject:anObject forKey:aKey];
}

- (id)keyAtIndex:(NSUInteger)anIndex
{
	return [array objectAtIndex:anIndex];
}

- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level
{
	NSMutableString *indentString = [NSMutableString string];
	NSUInteger i, count = level;
	for (i = 0; i < count; i++)
	{
		[indentString appendFormat:@"    "];
	}
	
	NSMutableString *description = [NSMutableString string];
	[description appendFormat:@"%@{\n", indentString];
	for (NSObject *key in self)
	{
		[description appendFormat:@"%@    %@ = %@;\n",
     indentString,
     DescriptionForObject(key, locale, level),
     DescriptionForObject([self objectForKey:key], locale, level)];
	}
	[description appendFormat:@"%@}\n", indentString];
	return description;
}

@end

