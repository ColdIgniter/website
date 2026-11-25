<!---
 * Class IntegerCast
 *
 * Handles converting a value to an integer.
 *
 * Difference: intval() of the polyfills stands in for the cast (int).
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting a value to an integer">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfreturn intval(arguments.value)>
	</cffunction>
</cfcomponent>
