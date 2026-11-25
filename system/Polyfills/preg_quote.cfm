<!---
 * Quotes the characters of a string that have a meaning in a regular
 * expression: a backslash is put before every character that is not a
 * letter, a digit, an underscore or a non-ASCII character.
 *
 * Difference: the result is for the Java engine, not for PCRE. The
 * delimiter argument of the original is not needed.
--->
<cffunction name="preg_quote" returntype="string" output="no" hint="Quotes the characters of a string that have a meaning in a regular expression">
	<cfargument name="string" type="string" required="yes">

	<cfreturn JavaCast("string", arguments.string).replaceAll("([^A-Za-z0-9_\u0080-\uFFFF])", "\\$1")>
</cffunction>
