<!---
 * Class URICast
 *
 * Handles converting a text to a URI and back.
 *
 * Difference: the type check of get() is isSimple_() (see BaseCast).
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting a text to a URI and back">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfif NOT isSimple_(arguments.value)>
			<cfset invalidTypeValueError(arguments.value)>
		</cfif>

		<cfreturn new_("ColdIgniter\HTTP\URI", arguments.value)>
	</cffunction>

	<cffunction name="set" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfif NOT instanceof_(arguments.value, "URI")>
			<cfset invalidTypeValueError(arguments.value)>
		</cfif>

		<cfreturn arguments.value.__toString()>
	</cffunction>
</cfcomponent>
