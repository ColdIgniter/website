<!---
 * Checks if a string starts with a given substring, exactly
 * (case-sensitive).
--->
<cffunction name="str_starts_with" returntype="boolean" output="no" hint="Checks if a string starts with a given substring">
	<cfargument name="haystack" type="string" required="yes">
	<cfargument name="needle" type="string" required="yes">

	<cfif Len(arguments.needle) GT Len(arguments.haystack)>
		<cfreturn false>
	</cfif>

	<cfif Len(arguments.needle) EQ 0>
		<cfreturn true>
	</cfif>

	<cfreturn Compare(Left(arguments.haystack, Len(arguments.needle)), arguments.needle) EQ 0>
</cffunction>
