<!---
 * Returns the one object that stands in for a class with static
 * members: static_("Config\Services").autoloader() stands in for
 * Services::autoloader().
 *
 * The object is created once per request, without __construct().
--->
<cffunction name="static_" returntype="any" output="no" hint="Returns the one object that stands in for a class with static members">
	<cfargument name="class" type="string" required="yes">
	<cfset var key = arguments.class>

	<!--- a leading backslash is rare: the pattern is run only when there is one --->
	<cfif Compare(Left(key, 1), "\") EQ 0>
		<cfset key = REReplace(key, "^\\+", "")>
	</cfif>

	<cfif NOT StructKeyExists(request.ColdIgniter.statics, key)>
		<cfset request.ColdIgniter.statics[key] = request.ColdIgniter.autoloader.instantiate(key)>
	</cfif>

	<cfreturn request.ColdIgniter.statics[key]>
</cffunction>
