<!---
 * Finds whether a variable is null.
 *
 * There is no null here, so an empty string stands in for it.
--->
<cffunction name="is_null" returntype="boolean" output="no" hint="Finds whether a variable is null (an empty string)">
	<cfargument name="value" type="any" required="yes">

	<cfreturn IsSimpleValue(arguments.value) AND arguments.value EQ "">
</cffunction>
