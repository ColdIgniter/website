<!---
 * Class StringCast
 *
 * Handles converting a value to a string.
 *
 * Difference: strval() of the polyfills stands in for the cast (string).
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting a value to a string">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfreturn strval(arguments.value)>
	</cffunction>
</cfcomponent>
