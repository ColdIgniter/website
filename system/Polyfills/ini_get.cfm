<!---
 * Gets the value of a configuration option.
 *
 * Difference: it reads what ini_set() has kept for this request, and an
 * empty string is returned for an option that was not set.
--->
<cffunction name="ini_get" returntype="string" output="no" hint="Gets the value of a configuration option">
	<cfargument name="option" type="string" required="yes">

	<cfif StructKeyExists(request.ColdIgniter.ini, arguments.option)>
		<cfreturn request.ColdIgniter.ini[arguments.option]>
	</cfif>

	<cfreturn "">
</cffunction>
