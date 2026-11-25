<!---
 * Class IntBoolCast
 *
 * Handles converting an integer to a boolean (get), and a boolean to an
 * integer (set).
 *
 * Difference: the original class is final; there is no such thing here.
 * The type check of get() is isSimple_() (see BaseCast). set() takes any
 * simple value, not only a boolean, as the text "1" and the text "YES" can
 * not be told from a boolean; boolval() and intval() of the polyfills
 * stand in for the casts.
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting an integer to a boolean and back">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfif NOT isSimple_(arguments.value)>
			<cfset invalidTypeValueError(arguments.value)>
		</cfif>

		<cfreturn JavaCast("boolean", boolval(arguments.value))>
	</cffunction>

	<cffunction name="set" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfif NOT isSimple_(arguments.value)>
			<cfset invalidTypeValueError(arguments.value)>
		</cfif>

		<cfreturn intval(arguments.value)>
	</cffunction>
</cfcomponent>
