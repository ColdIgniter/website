<!---
 * Reads a whole file into a string.
 *
 * Difference: a file that cannot be read throws an exception, where the
 * original gives false with a warning.
--->
<cffunction name="file_get_contents" returntype="string" output="no" hint="Reads a whole file into a string">
	<cfargument name="filename" type="string" required="yes">
	<cfset var contents = "">

	<cffile action="read" file="#arguments.filename#" variable="contents">

	<cfreturn contents>
</cffunction>
