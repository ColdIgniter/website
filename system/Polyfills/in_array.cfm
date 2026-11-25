<!---
 * Checks if a value exists in an array. The comparison is exact
 * (case-sensitive), as with the strict flag.
--->
<cffunction name="in_array" returntype="boolean" output="no" hint="Checks if a value exists in an array">
	<cfargument name="needle" type="string" required="yes">
	<cfargument name="haystack" type="array" required="yes">
	<cfset var i = 0>

	<cfloop from="1" to="#ArrayLen(arguments.haystack)#" index="i">
		<cfif IsSimpleValue(arguments.haystack[i]) AND Compare(arguments.haystack[i], arguments.needle) EQ 0>
			<cfreturn true>
		</cfif>
	</cfloop>

	<cfreturn false>
</cffunction>
