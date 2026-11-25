<!---
 * Returns the full path with "." and ".." parts and mixed slashes
 * resolved, without a trailing slash.
 *
 * Difference: returns an empty string, not false, if the path does
 * not exist.
--->
<cffunction name="realpath" returntype="string" output="no" hint="Returns the canonical full path, or an empty string if it does not exist">
	<cfargument name="path" type="string" required="yes">
	<cfset var target = CreateObject("java", "java.io.File").init(arguments.path)>

	<cfif NOT target.exists()>
		<cfreturn "">
	</cfif>

	<cfreturn target.getCanonicalPath()>
</cffunction>
