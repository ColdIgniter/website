<!---
 * Finds whether a variable is a boolean.
 *
 * Difference: every literal here is text (the text "true" and the text
 * "false" are not booleans), so only a real boolean counts, such as
 * JavaCast("boolean", true) or the result of a function that returns one.
--->
<cffunction name="is_bool" returntype="boolean" output="no" hint="Finds whether a variable is a boolean">
	<cfargument name="value" type="any" required="yes">

	<cfif NOT IsSimpleValue(arguments.value)>
		<cfreturn false>
	</cfif>

	<cfreturn Compare(arguments.value.getClass().getName(), "java.lang.Boolean") EQ 0>
</cffunction>
