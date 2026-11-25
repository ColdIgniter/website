<!---
 * Strips characters from the end of a string.
 *
 * Without a list of characters, whitespace is stripped. The characters
 * are a plain list (no ranges). Named with an underscore, because a
 * CFML function has the name of the original.
 *
 * Difference: the run of characters is only tried at its left edge (a
 * look-behind), so a long run that is not at the end is not scanned
 * again from every position (the plain form is quadratic). The end is
 * \z, because $ also matches before a last line break.
 *
 * Not ported yet: the NUL character in the default list of characters,
 * because Chr(0) is an empty string on the server.
--->
<cffunction name="rtrim_" returntype="string" output="no" hint="Strips characters from the end of a string">
	<cfargument name="string" type="string" required="yes">
	<cfargument name="characters" type="string" required="no" default="#Chr(32) & Chr(9) & Chr(10) & Chr(13) & Chr(11)#">
	<cfset var escaped = JavaCast("string", arguments.characters).replaceAll("([^A-Za-z0-9])", "\\$1")>

	<cfif arguments.characters EQ "">
		<cfreturn arguments.string>
	</cfif>

	<cfreturn JavaCast("string", arguments.string).replaceAll("(?<![" & escaped & "])[" & escaped & "]+\z", "")>
</cffunction>
