<!---
 * Class BooleanCast
 *
 * Handles converting a value to a boolean.
 *
 * Difference: filter_var() with FILTER_VALIDATE_BOOLEAN is not in the
 * polyfills, so the text "1", "true", "on" and "yes" (any case) are true,
 * as the filter has it, and anything else is false. A real boolean is read
 * as it is.
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting a value to a boolean">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfif is_bool(arguments.value)>
			<cfreturn arguments.value>
		</cfif>

		<!--- for PostgreSQL --->
		<cfif IsSimpleValue(arguments.value) AND Compare(arguments.value, "t") EQ 0>
			<cfreturn JavaCast("boolean", true)>
		</cfif>

		<cfif IsSimpleValue(arguments.value) AND Compare(arguments.value, "f") EQ 0>
			<cfreturn JavaCast("boolean", false)>
		</cfif>

		<cfif NOT IsSimpleValue(arguments.value)>
			<cfreturn JavaCast("boolean", false)>
		</cfif>

		<cfreturn JavaCast("boolean", ListFindNoCase("1,true,on,yes", Trim(arguments.value)) GT 0)>
	</cffunction>
</cfcomponent>
