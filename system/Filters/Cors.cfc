<!---
 * CORS filter
--->
<cfcomponent output="no" extends="FilterInterface" hint="CORS filter">

	<!---
	 * The Cors service, or an empty string (null) before it is made.
	--->
	<cfset this.cors = "">

	<!---
	 * @param config A map of the config, or an empty string. Used for testing only.
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">

		<cfif NOT is_null(arguments.config) AND NOT StructIsEmpty(arguments.config)>
			<cfset this.cors = new_("ColdIgniter\HTTP\Cors", arguments.config)>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * @param request_   The request
	 * @param arguments_ An empty string, or a list of strings
	 *
	 * @return A response, or an empty string (null)
	--->
	<cffunction name="before" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="arguments_" type="any" required="no" default="">
		<cfset var response = "">

		<cfif NOT instanceof_(arguments.request_, "ColdIgniter\HTTP\IncomingRequest")>
			<cfreturn "">
		</cfif>

		<cfset createCorsService(arguments.arguments_)>

		<cfset response = service("response")>

		<cfif this.cors.isPreflightRequest(arguments.request_)>
			<cfset response = this.cors.handlePreflightRequest(arguments.request_, response)>

			<!---
			 Always adds `Vary: Access-Control-Request-Method` header for cacheability.
			 If there is an intermediate cache server such as a CDN, if a plain
			 OPTIONS request is sent, it may be cached. But valid preflight requests
			 have this header, so it will be cached separately.
			--->
			<cfset response.appendHeader("Vary", "Access-Control-Request-Method")>

			<cfreturn response>
		</cfif>

		<cfif arguments.request_.is("OPTIONS")>
			<!--- Same reason for the Vary header as above. --->
			<cfset response.appendHeader("Vary", "Access-Control-Request-Method")>
		</cfif>

		<cfset this.cors.addResponseHeaders(arguments.request_, response)>

		<cfreturn "">
	</cffunction>

	<cffunction name="createCorsService" access="private" returntype="void" output="no">
		<cfargument name="arguments_" type="any" required="yes">

		<cfif NOT IsObject(this.cors)>
			<cfif is_null(arguments.arguments_)>
				<cfset this.cors = static_("ColdIgniter\HTTP\Cors").factory()>
			<cfelse>
				<cfset this.cors = static_("ColdIgniter\HTTP\Cors").factory(arguments.arguments_[1])>
			</cfif>
		</cfif>
	</cffunction>

	<!---
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

		<cfif NOT instanceof_(arguments.request_, "ColdIgniter\HTTP\IncomingRequest")>
			<cfreturn "">
		</cfif>

		<cfset createCorsService(arguments.arguments_)>

		<cfif this.cors.hasResponseHeaders(arguments.request_, arguments.response)>
			<cfreturn "">
		</cfif>

		<!--- Same reason for the Vary header as in before(). --->
		<cfif arguments.request_.is("OPTIONS")>
			<cfset arguments.response.appendHeader("Vary", "Access-Control-Request-Method")>
		</cfif>

		<cfreturn this.cors.addResponseHeaders(arguments.request_, arguments.response)>
	</cffunction>

</cfcomponent>
