<!---
 * Gets the float value of a variable, as a cast to float does. Not in the
 * original as a function: floatval() reads a numeric string only, so this
 * stands in for the operator (float).
 *
 * A string is read up to the end of its numeric prefix (" 1.5abc" is 1.5,
 * "abc" is 0). A boolean is 1 or 0, a null (an empty string) is 0, and a
 * list or a map is 1 when it has items and 0 when it has none.
 *
 * Difference: the text "true" and "YES" are 1, and "false" and "NO" are 0,
 * as in intval().
--->
<cffunction name="floatcast_" returntype="numeric" output="no" hint="Gets the float value of a variable">
	<cfargument name="value" type="any" required="yes">
	<cfset var text = "">
	<cfset var found = "">

	<cfif NOT IsSimpleValue(arguments.value) OR is_bool(arguments.value)>
		<cfreturn intval(arguments.value)>
	</cfif>

	<cfset text = JavaCast("string", arguments.value)>

	<cfif Compare(LCase(text), "true") EQ 0 OR Compare(LCase(text), "yes") EQ 0>
		<cfreturn 1>
	</cfif>

	<cfset found = REFind("^[ \t\n\r\x0B\f]*[+-]?([0-9]+(\.[0-9]*)?|\.[0-9]+)([eE][+-]?[0-9]+)?", text, 1, true)>

	<cfif found.pos[1] EQ 0>
		<cfreturn 0>
	</cfif>

	<cfreturn floatval(Mid(text, 1, found.len[1]))>
</cffunction>
