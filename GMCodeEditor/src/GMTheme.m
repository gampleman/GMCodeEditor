//
//  GMTheme.m
//  Code Editor
//
//  Created by Jakub Hampl on 17.07.13.
//  Copyright (c) 2013 Jakub Hampl. All rights reserved.
//

#import "GMTheme.h"

@implementation GMTheme


+ (id)themeAtURL:(NSURL *)url
{
  NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL: url];
  return [[self alloc] initWithDictionary: dict];
}

+ (id)themeAtPath:(NSString *)path
{
  NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
  return [[self alloc] initWithDictionary: dict];
}

+ (id)themeFromBundleWithName:(NSString *)name
{
  return [self themeAtPath: [[NSBundle mainBundle] pathForResource: name ofType: @"theme"]];
}


- (GMTheme *)initWithDictionary: (NSDictionary *)dict
{
  if (self = [super init]) {
    _theme = [self processStyleItem: dict];
  }
  return self;
}


- (id)processStyleItem: (id)item
{
  if ([item isKindOfClass: [NSString class]] && [item characterAtIndex: 0] == '#') {
    return [self colorWithHexColorString: [item substringFromIndex: 1]];
  }
  
  if ([item isKindOfClass: [NSDictionary class]]) {
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    for (id key in item) {
      if ([key isEqualToString: NSFontAttributeName]) {
        [ret setValue: [self fontWithFontString: item[key]] forKey: key];
      } else {
        [ret setValue: [self processStyleItem: item[key]] forKey: key];
      }
    }
    return ret;
  }
  return item;
}


- (NSColor*)colorWithHexColorString:(NSString*)inColorString
{
  NSColor* result = nil;
  unsigned colorCode = 0;
  unsigned char redByte, greenByte, blueByte;
  
  if (nil != inColorString)
  {
    NSScanner* scanner = [NSScanner scannerWithString:inColorString];
    (void) [scanner scanHexInt:&colorCode]; // ignore error
  }
  redByte = (unsigned char)(colorCode >> 16);
  greenByte = (unsigned char)(colorCode >> 8);
  blueByte = (unsigned char)(colorCode); // masks off high bits
  
  result = [NSColor
            colorWithCalibratedRed:(CGFloat)redByte / 0xff
            green:(CGFloat)greenByte / 0xff
            blue:(CGFloat)blueByte / 0xff
            alpha:1.0];
  return result;
}

- (NSFont *)fontWithFontString: (NSString *)fontString
{
  NSScanner *scanner = [NSScanner scannerWithString: fontString];
  CGFloat size = 0;
  NSString *name;
  [scanner scanDouble: &size];
  [scanner scanString: @"pt " intoString: nil];
  [scanner scanCharactersFromSet: [NSCharacterSet characterSetWithRange: NSMakeRange(0, 1000)] intoString:&name];
  NSFont *fn = [NSFont fontWithName:name size: size];
  return fn;
}

- (NSAttributedString *)formatString:(NSAttributedString *)string forToken:(NSString *)token
{
  NSMutableDictionary *def = [NSMutableDictionary dictionaryWithDictionary: [self defaultAttributes]];
  [def addEntriesFromDictionary: _theme[token]];
  [def setValue: token forKey: @"GMToken"];
  //  NSLog(@"FormatString: '%@' with def %@", string, def);
  NSMutableAttributedString *ret = [[NSMutableAttributedString alloc] initWithAttributedString: string];
  [ret setAttributes: def range: NSMakeRange(0, [string length])];
  return ret;
}

- (NSDictionary *)defaultAttributes
{
  return _theme[@"*"];
}

- (void)setValue:(id)value forAttribute:(NSString *)attribute inToken:(NSString *)token
{
  [_theme[token] setValue: value forKey: attribute];
}

@end
