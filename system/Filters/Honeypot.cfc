<!---
 * Honeypot filter
--->
<cfcomponent output="no" extends="FilterInterface" hint="Honeypot filter">

	<!---
	 * Checks if Honeypot field is empty, if not then the
	 * requester is a bot
	 *
	 * @param request_   The request
	 * @param arguments_ An empty string, or a list of strings
	 *
	 * @return An empty string (null)
	--->
	<cffunction name="before" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="arguments_" type="any" required="no" default="">

		<cfif NOT instanceof_(arguments.request_, "ColdIgniter\HTTP\IncomingRequest")>
			<cfreturn "">
		</cfif>

		<cfif service("honeypot").hasContent(arguments.request_)>
			<cfset static_("ColdIgniter\Honeypot\Exceptions\HoneypotException").isBot()>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * Attach a honeypot to the current response.
	 *
	 * @param request_   The request
	 * @param response   The response
	 * @param arguments_ An empty string, or a list of strings
	 *
	 * @return An empty string (null)
	--->
	<cffunction name="after" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">
		<cfargument name="arguments_" type="any" required="no" default="">

		<cfset service("honeypot").attachHoneypot(arguments.response)>

		<cfreturn "">
	</cffunction>

</cfcomponent>
