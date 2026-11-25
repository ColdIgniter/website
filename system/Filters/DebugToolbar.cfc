<!---
 * Debug Toolbar filter
--->
<cfcomponent output="no" extends="FilterInterface" hint="Debug Toolbar filter">

	<!---
	 * We don't need to do anything here.
	 *
	 * @param request_   The request
	 * @param arguments_ An empty string, or a list of strings
	 *
	 * @return A response, or an empty string (null)
	--->
	<cffunction name="before" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="arguments_" type="any" required="no" default="">

		<cfreturn "">
	</cffunction>

	<!---
	 * If the debug flag is set (CI_DEBUG) then collect performance
	 * and debug information and display it in a toolbar.
	 *
	 * @param request_   The request
	 * @param response   The response
	 * @param arguments_ An empty string, or a list of strings
	 *
	 * @return A response, or an empty string (null)
	 *
	 * Difference: the debug flag is also tested here, before the toolbar
	 * service is asked for. Without it the toolbar and all its collectors
	 * are created on every request, also in production, and prepare() then
	 * returns at once.
	--->
	<cffunction name="after" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">
		<cfargument name="arguments_" type="any" required="no" default="">

		<cfif NOT request.CI_DEBUG>
			<cfreturn "">
		</cfif>

		<cfset service("toolbar").prepare(arguments.request_, arguments.response)>

		<cfreturn "">
	</cffunction>

</cfcomponent>
