#import <Cocoa/Cocoa.h>


@protocol GMAutocompleteItem <NSObject>
@optional
- (NSString *)autocompletionKey;
- (NSString *)autocompletionSearchKey;
- (NSString *)autocompletionInsertionString;
@end


typedef enum {
  GMMatchingPrefix = 0,
  GMMatchingPrefixSuffixSorted,
  GMMatchingSubstring,
  GMMatchingDiceCoefficient,
  GMMatchingSubletters
} GMMatchingAlgorithm;

/**
 GMAutoCompleteTextView is a general purpose autocompletion text component. It allows for sofisticated customization,
 mostly through subclassing, which is required for proper usage of this component.
 
 We will explain here the general flow of autocompletion, and the individual methods will also explain the specifics of
 providing your own implementation. 
 
 ### Autocomplete Flow
 
 Whenever the underlying text view's `textStorage` changes, GMAutoCompleteTextView calls triggerForCurrentPosition to see
 if it should trigger autocompletion. If this method returns nil, the process stops. Otherwise a trigger object is
 returned, and this object should indicate the context of the autocompletion. (The default implementation simply always
 returns a particular string). 
 
 Then rangeForCurrentPosition is called, which should return a range of what of the autocompleted word has already been
 typed into the text view. From this range autocompleteFilter is set to a string from that range.
 
 Next autocompletionListForTrigger: is called which should return a list of possible autocompletions for the particular
 trigger. If the results are too many or need to be downloaded from a server, you can already use @autocompleteFilter to 
 select only the relevant ones. Otherwise you may leave this to the code to do automatically.
 autocompletionListForTrigger: is the only method that really needs overriding to something sensible.
 
 After that, the list has to be filtered and sorted. For this the method item:matchesFilter: is used. This should return
 a score between <0,1>, which is used both for ordering and filtering. Items with scores below 0.1 will not be displayed
 and items with the highest score will be displayed at the top. 
 
 Then to display the autocompletion window, appropriate NSTableCellView subclasses have to be instantiated and filled with
 the appropriate objects. cellTypeForTrigger:object: is called, which should return an identifier for a cell. By default
 this will return the trigger. This allows for a naming convention, that simplifies the process considerably. If you name
 your trigger, your cellview nib and your cell identifier the same, you do not need to change this method at all. Anyway,
 this string is then used to load a nib of that same name from the app bundle and use it as the cell view.
 
 This allows you to use not only strings in autocompletionListForTrigger:, but any arbitrary objects you wish. The only
 thing you need to do then, is to make your own cells to display these values and implement one of these methods:
 
 - textForObject: which given an object of the autocompletion list will give a string to actually autocomplete
 - or implement a `key` method directly on the object
 
 This is used both for the filtering and also for actually autocompleting a value.
 
 @see [Autocomplete Text View Programming Guide](Autocompletion)
 */
@interface GMAutoCompleteTextView : NSTextView <NSTextStorageDelegate, NSTableViewDelegate, NSTableViewDataSource> {
@private
  NSMutableArray *filteredList;
  //NSPopover *autocompletePopover;
  NSTableView *autocompleteTable;
  NSWindow *autocompleteWindow;
  id trigger;
}


/**
 @name Customization
 */
/**
 The matching algorithm that item:matchesFilter: will use.
 
 See the documentation for item:matchesFilter: for more information. The possible values are:
 
 - `GMMatchingPrefix`
 - `GMMatchingPrefixSuffixSorted`
 - `GMMatchingSubstring`
 - `GMMatchingDiceCoefficient`
 - `GMMatchingSubletters`
 @see item:matchesFilter:
 */
@property GMMatchingAlgorithm matchingAlgorithm;

/**
 @name Methods to consider overriding in subclasses
 */
/**
 Returns the list of autocompletions.
 
 You can already prefilter this list using the autocompleteFilter property, but this will be done automatically anyway later on.
 @param trigger A context object returned by -triggerForCurrentPosition.
 @return An array of autocompletion items. Without overriding -cellTypeForTrigger:object: this should be an array of strings, otherwise it can be an array of arbitrary objects, which your celltype should be able to display to the user. This object shoud respond to -key, otherwise you may need to override -textForObject:
 @see -triggerForCurrentPosition
*/
- (NSArray *)autocompletionListForTrigger: (id)trigger;
/**
 Provide an identifier for a cell nib to be loaded for displaying in the autocompletion window.
 
 The default behaviour is, that the app bundle is searched for a nib named whatever this method returns. Such a nib should contain a NSTableCellView with its `identifier` property set to the same string. Once the cell is loaded, it will be efficiently reused by the code.
 
 If the cell type isn't found, a default one will be constructed. However, the default cell can only display string objects, so for displaying richer information you will need to provide your own cell.
 @param trigger The context object for the autocompletion (that is whatever -triggerForCurrentPosition returns).
 @param object The object that is being displayed (this is an element from an array that -autocompletionListForTrigger: returns).
 @return A string identifier for a cell type, which is both the nib name and the `identifier` property of the NSTableCellView contained within.
 */
- (NSString *)cellTypeForTrigger: (id)trigger object: (id)object;
/**
 Detects if and what kind of autocompletion is relevant.
 
 For example, in a code editor, the type of the token being edited is passed, as then only the relevant symbols that fit into the token type can be autocompleted.
 
 If unsure what to use as a context object, using strings that identify your cell type means you do not have to override -cellTypeForTrigger:object:, since it will use the trigger string as a default to search for a suitable nib.
 @return If no autocompletion should take place, the method must return `nil`. Otherwise it can return an arbitrary object, that will be used for identifiying the type of autocomletion necessary.
 */
- (id)triggerForCurrentPosition;
/**
 Gives a string to actually autocomplete for a selected object.
 
 The method will try to convert the object to a string. That is if the object is a string, the object itself will be returned. If it responds to the `-key` method, that will be called and the result returned. Otherwise, as the object's `-description` method will be called.
 
 Therefore to make autocomplete work with arbitrary objects, you need to either override this method, or give your objects a `-key` method.
 @param object An autocomplete list object (this is an element from an array that -autocompletionListForTrigger: returns).
 @return A string that will be used for actually autocompleting in the text field.
 */
- (NSString *)textForObject: (id) object;
/**
 Gives a range of the text that has already been autocompleted.
 
 Conceptually, this should work by extending from the current selection backwards. This implementation selects the current word, that is until the next whitespace. For other purposes, you might want to override this behavior.
 @return A NSRange showing the already typed in filter. Returning a zero length selection will make the autocomplete window disapear.
 */
- (NSRange)rangeForCurrentPosition;
/**
Provides a score based filtering and ordering.

The exact method how the score is calculated depends on the value of the @matchingAlgorithm property:

- `GMMatchingPrefix` makes this method return 1.0 if the filter is an exact prefix of the item, and 0.0 otherwise. 
     This is the default. It does not change the sorting of the collection at all
- `GMMatchingPrefixSuffixSorted` works the same as `GMMatchingPrefix` except that it will reduce the score dependingly on the length of the unmatched suffix. For example:
      
         [cm item @"hello" matchesFilter: @"herro"];       // 0.0
         [cm item @"hello" matchesFilter: @"hell"];        // 0.99
         [cm item @"hello-world" matchesFilter: @"hell"];  // 0.93
 
      This means that the ordering will be that the shortest properties will be first. (NB: If the suffix is more then 90 characters long, it will be excluded from the list).
- `GMMatchingSubstring` returns 1.0 if the filter is a substring of the item, 0.0 otherwise. 
- `GMMatchingDiceCoefficient` uses an [approximate string matching technique](http://www.catalysoft.com/articles/strikeamatch.html) to find and sort the elements by those that match the closest. This does not require an exact match, but rather measures a distance metric between the words.
- `GMMatchingSubletters` will match a string if the item has all the letters of the filter in the correct order. The score is higher if the letters are close together.
        
         [cm item @"hello world" matchesFilter: @"herro wrold"]; // 0.0
         [cm item @"hello world" matchesFilter: @"hlr"]; // low score
         [cm item @"hello world" matchesFilter: @"llowl"]; // high score

If the scores are tied, the original ordering (from autocompletionListForTrigger:) is retained, so you can impose your own 
 order (especially when using `GMMatchingPrefix`, this is necessary, since all the matching elements have the same 
 ordering). 

@param item The object which is part of the array returned by autocompletionListForTrigger:.
@param filter What has been already typed. (NB: this is equal to @autocompleteFilter, but passed in for convenience).
@return A score between <0,1>, such that scores below 0.1 will not be shown, and the autocompletion list will be 
 sorted based on the score.
@see matchingAlgorithm
 */
- (double) item: (id)item matchesFilter: (NSString *)filter;


/**
 ------------------------------------------
 @name Triggering the autocompletion window
 ------------------------------------------
 */
-(void)showAutocomplete;

/**
 Indicates whether the autocomplete is being active at the moment.
 @return True when the window is showing and false otherwise.
 */
- (BOOL)autocompletionIsActive;

/**
 The string already typed.
 */
@property (readonly) NSString *autocompleteFilter;

@end