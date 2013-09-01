Autocomplete Text View Programming Guide
========================================

This document shows how to use the GMAutoCompleteTextView class and explains how would one go about implementing their own auto completing text view. If you want to use GMCodeEditor, chances are that this document will be less interesting, since it assumes you wish to make completely custom autocompletion and it is primarily written in a style assuming it is the only class being used. However if you wish to significantly modify GMCodeEditor's autocompletion, this document still might be useful, but I would also recommend taking a look at the code for that class.

It is good to note, that GMAutoCompleteTextView is a powerful class that is mean for special needs of autocompletion, and that for simpler word based autocompletion using `-(NSArray *)textView:theTextView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index` may be much easier.

That being said, GMAutoCompleteTextView will allow many very interesting applications.

### Subclassing

In order to make your own autocompletion work, you will need to use your own subclass. This has been chosen so, because different autocompletion behaviors often need very different approaches and also chances are you may be needing to override NSTextView anyway.


## Conceptual Overview

Autocompletion works by observing the events that change a text views `textStorage` and whenever that happens a check is performed whether or not to perform the autocompletion. If this fails, the process stops here until the next event happens. If it succeeds, it can also determine the type of autocompletion. For example, in my application I autocomplete latex math directives for formatting mathematics and bibtex cite keys for creating academic references. A bibtex key in my application always starts with an at sign (`@`), math directives are only relevant when a math equation is detected, delimited by dollar symbols `$`. Therefore if the user typed something that begins with an `@`, I signal a reference type autocompletion, if it begins with a `$`, I signal a math autocompletion and otherwise I signal no autocompletion. To achieve this, you must override [GMAutoCompleteTextView triggerForCurrentPosition]. If you wish to have autocompletion always showing, make sure to never return `nil` from this method.

The next step is to find the string that will be used to filter the possibilities for autocompletion. The method [rangeForCurrentPosition]([GMAutoCompleteTextView rangeForCurrentPosition]) is responsible for this. The default implementation selects 1 word backwards from the current selection.

Then the list of autocompletions needs to be obtained. This will always have to be a NSArray, but we can autocomplete much richer objects than merely strings. The method [GMAutoCompleteTextView autocompletionListForTrigger:] is responsible for this. If you return an array of strings from this method, then no more work is required from you. However if more complex objects are returned then there are several tasks that must be performed. 

The first task is to display the object properly in the list. The easiest way to do this is to create a nib in your project whose sole object is a NSTableCellView subclass. Then bind all of it's children to the table cell view's `objectValue`'s properties. The nib should have the same name as the `trigger` property that corresponds to the object being presented, or alternatively, [GMAutoCompleteTextView cellTypeForTrigger:object:] should be implemented returning the name of the nib. For the purposes of reusing memory, the cell view's `identifier` should be set to the nib's filename (excluding extension).

The second task is to extract from this object the string that should be autocompleted. The recommended way is to have the object implement the `-key` method, which represents the string being autocompleted. Alternatively, [GMAutoCompleteTextView textForObject:] may be implemented that will return the key to the object.

Once the list of potential objects for autocompletion is obtained, they are filtered and sorted. This is done via [GMAutoCompleteTextView  item:matchesFilter:], which returns a score which is used both for filtering and ordering. The workings of this method can be substantially customized by changing the [GMAutoCompleteTextView  matchingAlgorithm] property. The possible values and their effects are [in the documentation]([GMAutoCompleteTextView  item:matchesFilter:]).

Finally, if after filtering there are any objects remaining, the view will display the list, otherwise if the list is showing, it will hide it.