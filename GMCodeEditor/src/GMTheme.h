//
//  GMTheme.h
//  Code Editor
//
//  Created by Jakub Hampl on 17.07.13.
//  Copyright (c) 2013 Jakub Hampl. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 GMTheme represents a syntax highlighting theme. The responsibilities of this class include loading a 
 representation of a theme from a stored file system location as well as actually formatting strings.
 
 If you wish to subclass or replace GMTheme in your application (a usefull alternative in some applications
 would surely be a NSUserDefaults based variant for allowing users to customize the theme), the only method
 that this object has to respond to is formatString:forToken:. This method must return an appropriately 
 formated NSAttributedString based on the token name. It also must set the custom attribute `GMToken` to the
 value of the token.
 
 ## Serialization Format
 
 d
 
*/
@interface GMTheme : NSObject
@property (retain) NSDictionary *theme;


/**
 @name Creating a theme from a filesystem representation
 */
/**
 Loads a theme plist from a given URL.
 @param url The accessible url where to find the theme declaration.
 @return Returns a new GMTheme instance if the file was found and parsed properly, otherwise nil.
 */
+ (id)themeAtURL: (NSURL *)url;
/**
 Loads a theme plist from a given path.
 @param path The accessible filesystem path where to find the theme declaration.
 @return Returns a new GMTheme instance if the file was found and parsed properly, otherwise nil.
 */
+ (id)themeAtPath: (NSString *)path;
/**
 Loads a theme plist from the application bundle.
 
 This is a useful shorthand method when using the provided theme bundles as these will by default reside
 in the applications resource folder and have the `.theme` extension. This method thus allows to find such
 bundles simply by their theme name.
 @param name The name of the theme.
 @return Returns a new GMTheme dictionary instance if the file was found and parsed properly, otherwise nil.
 */
+ (id)themeFromBundleWithName: (NSString *)name;
/**
 @name Creating a theme programatically
 */
/**
 Processes a dictionary, turning certain key value pairs into the appropriate data types for NSAttributedString.
 
 @param dict The theme definition dictionary.
 @return Returns a new GMTheme.
 */
- (id)initWithDictionary: (NSDictionary *)dict;
/**
 Modifies a property for a token without processing.
 
 This is usefull for specifying things that the current format doesn't support like colors with alpha values or fonts created with a matrix.
 @param value The value of the attribute.
 @param attribute A key that will go into NSAttributedString's attributes property.
 @param token The token you want this setting to apply to. Use `*` to modify the -defaultAttributes.
*/
- (void)setValue:(id)value forAttribute:(NSString *)attribute inToken: (NSString *)token;
/**
 @name Using a theme
 */
/**
 Returns a formatted string based on the theme settings for the given token.
 
 Also has to set the custom attribute `GMToken` with the token string in order for other methods to
 be able to directly understand the parse. 
 @param string The input string that should be formatted.
 @param token  The name of the token which should match the [language](GMLanguage) definition.
 @return An attributed string with appropriate formatting applied.
*/
- (NSAttributedString *)formatString:(NSAttributedString *)string forToken:(NSString *)token;

/**
 Returns the attributes that should be used for the default string.
 
 The default string is the string that isn't categorized as any particular token.
 @return A dictionary of attributes that go into NSAttributedString
 */
- (NSDictionary *)defaultAttributes;

@end
