<!---
 * Sets the value of a configuration option.
 *
 * Difference: there is no configuration to change, so the value is
 * only kept for the rest of the request, where ini_get() reads it.
 * Returns the old value, or false if there was none.
--->
<cffunction name="ini_set" returntype="any" output="no" hint="Sets the value of a configuration option">
	<cfargument name="option" type="string" required="yes">
	<cfargument name="value" type="string" required="yes">
	<cfset var old = false>

	<cfif StructKeyExists(request.ColdIgniter.ini, arguments.option)>
		<cfset old = request.ColdIgniter.ini[arguments.option]>
	</cfif>

	<cfset request.ColdIgniter.ini[arguments.option] = arguments.value>

	<cfreturn old>
</cffunction>
