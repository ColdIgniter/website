<!---
 * Calculates the md5 hash of a string, as 32 lower-case hexadecimal
 * characters. Hash() gives upper case.
--->
<cffunction name="md5" returntype="string" output="no" hint="Calculates the md5 hash of a string">
	<cfargument name="string" type="string" required="yes">

	<cfreturn LCase(Hash(arguments.string))>
</cffunction>
