<!---
 * Gets the boolean value of a variable, as a cast to bool does.
 *
 * An empty string (null), "0", a list or a map with no items, and a boolean
 * false are false. Anything else is true.
 *
 * Difference: the text "false" and "NO" are false too, as a literal false
 * and the text of a boolean false are the same value here (the original
 * reads the text "false" as true).
--->
<cffunction name="boolval" returntype="boolean" output="no" hint="Gets the boolean value of a variable">
	<cfargument name="value" type="any" required="yes">
	<cfset var text = "">

	<cfif IsArray(arguments.value)>
		<cfreturn ArrayLen(arguments.value) GT 0>
	</cfif>

	<cfif NOT IsSimpleValue(arguments.value)>
		<cfreturn IsObject(arguments.value) OR NOT StructIsEmpty(arguments.value)>
	</cfif>

	<cfif is_bool(arguments.value)>
		<cfreturn arguments.value>
	</cfif>

	<cfset text = JavaCast("string", arguments.value)>

	<cfif Len(text) EQ 0 OR Compare(text, "0") EQ 0 OR Compare(LCase(text), "false") EQ 0 OR Compare(LCase(text), "no") EQ 0>
		<cfreturn false>
	</cfif>

	<cfreturn true>
</cffunction>
