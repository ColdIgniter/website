<!---
 * Class BooleanCast
 *
 * Handles converting a value to a boolean.
 *
 * Difference: boolval() of the polyfills stands in for the cast (bool); the
 * text "false" and "NO" are false.
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting a value to a boolean">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfreturn JavaCast("boolean", boolval(arguments.value))>
	</cffunction>
</cfcomponent>
