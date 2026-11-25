<!---
 * Gets the integer value of a variable, as a cast to int does.
 *
 * A string is read up to the end of its numeric prefix (" 12abc" is 12,
 * "1.9" is 1, "1e3" is 1000, "abc" is 0), and the fraction is cut off. A
 * boolean is 1 or 0 and a null (an empty string) is 0. A list or a map is 1
 * when it has items, and 0 when it has none.
 *
 * Difference: the text "true" and "YES" are the booleans that CFML writes
 * as text, so they are 1, and "false" and "NO" are 0 (the original reads
 * the text "false" as 0 and the text "true" as 0 too).
--->
<cffunction name="intval" returntype="numeric" output="no" hint="Gets the integer value of a variable">
	<cfargument name="value" type="any" required="yes">
	<cfset var text = "">
	<cfset var found = "">

	<cfif IsArray(arguments.value)>
		<cfif ArrayLen(arguments.value) GT 0>
			<cfreturn 1>
		</cfif>

		<cfreturn 0>
	</cfif>

	<cfif NOT IsSimpleValue(arguments.value)>
		<cfif IsObject(arguments.value) OR NOT StructIsEmpty(arguments.value)>
			<cfreturn 1>
		</cfif>

		<cfreturn 0>
	</cfif>

	<cfif is_bool(arguments.value)>
		<cfif arguments.value>
			<cfreturn 1>
		</cfif>

		<cfreturn 0>
	</cfif>

	<cfset text = JavaCast("string", arguments.value)>

	<cfif Compare(LCase(text), "true") EQ 0 OR Compare(LCase(text), "yes") EQ 0>
		<cfreturn 1>
	</cfif>

	<cfset found = REFind("^[ \t\n\r\x0B\f]*[+-]?([0-9]+(\.[0-9]*)?|\.[0-9]+)([eE][+-]?[0-9]+)?", text, 1, true)>

	<cfif found.pos[1] EQ 0>
		<cfreturn 0>
	</cfif>

	<cfreturn Fix(floatval(Mid(text, 1, found.len[1])))>
</cffunction>
