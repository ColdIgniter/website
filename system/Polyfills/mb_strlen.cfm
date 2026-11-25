<!---
 * Gets the string length, in characters.
 *
 * Len() counts the 16 bit units of the Java string, so a character
 * outside the basic plane (a surrogate pair) would count twice. Such
 * a pair is counted once here.
--->
<cffunction name="mb_strlen" returntype="numeric" output="no" hint="Gets the string length, in characters">
	<cfargument name="string" type="string" required="yes">
	<cfset var pairs = (Len(arguments.string) - Len(JavaCast("string", arguments.string).replaceAll("[\uD800-\uDBFF][\uDC00-\uDFFF]", ""))) / 2>

	<cfreturn Len(arguments.string) - pairs>
</cffunction>
