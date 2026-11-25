<!---
 * Defines a named constant. Constants live in the Request scope, so
 * define("APPPATH", value) is read back as request.APPPATH.
 * Returns false if the constant already exists.
--->
<cffunction name="define" returntype="boolean" output="no" hint="Defines a named constant">
	<cfargument name="constant_name" type="string" required="yes">
	<cfargument name="value" type="any" required="yes">

	<cfif StructKeyExists(request, arguments.constant_name)>
		<cfreturn false>
	</cfif>

	<cfset request[arguments.constant_name] = arguments.value>

	<cfreturn true>
</cffunction>
