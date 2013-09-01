//
//  GMSyntaxHighlighter.m
//  CSS Editor
//
//  Created by Jakub Hampl on 04.07.13.
//  Copyright (c) 2013 Jakub Hampl. All rights reserved.
//

#import "GMSyntaxHighlighter.h"
#import "GMLanguage.h"

@implementation GMSyntaxHighlighter

- (id)init
{
  if (self = [super init]) {
    _theme = [GMTheme themeFromBundleWithName: @"default"];
    _language = @{@"grammar": @{}};
  }
  return self;
}

- (NSAttributedString *)highlight: (NSString *)text
{
  return [GMToken stringify: [self tokenize: text] theme: [self theme]];
}

- (NSArray *)tokenize:(NSString *)text
{
  
  NSMutableArray *strarr = [NSMutableArray arrayWithObject: text];
  GMOrderedDictionary *predictives = [GMOrderedDictionary dictionary];
  
  for (NSString *token in _language[@"grammar"]) {
    id val = _language[@"grammar"][token];
    GMOrderedDictionary *inside;
    NSRegularExpression *pattern;
    NSRegularExpression *predictive;
    BOOL lookbehind = NO;
    NSUInteger lookbehindLength = 0;
    
    if ([val isKindOfClass: [NSDictionary class]]) {
      pattern = val[@"pattern"];
      inside = val[@"inside"];
      lookbehind = [val[@"lookbehind"] boolValue];
      predictive = val[@"predictive"];
      if (predictive) [predictives setValue:predictive forKey: token];
    } else if ([val isKindOfClass: [NSRegularExpression class]]) {
      pattern = val;
    }
    
    
    
    
    for (int i = 0; i < [strarr count]; i++) {
      id str = strarr[i];
      
      if ([strarr count] > [text length]) {
        break;
      }
      
      if ([str isKindOfClass:[GMToken class]]) {
        continue;
      }
      
      //val[@"lastIndex"] = 0;
    
      NSTextCheckingResult *match = [pattern firstMatchInString: str options:0 range: NSMakeRange(0, [str length])];
      if (match) {
        if (lookbehind) {
          lookbehindLength = [match rangeAtIndex: 1].length;
        }
        NSUInteger from = match.range.location - 1 + lookbehindLength;
        NSString *slice = [str substringWithRange: NSMakeRange(match.range.location + lookbehindLength, match.range.length - lookbehindLength)];
        NSUInteger len = [slice length];
        NSUInteger to = from + len;
        NSString *before;
        if (from + 1 > 0) {
          before = [str substringWithRange:NSMakeRange(0, from + 1)];
        }
        NSString *after;
        if (to + 1 < [str length]) {
          after = [str substringFromIndex: to + 1];
        }
        
        NSMutableArray *args = [NSMutableArray array];
        if (before) {
          [args addObject: before];
        }
        GMToken *wrapped;
        if (inside) {
          GMSyntaxHighlighter *sh = [[GMSyntaxHighlighter alloc] init];
          sh.language = @{@"grammar": inside};
          sh.theme = [self theme];
          wrapped = [[GMToken alloc] initWithToken: token inside: [sh tokenize:slice]];
        } else {
          wrapped = [[GMToken alloc] initWithToken: token inside: slice];
        }
        [args addObject: wrapped];
        if (after) {
          [args addObject: after];
        }
        
        [strarr replaceObjectsInRange:NSMakeRange(i, 1) withObjectsFromArray:args];
        
      }
      
    }
    
  }
  
  NSMutableString *tokenString = [NSMutableString string];
  NSUInteger offset = 0;
  
  for (NSString *token in predictives) {
    for (int i = 0; i < [strarr count]; i++) {
      id str = strarr[i];
      
      if ([strarr count] > [text length]) {
        break;
      }
      
      if ([str isKindOfClass:[GMToken class]]) {
        [tokenString appendFormat:@"<%@>", [str tokenType]];
        offset += [str contentLength];
        continue;
      }
      
      NSString *matchCopy = [tokenString stringByAppendingString: str];
      
      
      NSTextCheckingResult *match = [predictives[token] firstMatchInString: matchCopy options:0 range: NSMakeRange(0, [matchCopy length])];
      if (match) {
        NSRange r = [match rangeAtIndex: [match numberOfRanges]-1];
        NSMutableArray *args = [NSMutableArray array];
        
        if (r.location > [matchCopy length] - [tokenString length]) {
          //NSRange range = NSMakeRange([tokenString length] - 1, r.length);
          NSString *before = [matchCopy substringWithRange: NSMakeRange([tokenString length], r.location - [tokenString length])];
          [args addObject: before];
          [tokenString appendString: before];
        }
        
        [args addObject: [[GMToken alloc] initWithToken: token inside: [matchCopy substringWithRange:r]]];
        [tokenString appendFormat: @"<%@>", token];
        if (r.location + r.length < [matchCopy length]) {
          NSString *after = [matchCopy substringFromIndex: r.location + r.length];
          [args addObject: after];
          [tokenString appendString: after];
        }
        [strarr replaceObjectsInRange:NSMakeRange(i, 1) withObjectsFromArray:args];
        
      } else {
        [tokenString appendString: str];
      }
      
      
    }
  }
  return strarr;
}


- (NSString *)convertToHTML:(NSAttributedString *)as
{
  NSMutableString *html = [NSMutableString string];
  [as enumerateAttribute: @"GMToken" inRange:NSMakeRange(0, [as length]) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
    NSString *str = (__bridge NSString *)(CFXMLCreateStringByEscapingEntities(NULL, (__bridge CFStringRef)([[as string] substringWithRange: range]), NULL));
    if (value) {
      [html appendFormat: @"<span class='%@'>%@</span>", value, str];
    } else {
      [html appendString: str];
    }
    str = nil;
  }];
  return html;
}

@end

@implementation GMToken

- (GMToken *)initWithToken:(NSString *)token inside:(id)inside
{
  if (self = [super init]) {
    self.tokenType = token;
    self.content = inside;
  }
  return self;
}

- (NSUInteger)contentLength
{
  if ([_content isKindOfClass: [NSString class]]) {
    return [_content length];
  } else if ([_content isKindOfClass: [NSArray class]]) {
    NSUInteger ret = 0;
    for (id element in _content) {
      ret += [element contentLength];
    }
    return ret;
  }
  return 0;
}

+(NSAttributedString *)stringify:(id)token theme: (GMTheme *)theme
{
  if ([token isKindOfClass: [NSString class]]) {
    return [[NSAttributedString alloc] initWithString: token attributes: theme.defaultAttributes];
  }
  
  if ([token isKindOfClass: [NSArray class]]) {
    NSMutableAttributedString *ret = [[NSMutableAttributedString alloc] init];
    for(id element in token) {
      [ret appendAttributedString: [GMToken stringify: element theme: theme]];
    }
    return ret;
  }

  NSAttributedString *content = [GMToken stringify: [token content] theme: theme];
  
  return [theme formatString: content forToken: [token tokenType]];

}

-(NSString *)description
{
  return [NSString stringWithFormat: @"<GMToken[%@]: '%@'>", self.tokenType, self.content];
}

@end




