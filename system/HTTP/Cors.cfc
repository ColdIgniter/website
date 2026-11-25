<!---
 * Cross-Origin Resource Sharing (CORS)
 *
 * The config is a map (see array_()) with the keys allowedOrigins,
 * allowedOriginsPatterns, allowedHeaders, exposedHeaders and
 * allowedMethods (each a list of strings), supportsCredentials (a
 * boolean) and maxAge (a number).
 *
 * Difference: a config that is wrong throws an error of the type
 * "ColdIgniter.Exceptions.ConfigException", as the original throws a
 * ConfigException.
--->
<cfcomponent output="no" hint="Cross-Origin Resource Sharing (CORS)">

	<!---
	 * The config, a map.
	--->
	<cfset this.config = "">

	<!---
	 * @param settings A map of the config, the Config\Cors, or an empty string (null)
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="settings" type="any" required="no" default="">
		<cfset var defaults = array_()>

		<cfset defaults["allowedOrigins"] = ArrayNew(1)>
		<cfset defaults["allowedOriginsPatterns"] = ArrayNew(1)>
		<cfset defaults["supportsCredentials"] = false>
		<cfset defaults["allowedHeaders"] = ArrayNew(1)>
		<cfset defaults["exposedHeaders"] = ArrayNew(1)>
		<cfset defaults["allowedMethods"] = ArrayNew(1)>
		<cfset defaults["maxAge"] = 7200>

		<cfif is_null(arguments.settings)>
			<cfset arguments.settings = config("Config\Cors")>
		</cfif>
		<cfif instanceof_(arguments.settings, "Config\Cors")>
			<cfset arguments.settings = arguments.settings.default>
		</cfif>

		<cfset this.config = array_merge(defaults, arguments.settings)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Creates a new instance by config name.
	--->
	<cffunction name="factory" access="public" returntype="any" output="no">
		<cfargument name="configName" type="string" required="no" default="default">
		<cfset var cfg = config("Config\Cors")>

		<cfreturn new_("ColdIgniter\HTTP\Cors", cfg[arguments.configName])>
	</cffunction>

	<!---
	 * Whether if the request is a preflight request.
	--->
	<cffunction name="isPreflightRequest" access="public" returntype="boolean" output="no">
		<cfargument name="request_" type="any" required="yes">

		<cfreturn arguments.request_.is("OPTIONS") AND arguments.request_.hasHeader("Access-Control-Request-Method")>
	</cffunction>

	<!---
	 * Handles the preflight request, and returns the response.
	--->
	<cffunction name="handlePreflightRequest" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">

		<cfset arguments.response.setStatusCode(204)>

		<cfset setAllowOrigin(arguments.request_, arguments.response)>

		<cfif arguments.response.hasHeader("Access-Control-Allow-Origin")>
			<cfset setAllowHeaders(arguments.response)>
			<cfset setAllowMethods(arguments.response)>
			<cfset setAllowMaxAge(arguments.response)>
			<cfset setAllowCredentials(arguments.response)>
		</cfif>

		<cfreturn arguments.response>
	</cffunction>

	<cffunction name="checkWildcard" access="private" returntype="void" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="count" type="numeric" required="yes">

		<cfif in_array("*", this.config[arguments.name]) AND arguments.count GT 1>
			<cfthrow type="ColdIgniter.Exceptions.ConfigException" message="If wildcard is specified, you must set `'#arguments.name#' => ['*']`. But using wildcard is not recommended.">
		</cfif>
	</cffunction>

	<cffunction name="checkWildcardAndCredentials" access="private" returntype="void" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="header" type="string" required="yes">
		<cfset var list = this.config[arguments.name]>

		<cfif ArrayLen(list) EQ 1 AND Compare(list[1], "*") EQ 0 AND this.config["supportsCredentials"]>
			<cfthrow type="ColdIgniter.Exceptions.ConfigException" message="When responding to a credentialed request, the server must not specify the ""*"" wildcard for the #arguments.header# response-header value.">
		</cfif>
	</cffunction>

	<cffunction name="setAllowOrigin" access="private" returntype="void" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">
		<cfset var originCount = ArrayLen(this.config["allowedOrigins"])>
		<cfset var originPatternCount = ArrayLen(this.config["allowedOriginsPatterns"])>
		<cfset var origin = "">
		<cfset var regex = "">
		<cfset var i = 0>

		<cfset checkWildcard("allowedOrigins", originCount)>
		<cfset checkWildcardAndCredentials("allowedOrigins", "Access-Control-Allow-Origin")>

		<!--- Single Origin. --->
		<cfif originCount EQ 1 AND originPatternCount EQ 0>
			<cfset arguments.response.setHeader("Access-Control-Allow-Origin", this.config["allowedOrigins"][1])>

			<cfreturn>
		</cfif>

		<!--- Multiple Origins. --->
		<cfif NOT arguments.request_.hasHeader("Origin")>
			<cfreturn>
		</cfif>

		<cfset origin = arguments.request_.getHeaderLine("Origin")>

		<cfif originCount GT 1 AND in_array(origin, this.config["allowedOrigins"])>
			<cfset arguments.response.setHeader("Access-Control-Allow-Origin", origin)>
			<cfset arguments.response.appendHeader("Vary", "Origin")>

			<cfreturn>
		</cfif>

		<cfif originPatternCount GT 0>
			<cfloop from="1" to="#originPatternCount#" index="i">
				<cfset regex = "##\A" & this.config["allowedOriginsPatterns"][i] & "\z##">

				<cfif preg_match(regex, origin)>
					<cfset arguments.response.setHeader("Access-Control-Allow-Origin", origin)>
					<cfset arguments.response.appendHeader("Vary", "Origin")>

					<cfreturn>
				</cfif>
			</cfloop>
		</cfif>
	</cffunction>

	<cffunction name="setAllowHeaders" access="private" returntype="void" output="no">
		<cfargument name="response" type="any" required="yes">

		<cfset checkWildcard("allowedHeaders", ArrayLen(this.config["allowedHeaders"]))>
		<cfset checkWildcardAndCredentials("allowedHeaders", "Access-Control-Allow-Headers")>

		<cfset arguments.response.setHeader("Access-Control-Allow-Headers", implode(", ", this.config["allowedHeaders"]))>
	</cffunction>

	<cffunction name="setAllowMethods" access="private" returntype="void" output="no">
		<cfargument name="response" type="any" required="yes">

		<cfset checkWildcard("allowedMethods", ArrayLen(this.config["allowedMethods"]))>
		<cfset checkWildcardAndCredentials("allowedMethods", "Access-Control-Allow-Methods")>

		<cfset arguments.response.setHeader("Access-Control-Allow-Methods", implode(", ", this.config["allowedMethods"]))>
	</cffunction>

	<cffunction name="setAllowMaxAge" access="private" returntype="void" output="no">
		<cfargument name="response" type="any" required="yes">

		<cfset arguments.response.setHeader("Access-Control-Max-Age", "#this.config['maxAge']#")>
	</cffunction>

	<cffunction name="setAllowCredentials" access="private" returntype="void" output="no">
		<cfargument name="response" type="any" required="yes">

		<cfif this.config["supportsCredentials"]>
			<cfset arguments.response.setHeader("Access-Control-Allow-Credentials", "true")>
		</cfif>
	</cffunction>

	<!---
	 * Adds CORS headers to the Response.
	--->
	<cffunction name="addResponseHeaders" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">

		<cfset setAllowOrigin(arguments.request_, arguments.response)>

		<cfif arguments.response.hasHeader("Access-Control-Allow-Origin")>
			<cfset setAllowCredentials(arguments.response)>
			<cfset setExposeHeaders(arguments.response)>
		</cfif>

		<cfreturn arguments.response>
	</cffunction>

	<cffunction name="setExposeHeaders" access="private" returntype="void" output="no">
		<cfargument name="response" type="any" required="yes">

		<cfif ArrayLen(this.config["exposedHeaders"]) GT 0>
			<cfset arguments.response.setHeader("Access-Control-Expose-Headers", implode(", ", this.config["exposedHeaders"]))>
		</cfif>
	</cffunction>

	<!---
	 * Check if response headers were set
	--->
	<cffunction name="hasResponseHeaders" access="public" returntype="boolean" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">

		<cfif NOT arguments.response.hasHeader("Access-Control-Allow-Origin")>
			<cfreturn false>
		</cfif>

		<cfif this.config["supportsCredentials"] AND NOT arguments.response.hasHeader("Access-Control-Allow-Credentials")>
			<cfreturn false>
		</cfif>

		<cfif ArrayLen(this.config["exposedHeaders"]) GT 0>
			<cfif NOT arguments.response.hasHeader("Access-Control-Expose-Headers")>
				<cfreturn false>
			</cfif>

			<cfreturn Find(implode(", ", this.config["exposedHeaders"]), arguments.response.getHeaderLine("Access-Control-Expose-Headers")) GT 0>
		</cfif>

		<cfreturn true>
	</cffunction>

</cfcomponent>
