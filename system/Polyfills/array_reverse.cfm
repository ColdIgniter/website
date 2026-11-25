<!---
 * Returns a list with the elements in reverse order. The argument is not
 * changed.
--->
<cffunction name="array_reverse" returntype="array" output="no" hint="Returns a list with the elements in reverse order">
	<cfargument name="array" type="array" required="yes">
	<cfset var result = ArrayNew(1)>
	<cfset var i = 0>

	<cfloop from="#ArrayLen(arguments.array)#" to="1" index="i" step="-1">
		<cfset ArrayAppend(result, arguments.array[i])>
	</cfloop>

	<cfreturn result>
</cffunction>
