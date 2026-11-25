<!---
 * Finds the position of the last occurrence of a string:
 * strrpos(haystack, needle).
 *
 * The position starts at 0. Difference: false, for a string that is not
 * found, is -1, and the offset argument is not supported.
--->
<cffunction name="strrpos" returntype="numeric" output="no" hint="Finds the position of the last occurrence of a string">
	<cfargument name="haystack" type="string" required="yes">
	<cfargument name="needle" type="string" required="yes">

	<cfif Len(arguments.needle) EQ 0>
		<cfreturn -1>
	</cfif>

	<cfreturn JavaCast("string", arguments.haystack).lastIndexOf(JavaCast("string", arguments.needle))>
</cffunction>
