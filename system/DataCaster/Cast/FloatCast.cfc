<!---
 * Class FloatCast
 *
 * Handles converting a value to a float.
 *
 * Difference: the type check is isSimple_() (see BaseCast), and
 * floatcast_() of the polyfills stands in for the cast (float).
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting a value to a float">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfif NOT isSimple_(arguments.value)>
			<cfset invalidTypeValueError(arguments.value)>
		</cfif>

		<cfreturn floatcast_(arguments.value)>
	</cffunction>
</cfcomponent>
