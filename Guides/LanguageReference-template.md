# Language Document Format Reference

The `.language` file format is used to configure the properties of the GMCodeEditor and its associated classes. The file is a plist file, though some post-processing is done on it so that some strings are turned into regular expressions for easy archiving of such objects. Therefore this document lists all the keys that such a file may contain.

### Comments

The `comments` key configures how the [GMCodeEditor toggleComments:] command will work. It should be a dictionary with at least line or start/end defined, possibly both.

`line` defines the string that will be a single line comment, like `//` in C/Java or `#` in Ruby/Shell/Python.

`start` and `end` define pairwise block comments like `/*` and `*/` in C/CSS or `{-` and `-}` in Haskell.

### Paired Characters

The `paired_characters` key should be a string which lists characters that will be considered paired. This means that when the user types the first character in the pair, the editor will automatically insert the other character and when the user moves the cursor over the second character the first will be briefly highlighted. This is meant for various kinds of brackets, quotes, etc.

The format should be a string of even length where the odd characters form the first of the pair and the even form the corresponding second. So a string like `<>""{}()` would establish the following pairs:

- `<`, `>`
- `"`, `"`
- `{`, `}`
- `(`, `)`

<small>Implementation Note: GMLanguage will transform this string into a dictionary where the keys are the first character and the values the second character.</small>

### Indenting Characters

`indent_characters` form a set of characters, after which the editor will immediately insert a line break and an indentation. In c-like languages this will typically be a `{`, as this delineates a code block.

### Grammar

The `grammar` is used to perform syntax-highlighting in the editor as well as analysis of what is being edited. Therefore it is also used for autocompletion purposes.

`grammar` should be an array of dictionaries where each dictionary should have only one key. This might seem odd, but the fact is that the grammar depends on the order of evaluation and this is not preserved when loading a NSDictionary. Therefore GMLanguage will transform this data structure into an Ordered Dictionary with the same API as NSMutableDictionary, except that it preserves order.

Any string (as a value, not as a key) will be attempted to be converted to a regular expression. Such a regular expression must start with a slash `/` and end with a slash `/` followed by possible modifier charachters:

<table>
<tr><th>Character</th><th>Objective C Constant</th></tr>
<tr><td><code>i</code></td><td><code>NSRegularExpressionCaseInsensitive</code></td></tr>
<tr><td><code>x</code></td><td><code>NSRegularExpressionAllowCommentsAndWhitespace</code></td></tr>
<tr><td><code>s</code></td><td><code>NSRegularExpressionDotMatchesLineSeparators</code></td></tr>
</table>

Therefore `/\s+..\s+/si` is equivalent to `[NSRegularExpression regularExpressionWithPattern: @"\\s+..\\s+" options: NSRegularExpressionDotMatchesLineSeparators | NSRegularExpressionCaseInsensitive error: &err]`.

The key in each of the dictionaries is the name of the token, the value should either be a regular expression that matches that token, or a dictionary of further options:

<table>
<tr><th>Key</th><th>Value</th></tr>
<tr>
  <td><code>pattern</code></td>
  <td>A regular expression that will match the token.</td>
</tr>
<tr>
  <td><code>inside</code></td>
  <td>Another grammar structure that will operate on the contents of the matched token.</td>
</tr>
<tr>
  <td><code>predictive</code></td>
  <td>The syntax highlighter will try to guess the best match for a token that cannot be distinguished based on the text. This then is a regular expression which matches on a combined stream: tokens that have been matched are replaced by the string `<token name>` whereas unmatched text is left verbatim. Therefore this allows to match tokens based on other tokens rather then necessarily syntactic properties of the text.</td>
</tr>
</table>

### autocompletion

The `autocompletion` dictionary specifies tokens as its keys and arrays of words as the values. When editing a token, the words in the array will be autocompleted.

## Example File

This is an example file for the CSS language:

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    	<key>paired_characters</key>
    	<string>(){}[]&quot;&quot;&apos;&apos;</string>
    	<key>indent_characters</key>
    	<string>{</string>
      <key>comments</key>
      <dict>
        <key>start</key>
        <string>/*</string>
        <key>end</key>
        <string>*/</string>
      </dict>
      <key>grammar</key>
    	<array>
    		<dict>
    			<key>comment</key>
    			<string>/\/\*[\w\W]*?\*\//g</string>
    		</dict>
    		<dict>
    			<key>at rule</key>
    			<dict>
    				<key>pattern</key>
    				<string>/@[\w-]+?.*?(;|(?=\s*\{))/gi</string>
    				<key>inside</key>
    				<array>
    					<dict>
    						<key>punctuation</key>
    						<string>/[;:]/g</string>
    					</dict>
    				</array>
    			</dict>
    		</dict>
    		<dict>
    			<key>url</key>
    			<string>/url\(([&quot;&apos;]?).*?\1\)/gi</string>
    		</dict>
    		<dict>
    			<key>selector</key>
    			<string>/[^\{\}\s][^\{\};]*(?=\s*\{)/g</string>
    		</dict>
    		<dict>
    			<key>property</key>
    			<dict>
    				<key>pattern</key>
    				<string>/(\b|\B)[\w-]+(?=\s*:)/ig</string>
    				<key>predictive</key>
    				<string>/&lt;selector&gt;\s*&lt;punctuation&gt;\s*(&lt;property&gt;\s*&lt;punctuation&gt;[^&lt;]+\s*&lt;punctuation&gt;\s*)*\s*([^&lt;\s]+)\s*$/</string>
    			</dict>
    		</dict>
    		<dict>
    			<key>string</key>
    			<string>/(&quot;|&apos;)(\\?.)*?\1/g</string>
    		</dict>
        <dict>
            <key>number</key>
            <string>/\d+/</string>
        </dict>
    		<dict>
    			<key>important</key>
    			<string>/\B!important\b/gi</string>
    		</dict>
    		<dict>
    			<key>ignore</key>
    			<string>/&amp;(lt|gt|amp);/gi</string>
    		</dict>
    		<dict>
    			<key>punctuation</key>
    			<string>/[\{\};:]/g</string>
    		</dict>
    	</array>
    </dict>
    </plist>
