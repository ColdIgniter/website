<!---
 * Creates SiteURI using superglobals.
 *
 * Not ported yet: createFromString, and the refresh of the GET values
 * after the query string changes.
--->
<cfcomponent output="no" hint="Creates SiteURI using superglobals">

	<cfset this.appConfig = "">
	<cfset this.superglobals = "">

	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="appConfig" type="any" required="yes">
		<cfargument name="superglobals" type="any" required="yes">

		<cfset this.appConfig = arguments.appConfig>
		<cfset this.superglobals = arguments.superglobals>

		<cfreturn this>
	</cffunction>

	<!---
	 * Create the current URI object from superglobals.
	 *
	 * This method updates superglobal server and get values.
	--->
	<cffunction name="createFromGlobals" access="public" returntype="any" output="no">
		<cfset var routePath = detectRoutePath()>

		<cfreturn createURIFromRoutePath(routePath)>
	</cffunction>

	<!---
	 * Detects the current URI path relative to baseURL based on the URIProtocol
	 * Config setting.
	 *
	 * @param protocol URIProtocol
	 *
	 * @return The route path
	--->
	<cffunction name="detectRoutePath" access="public" returntype="string" output="no">
		<cfargument name="protocol" type="string" required="no" default="">
		<cfset var routePath = "">

		<cfif arguments.protocol EQ "">
			<cfset arguments.protocol = this.appConfig.uriProtocol>
		</cfif>

		<cfif arguments.protocol EQ "REQUEST_URI">
			<cfset routePath = parseRequestURI()>
		<cfelseif arguments.protocol EQ "QUERY_STRING">
			<cfset routePath = parseQueryString()>
		<cfelse>
			<cfset routePath = this.superglobals.server(arguments.protocol)>
			<cfif is_null(routePath)>
				<cfset routePath = parseRequestURI()>
			</cfif>
		</cfif>

		<cfif routePath EQ "/" OR routePath EQ "">
			<cfreturn "/">
		</cfif>

		<cfreturn REReplace(routePath, "^/+", "")>
	</cffunction>

	<!---
	 * Will parse the REQUEST_URI and automatically detect the URI from it,
	 * fixing the query string if necessary.
	 *
	 * This method updates superglobal server and get values.
	 *
	 * @return The route path (before normalization).
	--->
	<cffunction name="parseRequestURI" access="private" returntype="string" output="no">
		<cfset var parts = "">
		<cfset var query = "">
		<cfset var path = "">
		<cfset var segments = "">
		<cfset var keep = "">
		<cfset var script = "">
		<cfset var remainingPath = "">
		<cfset var previousRequestData = "">
		<cfset var get = "">
		<cfset var i = 0>

		<cfif is_null(this.superglobals.server("REQUEST_URI")) OR is_null(this.superglobals.server("SCRIPT_NAME"))>
			<cfreturn "">
		</cfif>

		<!---
		 parse_url() returns false if no host is present, but the path or query
		 string contains a colon followed by a number. So we attach a dummy
		 host since REQUEST_URI does not include the host. This allows us to
		 parse out the query string and path.
		--->
		<cfset parts = parse_url("http://dummy" & this.superglobals.server("REQUEST_URI"))>
		<cfif StructKeyExists(parts, "query")>
			<cfset query = parts["query"]>
		</cfif>
		<cfif StructKeyExists(parts, "path")>
			<cfset path = parts["path"]>
		</cfif>

		<!--- Strip the SCRIPT_NAME path from the URI --->
		<cfif path NEQ "" AND this.superglobals.server("SCRIPT_NAME") NEQ ""
			AND ListLast(this.superglobals.server("SCRIPT_NAME"), ".") EQ "cfm">
			<!--- Compare each segment, dropping them until there is no match --->
			<cfset segments = explode("/", URLDecode(path))>
			<cfset keep = explode("/", path)>
			<cfset script = explode("/", this.superglobals.server("SCRIPT_NAME"))>

			<cfloop from="1" to="#ArrayLen(script)#" index="i">
				<!--- If these segments are not the same then we're done --->
				<cfif i GT ArrayLen(segments) OR Compare(script[i], segments[i]) NEQ 0>
					<cfbreak>
				</cfif>

				<cfset ArrayDeleteAt(keep, 1)>
			</cfloop>

			<cfset path = implode("/", keep)>
		</cfif>

		<!--- Cleanup: if indexPage is still visible in the path, remove it --->
		<cfif this.appConfig.indexPage NEQ "" AND Find(this.appConfig.indexPage, path) EQ 1>
			<cfset remainingPath = substr(path, Len(this.appConfig.indexPage))>

			<!--- Only remove if followed by '/' (route) or nothing (root) --->
			<cfif remainingPath EQ "" OR Left(remainingPath, 1) EQ "/">
				<cfset path = REReplace(remainingPath, "^/+", "")>
			</cfif>
		</cfif>

		<!---
		 This section ensures that even on servers that require the URI to
		 contain the query string (Nginx) a correct URI is found, and also
		 fixes the QUERY_STRING Server var and GET array.
		--->
		<cfif trim_(path, "/") EQ "" AND Left(query, 1) EQ "/">
			<cfset parts = explode("?", query, 2)>
			<cfset path = parts[1]>
			<cfif ArrayLen(parts) GT 1>
				<cfset this.superglobals.setServer("QUERY_STRING", parts[2])>
			<cfelse>
				<cfset this.superglobals.setServer("QUERY_STRING", "")>
			</cfif>
		<cfelse>
			<cfset this.superglobals.setServer("QUERY_STRING", query)>
		</cfif>

		<!--- Refresh only the request values derived from superglobals after GET changes. --->
		<cfset previousRequestData = this.superglobals.getRequestData()>
		<cfset get = parse_str(this.superglobals.server("QUERY_STRING"))>
		<cfset this.superglobals.setGetArray(get)>
		<cfset refreshRequestAfterGetChange(previousRequestData)>

		<cfreturn static_("ColdIgniter\HTTP\URI").removeDotSegments(path)>
	</cffunction>

	<!---
	 * Will parse QUERY_STRING and automatically detect the URI from it.
	 *
	 * This method updates superglobal server and get values.
	 *
	 * @return The route path (before normalization).
	--->
	<cffunction name="parseQueryString" access="private" returntype="string" output="no">
		<cfset var query = this.superglobals.server("QUERY_STRING")>
		<cfset var parts = "">
		<cfset var path = "">
		<cfset var previousRequestData = "">
		<cfset var get = "">

		<cfif trim_(query, "/") EQ "">
			<cfreturn "/">
		</cfif>

		<cfif Left(query, 1) EQ "/">
			<cfset parts = explode("?", query, 2)>
			<cfset path = parts[1]>
			<cfif ArrayLen(parts) GT 1>
				<cfset this.superglobals.setServer("QUERY_STRING", parts[2])>
			<cfelse>
				<cfset this.superglobals.setServer("QUERY_STRING", "")>
			</cfif>
		<cfelse>
			<cfset path = query>
		</cfif>

		<!--- Refresh only the request values derived from superglobals after GET changes. --->
		<cfset previousRequestData = this.superglobals.getRequestData()>
		<cfset get = parse_str(this.superglobals.server("QUERY_STRING"))>
		<cfset this.superglobals.setGetArray(get)>
		<cfset refreshRequestAfterGetChange(previousRequestData)>

		<cfreturn static_("ColdIgniter\HTTP\URI").removeDotSegments(path)>
	</cffunction>

	<!---
	 * Create current URI object.
	 *
	 * @param routePath URI path relative to baseURL
	--->
	<cffunction name="createURIFromRoutePath" access="private" returntype="any" output="no">
		<cfargument name="routePath" type="string" required="yes">
		<cfset var query = this.superglobals.server("QUERY_STRING")>
		<cfset var relativePath = arguments.routePath>

		<cfif query NEQ "">
			<cfset relativePath = arguments.routePath & "?" & query>
		</cfif>

		<cfreturn new_("ColdIgniter\HTTP\SiteURI", this.appConfig, relativePath, getHost())>
	</cffunction>

	<!---
	 * Update REQUEST once during URI parsing, leaving application-defined values alone.
	 *
	 * @param previousRequestData
	--->
	<cffunction name="refreshRequestAfterGetChange" access="private" returntype="void" output="no">
		<cfargument name="previousRequestData" type="any" required="yes">
		<cfset var requestData = this.superglobals.getRequestArray()>
		<cfset var currentData = this.superglobals.getRequestData()>
		<cfset var key = "">
		<cfset var value = "">
		<cfset var same = false>

		<cfloop collection="#arguments.previousRequestData#" item="key">
			<!--- A different value was supplied directly in REQUEST; preserve it. --->
			<cfset same = false>
			<cfif array_key_exists(key, requestData)>
				<cfset value = requestData[key]>
				<cfset same = value.equals(arguments.previousRequestData[key])>
			</cfif>

			<cfif same>
				<cfif array_key_exists(key, currentData)>
					<cfset requestData[key] = currentData[key]>
				<cfelse>
					<cfset requestData.remove(key)>
				</cfif>
			</cfif>
		</cfloop>

		<cfloop collection="#currentData#" item="key">
			<cfif NOT array_key_exists(key, arguments.previousRequestData) AND NOT array_key_exists(key, requestData)>
				<cfset requestData[key] = currentData[key]>
			</cfif>
		</cfloop>

		<cfset this.superglobals.setRequestArray(requestData)>
	</cffunction>

	<!---
	 * @return The current hostname. Returns an empty string if no valid host.
	--->
	<cffunction name="getHost" access="private" returntype="string" output="no">
		<cfset var httpHostPort = this.superglobals.server("HTTP_HOST")>
		<cfset var parts = "">

		<cfif NOT is_null(httpHostPort)>
			<cfset parts = explode(":", httpHostPort, 2)>

			<cfreturn getValidHost(parts[1])>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * @return The valid host (in Config\App::allowedHostnames), or an
	 *         empty string if it is not valid.
	--->
	<cffunction name="getValidHost" access="private" returntype="string" output="no">
		<cfargument name="host" type="string" required="yes">

		<cfif in_array(arguments.host, this.appConfig.allowedHostnames)>
			<cfreturn arguments.host>
		</cfif>

		<cfreturn "">
	</cffunction>

</cfcomponent>
