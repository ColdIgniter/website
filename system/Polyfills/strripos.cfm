<!---
 * Finds the position of the last occurrence of a string, ignoring case:
 * strripos(haystack, needle).
 *
 * The position starts at 0. Difference: false, for a string that is not
 * found, is -1, and the offset argument is not supported.
--->
<cffunction name="strripos" returntype="numeric" output="no" hint="Finds the position of the last occurrence of a string, case-insensitive">
	<cfargument name="haystack" type="string" required="yes">
	<cfargument name="needle" type="string" required="yes">

	<cfif Len(arguments.needle) EQ 0>
		<cfreturn -1>
	</cfif>

	<cfreturn JavaCast("string", LCase(arguments.haystack)).lastIndexOf(JavaCast("string", LCase(arguments.needle)))>
</cffunction>
