<!---
 * Page Cache filter
 *
 * Not ported yet: DownloadResponse and CLIRequest.
--->
<cfcomponent output="no" extends="FilterInterface" hint="Page Cache filter">

	<!---
	 * @var ResponseCache
	--->
	<cfset this.pageCache = "">

	<!---
	 * @var array of status codes
	--->
	<cfset this.cacheStatusCodes = ArrayNew(1)>

	<!---
	 * @param config The Cache config, or an empty string (null)
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\Cache")>
		</cfif>

		<cfset this.pageCache = service("responsecache")>
		<cfset this.cacheStatusCodes = arguments.config.cacheStatusCodes>

		<cfreturn this>
	</cffunction>

	<!---
	 * Checks page cache and return if found.
	 *
	 * @param request_   The request
	 * @param arguments_ An empty string, or a list of strings
	 *
	 * @return A response, or an empty string (null)
	--->
	<cffunction name="before" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="arguments_" type="any" required="no" default="">
		<cfset var response = service("response")>

		<cfreturn this.pageCache.get(arguments.request_, response)>
	</cffunction>

	<!---
	 * Cache the page.
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
		<cfset var allowed = false>
		<cfset var i = 0>

		<cfif ArrayLen(this.cacheStatusCodes) EQ 0>
			<cfset allowed = true>
		<cfelse>
			<cfloop index="i" from="1" to="#ArrayLen(this.cacheStatusCodes)#">
				<cfif arguments.response.getStatusCode() EQ this.cacheStatusCodes[i]>
					<cfset allowed = true>
				</cfif>
			</cfloop>
		</cfif>

		<cfif NOT instanceof_(arguments.response, "ColdIgniter\HTTP\RedirectResponse") AND allowed>
			<!---
			 Cache it without the performance metrics replaced
			 so that we can have live speed updates along the way.
			 Must be run after filters to preserve the Response headers.
			--->
			<cfset this.pageCache.make(arguments.request_, arguments.response)>

			<cfreturn arguments.response>
		</cfif>

		<cfreturn "">
	</cffunction>

</cfcomponent>
