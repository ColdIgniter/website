<!---
 * Includes a file of functions, once per request.
 *
 * The functions in the file become global, and the caller gets them
 * right away. A function that already exists is kept.
--->
<cffunction name="require_once" returntype="boolean" output="no" hint="Includes a file of functions, once per request">
	<cfargument name="filename" type="string" required="yes">
	<cfset var key = realpath(arguments.filename)>

	<cfif StructKeyExists(request.ColdIgniter.included, key)>
		<cfreturn true>
	</cfif>

	<cfset request.ColdIgniter.included[key] = true>
	<cfset request.ColdIgniter.functions.__require(arguments.filename)>
	<cfset StructAppend(variables, request.ColdIgniter.functions.__functions(), false)>

	<cfreturn true>
</cffunction>
