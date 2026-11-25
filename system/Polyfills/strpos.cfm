<!---
 * Finds the position of the first occurrence of a string:
 * strpos(haystack, needle, offset).
 *
 * The position and the offset start at 0. Difference: false, for a string
 * that is not found, is -1.
--->
<cffunction name="strpos" returntype="numeric" output="no" hint="Finds the position of the first occurrence of a string">
	<cfargument name="haystack" type="string" required="yes">
	<cfargument name="needle" type="string" required="yes">
	<cfargument name="offset" type="numeric" required="no" default="0">
	<cfset var found = 0>

	<cfif Len(arguments.needle) EQ 0 OR arguments.offset GT Len(arguments.haystack)>
		<cfreturn -1>
	</cfif>

	<cfset found = Find(arguments.needle, arguments.haystack, arguments.offset + 1)>

	<cfreturn found - 1>
</cffunction>
