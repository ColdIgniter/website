<!---
 * Class IntegerCast
 *
 * Handles converting a value to an integer.
 *
 * Difference: the type check is isSimple_() (see BaseCast), and intval() of
 * the polyfills stands in for the cast (int).
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting a value to an integer">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfif NOT isSimple_(arguments.value)>
			<cfset invalidTypeValueError(arguments.value)>
		</cfif>

		<cfreturn intval(arguments.value)>
	</cffunction>
</cfcomponent>
