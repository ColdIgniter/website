<!---
 * Force HTTPS filter
 *
 * The original gets the response of the exception it catches. An exception
 * cannot hold the response here, so force_https() changes the response it is
 * given and that response is returned (see force_https() in Common.cfm).
--->
<cfcomponent output="no" extends="FilterInterface" hint="Force HTTPS filter">

	<!---
	 * Force Secure Site Access? If the config value "forceGlobalSecureRequests"
	 * is true, will enforce that all requests to this site are made through
	 * HTTPS. Will redirect the user to the current page with HTTPS, as well as
	 * set the HTTP Strict Transport Security (HTST) header for those browsers
	 * that support it.
	 *
	 * @param arguments_ An empty string, or a list of strings
	 *
	 * @return The response to send, or an empty string.
	--->
	<cffunction name="before" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="arguments_" type="any" required="no" default="">
		<cfset var appConfig = config("Config\App")>
		<cfset var response = "">

		<cfif NOT (IsBoolean(appConfig.forceGlobalSecureRequests) AND appConfig.forceGlobalSecureRequests)>
			<cfreturn "">
		</cfif>

		<cfset response = service("response")>

		<cftry>
			<cfset force_https(request.YEAR, arguments.request_, response)>

			<cfcatch type="ColdIgniter.HTTP.Exceptions.RedirectException">
				<cfreturn response>
			</cfcatch>
		</cftry>

		<cfreturn "">
	</cffunction>

	<!---
	 * We don't have anything to do here.
	 *
	 * @param arguments_ An empty string, or a list of strings
	--->
	<cffunction name="after" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">
		<cfargument name="arguments_" type="any" required="no" default="">

		<cfreturn "">
	</cffunction>

</cfcomponent>
