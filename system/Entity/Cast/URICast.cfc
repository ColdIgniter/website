<!---
 * Class URICast
 *
 * Handles converting a text to a URI.
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting a text to a URI">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfif instanceof_(arguments.value, "URI")>
			<cfreturn arguments.value>
		</cfif>

		<cfreturn new_("ColdIgniter\HTTP\URI", arguments.value)>
	</cffunction>
</cfcomponent>
