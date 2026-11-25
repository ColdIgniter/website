<!---
 * Splits a string by a string. Empty parts are kept, which the list
 * functions do not do.
 *
 * With a limit above zero, the result has at most that many parts and
 * the last part holds the rest of the string.
--->
<cffunction name="explode" returntype="array" output="no" hint="Splits a string by a string">
	<cfargument name="separator" type="string" required="yes">
	<cfargument name="string" type="string" required="yes">
	<cfargument name="limit" type="numeric" required="no" default="0">
	<cfset var result = ArrayNew(1)>
	<cfset var start = 1>
	<cfset var position = Find(arguments.separator, arguments.string, 1)>

	<cfloop condition="position GT 0 AND (arguments.limit LTE 0 OR ArrayLen(result) LT arguments.limit - 1)">
		<cfset ArrayAppend(result, substr(arguments.string, start - 1, position - start))>
		<cfset start = position + Len(arguments.separator)>
		<cfif start GT Len(arguments.string)>
			<cfset position = 0>
		<cfelse>
			<cfset position = Find(arguments.separator, arguments.string, start)>
		</cfif>
	</cfloop>

	<cfset ArrayAppend(result, substr(arguments.string, start - 1))>

	<cfreturn result>
</cffunction>
