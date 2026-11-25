<!---
 * Config exception.
 *
 * Thrown if the value of the Config class is invalid or the type is
 * incorrect.
 *
 * An exception is not an object here. The methods throw the exception
 * themselves, with the type "ColdIgniter.Exceptions.ConfigException":
 *
 *     <cfset static_("ColdIgniter\Exceptions\ConfigException").forDisabledMigrations()>
 *
 * Difference: the original extends RuntimeException, so a catch of that
 * type finds it; here the type is its own. DebugTraceableTrait is not
 * needed, a thrown error carries its own trace.
--->
<cfcomponent output="no" hint="Config exception">

	<cffunction name="getExitCode" access="public" returntype="numeric" output="no">

		<cfreturn request.EXIT_CONFIG>
	</cffunction>

	<cffunction name="forDisabledMigrations" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Exceptions.ConfigException" message="#lang('Migrations.disabled')#">
	</cffunction>

</cfcomponent>
