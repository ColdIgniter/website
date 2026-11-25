<!---
 * Abstraction for a uniform resource identifier (URI).
 *
 * The query is kept as a string here; the original keeps it as an array.
 *
 * Not ported yet: the query variables (getQuery options, stripQuery,
 * keepQuery), resolveRelativeURI, the encoding of the path, the default
 * ports and showPassword.
 *
 * Difference: addQuery() and setQueryArray() read the query string into a
 * map (parse_str) and write it back (http_build_query), as it is kept as a
 * string. A null value (an empty string) removes the key, as
 * http_build_query() leaves a null out.
 *
 * Difference: there is no clone operator. clone_() makes a copy.
--->
<cfcomponent output="no" hint="Abstraction for a uniform resource identifier (URI)">

	<!---
	 * Sub-delimiters used in query strings and fragments.
	--->
	<cfset this.CHAR_SUB_DELIMS = "!\$&'\(\)\*\+,;=">

	<!---
	 * Unreserved characters used in paths, query strings, and fragments.
	--->
	<cfset this.CHAR_UNRESERVED = "a-zA-Z0-9_\-\.~">

	<!---
	 * The URI segments.
	 *
	 * Starts at 1 instead of 0
	--->
	<cfset this.segments = ArrayNew(1)>

	<!---
	 * The URI Scheme.
	--->
	<cfset this.scheme = "http">

	<!---
	 * URI User Info
	--->
	<cfset this.user = "">

	<!---
	 * URI User Password
	--->
	<cfset this.password = "">

	<!---
	 * URI Host
	--->
	<cfset this.host = "">

	<!---
	 * URI Port
	--->
	<cfset this.port = "">

	<!---
	 * URI path.
	--->
	<cfset this.path = "">

	<!---
	 * The name of any fragment.
	--->
	<cfset this.fragment = "">

	<!---
	 * The query string.
	--->
	<cfset this.query = "">

	<!---
	 * Whether to throw exceptions on bad segments, or to stay silent.
	--->
	<cfset this.silent = false>

	<!---
	 * Builds a representation of the string from the component parts.
	 *
	 * @param scheme URI scheme. E.g., http, ftp
	 *
	 * @return URI string with only passed parts. Maybe incomplete as a URI.
	--->
	<cffunction name="createURIString" access="public" returntype="string" output="no">
		<cfargument name="scheme" type="string" required="no" default="">
		<cfargument name="authority" type="string" required="no" default="">
		<cfargument name="path" type="string" required="no" default="">
		<cfargument name="query" type="string" required="no" default="">
		<cfargument name="fragment" type="string" required="no" default="">
		<cfset var uri = "">

		<cfif arguments.scheme NEQ "">
			<cfset uri = uri & arguments.scheme & "://">
		</cfif>

		<cfif arguments.authority NEQ "">
			<cfset uri = uri & arguments.authority>
		</cfif>

		<cfif arguments.path NEQ "">
			<cfif Right(uri, 1) EQ "/">
				<cfset uri = uri & REReplace(arguments.path, "^/+", "")>
			<cfelse>
				<cfset uri = uri & "/" & REReplace(arguments.path, "^/+", "")>
			</cfif>
		</cfif>

		<cfif arguments.query NEQ "">
			<cfset uri = uri & "?" & arguments.query>
		</cfif>

		<cfif arguments.fragment NEQ "">
			<cfset uri = uri & "##" & arguments.fragment>
		</cfif>

		<cfreturn uri>
	</cffunction>

	<!---
	 * Used when resolving and merging paths to correctly interpret and
	 * remove single and double dot segments from the path per
	 * RFC 3986 Section 5.2.4
	 *
	 * @see http://tools.ietf.org/html/rfc3986#section-5.2.4
	--->
	<cffunction name="removeDotSegments" access="public" returntype="string" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfset var output = ArrayNew(1)>
		<cfset var input = "">
		<cfset var result = "">
		<cfset var i = 0>

		<cfif arguments.path EQ "" OR arguments.path EQ "/">
			<cfreturn arguments.path>
		</cfif>

		<cfset input = explode("/", arguments.path)>

		<!--- This is not a perfect solution, but is close enough --->
		<cfloop from="1" to="#ArrayLen(input)#" index="i">
			<cfif input[i] EQ "..">
				<cfif ArrayLen(output) GT 0>
					<cfset ArrayDeleteAt(output, ArrayLen(output))>
				</cfif>
			<cfelseif input[i] NEQ "." AND input[i] NEQ "">
				<cfset ArrayAppend(output, input[i])>
			</cfif>
		</cfloop>

		<cfset result = implode("/", output)>
		<cfset result = trim_(result, "/ ")>

		<!--- Add leading slash if necessary --->
		<cfif Left(arguments.path, 1) EQ "/">
			<cfset result = "/" & result>
		</cfif>

		<!--- Add trailing slash if necessary --->
		<cfif result NEQ "/" AND Right(arguments.path, 1) EQ "/">
			<cfset result = result & "/">
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * Constructor.
	 *
	 * @param uri The URI to parse.
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="uri" type="string" required="no" default="">

		<cfif NOT is_null(arguments.uri)>
			<cfset setURI(arguments.uri)>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets and overwrites any current URI information.
	--->
	<cffunction name="setURI" access="public" returntype="any" output="no">
		<cfargument name="uri" type="string" required="no" default="">
		<cfset var parts = "">

		<cfif NOT is_null(arguments.uri)>
			<cfset parts = parse_url(arguments.uri)>

			<cfif StructCount(parts) EQ 0>
				<cfif this.silent>
					<cfreturn this>
				</cfif>

				<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="Unable to parse URI: ""#arguments.uri#""">
			</cfif>

			<cfset applyParts(parts)>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * If $silent == true, then will not throw exceptions and will
	 * attempt to continue gracefully.
	 *
	 * @return URI
	--->
	<cffunction name="setSilent" access="public" returntype="any" output="no">
		<cfargument name="silent" type="boolean" required="no" default="true">

		<cfset this.silent = arguments.silent>

		<cfreturn this>
	</cffunction>

	<!---
	 * Makes a copy of this URI, the stand-in for the clone operator. The
	 * object is made without calling __construct() and the properties are
	 * copied (a list is duplicated).
	 *
	 * @return URI
	--->
	<cffunction name="clone_" access="public" returntype="any" output="no">
		<cfset var copy = request.ColdIgniter.autoloader.instantiate(this.__class)>
		<cfset var key = "">

		<cfloop collection="#this#" item="key">
			<cfif NOT IsCustomFunction(this[key])>
				<cfif IsArray(this[key])>
					<cfset copy[key] = Duplicate(this[key])>
				<cfelse>
					<cfset copy[key] = this[key]>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn copy>
	</cffunction>

	<!---
	 * Retrieve the scheme component of the URI.
	--->
	<cffunction name="getScheme" access="public" returntype="string" output="no">
		<cfreturn this.scheme>
	</cffunction>

	<!---
	 * Retrieve the authority component of the URI.
	 *
	 * The authority syntax of the URI is:
	 *
	 * [user-info@]host[:port]
	--->
	<cffunction name="getAuthority" access="public" returntype="string" output="no">
		<cfargument name="ignorePort" type="boolean" required="no" default="false">
		<cfset var authority = "">
		<cfset var userInfo = "">

		<cfif this.host EQ "">
			<cfreturn "">
		</cfif>

		<cfset authority = this.host>

		<cfset userInfo = getUserInfo()>
		<cfif userInfo NEQ "">
			<cfset authority = userInfo & "@" & authority>
		</cfif>

		<!--- Don't add port if it's a standard port for this scheme --->
		<cfif this.port NEQ "" AND NOT arguments.ignorePort
			AND NOT (this.scheme EQ "http" AND this.port EQ 80)
			AND NOT (this.scheme EQ "https" AND this.port EQ 443)>
			<cfset authority = authority & ":" & this.port>
		</cfif>

		<cfreturn authority>
	</cffunction>

	<!---
	 * Retrieve the user information component of the URI.
	--->
	<cffunction name="getUserInfo" access="public" returntype="string" output="no">
		<cfreturn this.user>
	</cffunction>

	<!---
	 * Retrieve the host component of the URI.
	--->
	<cffunction name="getHost" access="public" returntype="string" output="no">
		<cfreturn this.host>
	</cffunction>

	<!---
	 * Retrieve the port component of the URI.
	--->
	<cffunction name="getPort" access="public" returntype="any" output="no">
		<cfreturn this.port>
	</cffunction>

	<!---
	 * Retrieve the path component of the URI.
	--->
	<cffunction name="getPath" access="public" returntype="string" output="no">
		<cfreturn this.path>
	</cffunction>

	<!---
	 * Retrieve the query string
	--->
	<cffunction name="getQuery" access="public" returntype="string" output="no">
		<cfreturn this.query>
	</cffunction>

	<!---
	 * Retrieve a URI fragment
	--->
	<cffunction name="getFragment" access="public" returntype="string" output="no">
		<cfreturn this.fragment>
	</cffunction>

	<!---
	 * Returns the segments of the path as an array.
	--->
	<cffunction name="getSegments" access="public" returntype="array" output="no">
		<cfreturn this.segments>
	</cffunction>

	<!---
	 * Returns the value of a specific segment of the URI path.
	 * Allows to get only existing segments or the next one.
	 *
	 * @param number   Segment number starting at 1
	 * @param default  Default value
	 *
	 * @return The value of the segment. If you specify the last +1
	 *         segment, the default value. If you specify the last +2
	 *         or more throws HTTPException.
	--->
	<cffunction name="getSegment" access="public" returntype="string" output="no">
		<cfargument name="number" type="numeric" required="yes">
		<cfargument name="default" type="string" required="no" default="">

		<cfif arguments.number LT 1>
			<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="Request URI segment is out of range: #arguments.number#">
		</cfif>

		<cfif arguments.number GT ArrayLen(this.segments) + 1 AND NOT this.silent>
			<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="Request URI segment is out of range: #arguments.number#">
		</cfif>

		<cfif arguments.number GT ArrayLen(this.segments)>
			<cfreturn arguments.default>
		</cfif>

		<cfreturn this.segments[arguments.number]>
	</cffunction>

	<!---
	 * Sets the value of a specific segment of the URI path.
	 * Allows to set only existing segments or add new one.
	 *
	 * @param number Segment number starting at 1
	 * @param value  The segment value
	 *
	 * @return URI
	--->
	<cffunction name="setSegment" access="public" returntype="any" output="no">
		<cfargument name="number" type="numeric" required="yes">
		<cfargument name="value" type="any" required="yes">

		<cfif arguments.number LT 1>
			<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="Request URI segment is out of range: #arguments.number#">
		</cfif>

		<cfif arguments.number GT ArrayLen(this.segments) + 1>
			<cfif this.silent>
				<cfreturn this>
			</cfif>

			<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="Request URI segment is out of range: #arguments.number#">
		</cfif>

		<cfif arguments.number EQ ArrayLen(this.segments) + 1>
			<cfset ArrayAppend(this.segments, arguments.value)>
		<cfelse>
			<cfset this.segments[arguments.number] = arguments.value>
		</cfif>

		<cfreturn refreshPath()>
	</cffunction>

	<!---
	 * Returns the total number of segments.
	--->
	<cffunction name="getTotalSegments" access="public" returntype="numeric" output="no">
		<cfreturn ArrayLen(this.segments)>
	</cffunction>

	<!---
	 * Formats the URI as a string.
	 *
	 * Warning: For backwards-compatability this method
	 * assumes URIs with the same host as baseURL should
	 * be relative to the project's configuration.
	 * This aspect of __toString() is deprecated and should be avoided.
	--->
	<cffunction name="__toString" access="public" returntype="string" output="no">
		<cfreturn createURIString(getScheme(), getAuthority(), getPath(), getQuery(), getFragment())>
	</cffunction>

	<!---
	 * Sets the scheme for this URI.
	 *
	 * Because of the large number of valid schemes we cannot limit this
	 * to only http or https.
	 *
	 * @see https://www.iana.org/assignments/uri-schemes/uri-schemes.xhtml
	--->
	<cffunction name="setScheme" access="public" returntype="any" output="no">
		<cfargument name="str" type="string" required="yes">

		<cfset arguments.str = LCase(arguments.str)>
		<cfset this.scheme = REReplace(arguments.str, "[^a-z0-9\.\+-]+", "", "all")>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the userInfo/Authority portion of the URI.
	 *
	 * @param user The user's username
	 * @param pass The user's password
	--->
	<cffunction name="setUserInfo" access="public" returntype="any" output="no">
		<cfargument name="user" type="string" required="yes">
		<cfargument name="pass" type="string" required="yes">

		<cfset this.user = Trim(arguments.user)>
		<cfset this.password = Trim(arguments.pass)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the host name to use.
	--->
	<cffunction name="setHost" access="public" returntype="any" output="no">
		<cfargument name="str" type="string" required="yes">

		<cfset this.host = Trim(arguments.str)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the port portion of the URI.
	--->
	<cffunction name="setPort" access="public" returntype="any" output="no">
		<cfargument name="port" type="any" required="no" default="">

		<cfif is_null(arguments.port)>
			<cfreturn this>
		</cfif>

		<cfif arguments.port GT 0 AND arguments.port LTE 65535>
			<cfset this.port = arguments.port>

			<cfreturn this>
		</cfif>

		<cfif this.silent>
			<cfreturn this>
		</cfif>

		<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="Invalid port given: #arguments.port#">
	</cffunction>

	<!---
	 * Sets the path portion of the URI.
	--->
	<cffunction name="setPath" access="public" returntype="any" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfset var tempPath = "">

		<cfset this.path = filterPath(arguments.path)>

		<cfset tempPath = trim_(this.path, "/")>

		<cfif tempPath EQ "">
			<cfset this.segments = ArrayNew(1)>
		<cfelse>
			<cfset this.segments = explode("/", tempPath)>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the query portion of the URI, while attempting
	 * to clean the various parts of the query keys and values.
	--->
	<cffunction name="setQuery" access="public" returntype="any" output="no">
		<cfargument name="query" type="string" required="yes">

		<cfif Find("##", arguments.query) GT 0>
			<cfif this.silent>
				<cfreturn this>
			</cfif>

			<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="Query strings may not include URI fragments.">
		</cfif>

		<!--- Can't have leading ? --->
		<cfif arguments.query NEQ "" AND Left(arguments.query, 1) EQ "?">
			<cfset arguments.query = substr(arguments.query, 1)>
		</cfif>

		<cfset this.query = arguments.query>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the query portion of the URI, from a map of the variables.
	 *
	 * @return URI
	--->
	<cffunction name="setQueryArray" access="public" returntype="any" output="no">
		<cfargument name="query" type="any" required="yes">

		<cfreturn setQuery(http_build_query(arguments.query))>
	</cffunction>

	<!---
	 * Adds a single new element to the query vars. A null value (an empty
	 * string) takes the key out.
	 *
	 * @return URI
	--->
	<cffunction name="addQuery" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="value" type="any" required="no" default="">
		<cfset var vars = parse_str(this.query)>

		<cfif is_null(arguments.value)>
			<cfset vars.remove(arguments.key)>
		<cfelse>
			<cfset vars[arguments.key] = arguments.value>
		</cfif>

		<cfset this.query = http_build_query(vars)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the path from the segments, and the segments from the path.
	 *
	 * @return URI
	--->
	<cffunction name="refreshPath" access="public" returntype="any" output="no">
		<cfset var tempPath = "">

		<cfset this.path = filterPath(implode("/", this.segments))>

		<cfset tempPath = trim_(this.path, "/")>

		<cfif tempPath EQ "">
			<cfset this.segments = ArrayNew(1)>
		<cfelse>
			<cfset this.segments = explode("/", tempPath)>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the fragment portion of the URI.
	 *
	 * @see https://tools.ietf.org/html/rfc3986#section-3.5
	--->
	<cffunction name="setFragment" access="public" returntype="any" output="no">
		<cfargument name="string" type="string" required="yes">

		<cfset this.fragment = trim_(Trim(arguments.string), "## ")>

		<cfreturn this>
	</cffunction>

	<!---
	 * Encodes any dangerous characters, and removes dot segments.
	 * While dot segments have valid uses according to the spec,
	 * this URI class does not allow them.
	 *
	 * Not ported yet: the decoding and encoding of the characters.
	--->
	<cffunction name="filterPath" access="private" returntype="string" output="no">
		<cfargument name="path" type="string" required="no" default="">
		<cfset var orig = arguments.path>

		<!--- Remove dot segments --->
		<cfset arguments.path = removeDotSegments(arguments.path)>

		<!--- Fix up some leading slash edge cases... --->
		<cfif Left(orig, 2) EQ "./">
			<cfset arguments.path = "/" & arguments.path>
		</cfif>
		<cfif Left(orig, 3) EQ "../">
			<cfset arguments.path = "/" & arguments.path>
		</cfif>

		<cfreturn arguments.path>
	</cffunction>

	<!---
	 * Saves our parts from a parse_url call.
	--->
	<cffunction name="applyParts" access="private" returntype="void" output="no">
		<cfargument name="parts" type="any" required="yes">

		<cfif StructKeyExists(arguments.parts, "host") AND arguments.parts["host"] NEQ "">
			<cfset this.host = arguments.parts["host"]>
		</cfif>

		<cfif StructKeyExists(arguments.parts, "user") AND arguments.parts["user"] NEQ "">
			<cfset this.user = arguments.parts["user"]>
		</cfif>

		<cfif StructKeyExists(arguments.parts, "path") AND arguments.parts["path"] NEQ "">
			<cfset this.path = filterPath(arguments.parts["path"])>
		</cfif>

		<cfif StructKeyExists(arguments.parts, "query") AND arguments.parts["query"] NEQ "">
			<cfset setQuery(arguments.parts["query"])>
		</cfif>

		<cfif StructKeyExists(arguments.parts, "fragment") AND arguments.parts["fragment"] NEQ "">
			<cfset this.fragment = arguments.parts["fragment"]>
		</cfif>

		<cfif StructKeyExists(arguments.parts, "scheme")>
			<cfset setScheme(REReplace(arguments.parts["scheme"], "[:/]+$", ""))>
		<cfelse>
			<cfset setScheme("http")>
		</cfif>

		<cfif StructKeyExists(arguments.parts, "port")>
			<!--- Valid port numbers are enforced by earlier parse_url or setPort() --->
			<cfset this.port = arguments.parts["port"]>
		</cfif>

		<cfif StructKeyExists(arguments.parts, "pass")>
			<cfset this.password = arguments.parts["pass"]>
		</cfif>

		<!--- Populate our segments array --->
		<cfif StructKeyExists(arguments.parts, "path") AND arguments.parts["path"] NEQ "">
			<cfset this.segments = explode("/", trim_(arguments.parts["path"], "/"))>
			<cfif ArrayLen(this.segments) EQ 1 AND this.segments[1] EQ "">
				<cfset this.segments = ArrayNew(1)>
			</cfif>
		</cfif>
	</cffunction>

</cfcomponent>
