<!---
 * CSRF filter
--->
<cfcomponent output="no" extends="FilterInterface" hint="CSRF filter">

	<!---
	 * Do whatever processing this filter needs to do.
	 * By default it should not return anything during
	 * normal execution. However, when an abnormal state
	 * is found, it should return an instance of
	 * ColdIgniter\HTTP\Response. If it does, script
	 * execution will end and that Response will be
	 * sent back to the client, allowing for error pages,
	 * redirects, etc.
	 *
	 * @param request_   The request
	 * @param arguments_ An empty string, or a list of strings
	 *
	 * @return A response, or an empty string (null)
	--->
	<cffunction name="before" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="arguments_" type="any" required="no" default="">
		<cfset var security = "">

		<cfif NOT instanceof_(arguments.request_, "ColdIgniter\HTTP\IncomingRequest")>
			<cfreturn "">
		</cfif>

		<cfset security = service("security")>

		<cftry>
			<cfset security.verify(arguments.request_)>

			<cfcatch type="ColdIgniter.Security.Exceptions.SecurityException">
				<cfif security.shouldRedirect() AND NOT arguments.request_.isAJAX()>
					<cfreturn redirect().back().with("error", cfcatch.message)>
				</cfif>

				<cfrethrow>
			</cfcatch>
		</cftry>

		<cfreturn "">
	</cffunction>

	<!---
	 * Allows After filters to inspect and modify the response
	 * object as needed. This method does not allow any way
	 * to stop execution of other after filters, short of
	 * throwing an Exception or Error.
	 *
	 * @param request_   The request
	 * @param response   The response
	 * @param arguments_ An empty string, or a list of strings
	 *
	 * @return A response, or an empty string (null)
	--->
	<cffunction name="after" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">
		<cfargument name="arguments_" type="any" required="no" default="">

		<cfreturn "">
	</cffunction>

</cfcomponent>
