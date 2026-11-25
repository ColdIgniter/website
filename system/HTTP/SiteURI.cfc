<!---
 * URI for the application site
--->
<cfcomponent output="no" extends="URI" hint="URI for the application site">

	<!---
	 * The current baseURL.
	--->
	<cfset this.baseURL = "">

	<!---
	 * The path part of baseURL.
	 *
	 * The baseURL "http://example.com/" => "/"
	 * The baseURL "http://localhost:8888/ci431/public/" => "/ci431/public/"
	--->
	<cfset this.basePathWithoutIndexPage = "">

	<!---
	 * The Index File.
	--->
	<cfset this.indexPage = "">

	<!---
	 * List of URI segments in baseURL and indexPage.
	 *
	 * If the URI is "http://localhost:8888/ci431/public/index.cfm/test?a=b",
	 * and the baseURL is "http://localhost:8888/ci431/public/", then:
	 *   array(
	 *     1 => 'ci431',
	 *     2 => 'public',
	 *     3 => 'index.cfm',
	 *   );
	--->
	<cfset this.baseSegments = ArrayNew(1)>

	<!---
	 * URI path relative to baseURL.
	 *
	 * If the baseURL contains sub folders, this value will be different from
	 * the current URI path.
	 *
	 * This value never starts with '/'.
	--->
	<cfset this.routePath = "">

	<!---
	 * @param relativePath URI path relative to baseURL. May include
	 *                     queries or fragments.
	 * @param host         Optional current hostname.
	 * @param scheme       Optional scheme. 'http' or 'https'.
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="configApp" type="any" required="yes">
		<cfargument name="relativePath" type="string" required="no" default="">
		<cfargument name="host" type="string" required="no" default="">
		<cfargument name="scheme" type="string" required="no" default="">
		<cfset var relative = "">
		<cfset var routePath = "">
		<cfset var query = "">
		<cfset var fragment = "">
		<cfset var indexPageRoutePath = "">
		<cfset var uri = "">
		<cfset var parts = "">

		<cfset this.indexPage = arguments.configApp.indexPage>

		<cfset this.baseURL = determineBaseURL(arguments.configApp, arguments.host, arguments.scheme)>

		<cfset setBasePath()>

		<!--- Fix routePath, query, fragment --->
		<cfset relative = parseRelativePath(arguments.relativePath)>
		<cfset routePath = relative[1]>
		<cfset query = relative[2]>
		<cfset fragment = relative[3]>

		<!--- Fix indexPage and routePath --->
		<cfset indexPageRoutePath = getIndexPageRoutePath(routePath)>

		<!--- Fix the current URI --->
		<cfset uri = this.baseURL.__toString() & indexPageRoutePath>

		<!--- applyParts --->
		<cfset parts = parse_url(uri)>
		<cfif StructCount(parts) EQ 0>
			<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="Unable to parse URI: ""#uri#""">
		</cfif>
		<cfset parts["query"] = query>
		<cfset parts["fragment"] = fragment>
		<cfset applyParts(parts)>

		<cfset setRoutePath(routePath)>

		<cfreturn this>
	</cffunction>

	<cffunction name="parseRelativePath" access="private" returntype="array" output="no">
		<cfargument name="relativePath" type="string" required="yes">
		<cfset var parts = parse_url("http://dummy/" & arguments.relativePath)>
		<cfset var result = ArrayNew(1)>

		<cfif StructCount(parts) EQ 0>
			<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="Unable to parse URI: ""#arguments.relativePath#""">
		</cfif>

		<cfif arguments.relativePath EQ "/">
			<cfset ArrayAppend(result, "/")>
		<cfelse>
			<cfset ArrayAppend(result, REReplace(parts["path"], "^/+", ""))>
		</cfif>

		<cfif StructKeyExists(parts, "query")>
			<cfset ArrayAppend(result, parts["query"])>
		<cfelse>
			<cfset ArrayAppend(result, "")>
		</cfif>

		<cfif StructKeyExists(parts, "fragment")>
			<cfset ArrayAppend(result, parts["fragment"])>
		<cfelse>
			<cfset ArrayAppend(result, "")>
		</cfif>

		<cfreturn result>
	</cffunction>

	<cffunction name="determineBaseURL" access="private" returntype="any" output="no">
		<cfargument name="configApp" type="any" required="yes">
		<cfargument name="host" type="string" required="no" default="">
		<cfargument name="scheme" type="string" required="no" default="">
		<cfset var baseURL = normalizeBaseURL(arguments.configApp)>

		<cfset var uri = new_("ColdIgniter\HTTP\URI", baseURL)>

		<!--- Update scheme --->
		<cfif arguments.scheme NEQ "">
			<cfset uri.setScheme(arguments.scheme)>
		<cfelseif arguments.configApp.forceGlobalSecureRequests>
			<cfset uri.setScheme("https")>
		</cfif>

		<!--- Update host --->
		<cfif NOT is_null(arguments.host)>
			<cfset uri.setHost(arguments.host)>
		</cfif>

		<cfreturn uri>
	</cffunction>

	<cffunction name="getIndexPageRoutePath" access="private" returntype="string" output="no">
		<cfargument name="routePath" type="string" required="yes">
		<cfset var indexPage = "">
		<cfset var indexPageRoutePath = "">

		<!--- Remove starting slash unless it is `/`. --->
		<cfif arguments.routePath NEQ "" AND Left(arguments.routePath, 1) EQ "/" AND arguments.routePath NEQ "/">
			<cfset arguments.routePath = REReplace(arguments.routePath, "^/+", "")>
		</cfif>

		<!--- Check for an index page --->
		<cfif this.indexPage NEQ "">
			<cfset indexPage = this.indexPage>

			<!--- Check if we need a separator --->
			<cfif arguments.routePath NEQ "" AND Left(arguments.routePath, 1) NEQ "/" AND Left(arguments.routePath, 1) NEQ "?">
				<cfset indexPage = indexPage & "/">
			</cfif>
		</cfif>

		<cfset indexPageRoutePath = indexPage & arguments.routePath>

		<cfif indexPageRoutePath EQ "/">
			<cfset indexPageRoutePath = "">
		</cfif>

		<cfreturn indexPageRoutePath>
	</cffunction>

	<cffunction name="normalizeBaseURL" access="private" returntype="string" output="no">
		<cfargument name="configApp" type="any" required="yes">

		<!---
		 It's possible the user forgot a trailing slash on their
		 baseURL, so let's help them out.
		--->
		<cfset var baseURL = REReplace(arguments.configApp.baseURL, "[/ ]+$", "") & "/">

		<!--- Validate baseURL --->
		<cfif REFind("^[A-Za-z][A-Za-z0-9+.-]*://[^/ ]+/", baseURL) EQ 0>
			<cfthrow type="ColdIgniter.Config.Exceptions.ConfigException" message="Config\App::baseURL ""#baseURL#"" is not a valid URL.">
		</cfif>

		<cfreturn baseURL>
	</cffunction>

	<!---
	 * Sets basePathWithoutIndexPage and baseSegments.
	--->
	<cffunction name="setBasePath" access="private" returntype="void" output="no">
		<cfset this.basePathWithoutIndexPage = this.baseURL.getPath()>

		<cfset this.baseSegments = convertToSegments(this.basePathWithoutIndexPage)>

		<cfif this.indexPage NEQ "">
			<cfset ArrayAppend(this.baseSegments, this.indexPage)>
		</cfif>
	</cffunction>

	<!---
	 * Returns the baseURL.
	--->
	<cffunction name="getBaseURL" access="public" returntype="string" output="no">
		<cfreturn this.baseURL.__toString()>
	</cffunction>

	<!---
	 * Returns the URI path relative to baseURL.
	 *
	 * @return The Route path.
	--->
	<cffunction name="getRoutePath" access="public" returntype="string" output="no">
		<cfreturn this.routePath>
	</cffunction>

	<!---
	 * Sets the path portion of the URI. The path is relative to baseURL.
	 *
	 * @return SiteURI
	--->
	<cffunction name="setPath" access="public" returntype="any" output="no">
		<cfargument name="path" type="string" required="yes">

		<cfset setRoutePath(arguments.path)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the route path (and segments).
	--->
	<cffunction name="setRoutePath" access="private" returntype="void" output="no">
		<cfargument name="routePath" type="string" required="yes">
		<cfset var indexPageRoutePath = "">

		<cfset arguments.routePath = filterPath(arguments.routePath)>

		<cfset indexPageRoutePath = getIndexPageRoutePath(arguments.routePath)>

		<cfset this.path = this.basePathWithoutIndexPage & indexPageRoutePath>

		<cfset this.routePath = REReplace(arguments.routePath, "^/+", "")>

		<cfset this.segments = convertToSegments(this.routePath)>
	</cffunction>

	<!---
	 * Sets the path portion of the URI based on segments.
	 *
	 * @return SiteURI
	--->
	<cffunction name="refreshPath" access="public" returntype="any" output="no">
		<cfset var allSegments = array_merge(this.baseSegments, this.segments)>

		<cfset this.path = "/" & filterPath(implode("/", allSegments))>

		<cfif this.routePath EQ "/" AND this.path NEQ "/">
			<cfset this.path = this.path & "/">
		</cfif>

		<cfset this.routePath = filterPath(implode("/", this.segments))>

		<cfreturn this>
	</cffunction>

	<!---
	 * Converts path to segments
	--->
	<cffunction name="convertToSegments" access="private" returntype="array" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfset var tempPath = trim_(arguments.path, "/")>

		<cfif tempPath EQ "">
			<cfreturn ArrayNew(1)>
		</cfif>

		<cfreturn explode("/", tempPath)>
	</cffunction>

	<!---
	 * For base_url() helper.
	 * Named baseUrl_ because the baseURL property has the same name in CFML.
	 *
	 *
	 * Not in the original: with no scheme argument the scheme is null, so
	 * the argument is left out; an empty string asks for a
	 * protocol-relative link.
	 *
	 * @param relativePath URI string or array of URI segments.
	 * @param scheme       URI scheme. E.g., http, ftp. If empty
	 *                     string '' is set, a protocol-relative
	 *                     link is returned.
	--->
	<cffunction name="baseUrl_" access="public" returntype="string" output="no">
		<cfargument name="relativePath" type="any" required="no" default="">
		<cfargument name="scheme" type="string" required="no">
		<cfset var shared = config("Config\App")>
		<cfset var config_ = config("Config\App", false)>
		<cfset var key = "">
		<cfset var host = "">
		<cfset var scheme_ = "">
		<cfset var uri = "">

		<cfset arguments.relativePath = stringifyRelativePath(arguments.relativePath)>

		<!--- clone config_ of the shared config: a copy of its values --->
		<cfloop collection="#shared#" item="key">
			<cfif NOT IsCustomFunction(shared[key])>
				<cfset config_[key] = shared[key]>
			</cfif>
		</cfloop>
		<cfset config_.indexPage = "">

		<cfset host = getHost()>

		<cfif IsDefined("arguments.scheme")>
			<cfset scheme_ = arguments.scheme>
		</cfif>

		<cfset uri = new_("ColdIgniter\HTTP\SiteURI", config_, arguments.relativePath, host, scheme_)>

		<!--- Support protocol-relative links --->
		<cfif IsDefined("arguments.scheme") AND arguments.scheme EQ "">
			<cfreturn substr(uri.__toString(), Len(uri.getScheme()) + 1)>
		</cfif>

		<cfreturn uri.__toString()>
	</cffunction>

	<!---
	 * @param relativePath URI string or array of URI segments
	--->
	<cffunction name="stringifyRelativePath" access="private" returntype="string" output="no">
		<cfargument name="relativePath" type="any" required="yes">

		<cfif IsArray(arguments.relativePath)>
			<cfreturn implode("/", arguments.relativePath)>
		</cfif>

		<cfreturn arguments.relativePath>
	</cffunction>

	<!---
	 * For site_url() helper.
	 *
	 * Not in the original: with no scheme or config argument the value is
	 * null, so the argument is left out (see baseUrl_).
	 *
	 * @param relativePath URI string or array of URI segments.
	 * @param scheme       URI scheme. E.g., http, ftp. If empty
	 *                     string '' is set, a protocol-relative
	 *                     link is returned.
	 * @param config       Alternate configuration to use.
	--->
	<cffunction name="siteUrl" access="public" returntype="string" output="no">
		<cfargument name="relativePath" type="any" required="no" default="">
		<cfargument name="scheme" type="string" required="no">
		<cfargument name="config_" type="any" required="no">
		<cfset var host = "">
		<cfset var appConfig = "">
		<cfset var scheme_ = "">
		<cfset var uri = "">

		<cfset arguments.relativePath = stringifyRelativePath(arguments.relativePath)>

		<!--- Check current host. --->
		<cfif NOT IsDefined("arguments.config_")>
			<cfset host = getHost()>
			<cfset appConfig = config("Config\App")>
		<cfelse>
			<cfset appConfig = arguments.config_>
		</cfif>

		<cfif IsDefined("arguments.scheme")>
			<cfset scheme_ = arguments.scheme>
		</cfif>

		<cfset uri = new_("ColdIgniter\HTTP\SiteURI", appConfig, arguments.relativePath, host, scheme_)>

		<!--- Support protocol-relative links --->
		<cfif IsDefined("arguments.scheme") AND arguments.scheme EQ "">
			<cfreturn substr(uri.__toString(), Len(uri.getScheme()) + 1)>
		</cfif>

		<cfreturn uri.__toString()>
	</cffunction>

</cfcomponent>
