<!---
 * Class IntBoolCast
 *
 * Handles converting a value to a boolean (get), and a boolean to an
 * integer (set).
 *
 * Difference: the original class is final; there is no such thing here.
 * boolval() and intval() of the polyfills stand in for the casts.
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting an integer to a boolean and back">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfreturn JavaCast("boolean", boolval(arguments.value))>
	</cffunction>

	<cffunction name="set" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfreturn intval(arguments.value)>
	</cffunction>
</cfcomponent>
