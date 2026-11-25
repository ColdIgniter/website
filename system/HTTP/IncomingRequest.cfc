<!---
 * Class IncomingRequest
 *
 * Represents an incoming, server-side HTTP request.
 *
 * Per the HTTP specification, this interface includes properties for
 * each of the following:
 *
 * - Protocol version
 * - HTTP method
 * - URI
 * - Headers
 * - Message body
 *
 * Additionally, it encapsulates all data as it has arrived to the
 * application from the CGI environment, including:
 *
 * - The values represented in the server values.
 * - Any cookies provided
 * - Query string arguments
 * - Upload files, if any
 * - Deserialized body binds
 *
 * Not ported yet: old input (needs the session). The uploaded files are
 * read when first asked for (see Files/FileCollection.cfc).
--->
<cfcomponent output="no" extends="Request" hint="Represents an incoming, server-side HTTP request">

	<!---
	 * The URI for this request.
	 *
	 * Note: This WILL NOT match the actual URL in the browser since for
	 * everything this cares about (and the router, etc) is the portion
	 * AFTER the baseURL. So, if hosted in a sub-folder this will
	 * appear different than actual URI path. If you need that use getPath().
	--->
	<cfset this.uri = "">

	<!---
	 * The detected URI path (relative to the baseURL).
	 *
	 * Note: current_url() uses this to build its URI,
	 * so this becomes the source for the "current URL"
	 * when working with the share request instance.
	--->
	<cfset this.path = "">

	<!---
	 * The files that have been uploaded with this request.
	--->
	<cfset this.files = "">

	<!---
	 * Holds the negotiator.
	--->
	<cfset this.negotiator = "">

	<!---
	 * Holds the default locale.
	--->
	<cfset this.defaultLocale = "">

	<!---
	 * The current locale of the application.
	 * Default value is set in app/Config/App.cfc
	--->
	<cfset this.locale = "">

	<!---
	 * Stores the valid locale codes.
	--->
	<cfset this.validLocales = ArrayNew(1)>

	<!---
	 * Holds the old data from a redirect.
	--->
	<cfset this.oldInput = StructNew()>

	<!---
	 * The UserAgent instance.
	--->
	<cfset this.userAgent = "">

	<!---
	 * Constructor
	 *
	 * @param config
	 * @param body
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfargument name="uri" type="any" required="no" default="">
		<cfargument name="body" type="any" required="no" default="">
		<cfargument name="userAgent" type="any" required="no" default="">

		<cfif is_null(arguments.uri) OR is_null(arguments.userAgent)>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="You must supply the parameters: uri, userAgent.">
		</cfif>

		<cfset populateHeaders()>

		<!--- The body of the request is read here, where the original reads the input stream. --->
		<!--- The input stream is not available with enctype="multipart/form-data". --->
		<cfif is_null(arguments.body)
			AND Find("multipart/form-data", getHeaderLine("Content-Type")) EQ 0
			AND Val(getHeaderLine("Content-Length")) LTE getPostMaxSize(ini_get("post_max_size"))>
			<cfset arguments.body = http_request_data().content>
		</cfif>

		<!--- A body that is not text comes as binary data. --->
		<cfif IsBinary(arguments.body)>
			<cfset arguments.body = ToString(arguments.body)>
		</cfif>

		<cfset this.uri = arguments.uri>
		<cfset this.body = arguments.body>
		<cfset this.userAgent = arguments.userAgent>
		<cfset this.validLocales = arguments.config.supportedLocales>

		<cfset super.__construct(arguments.config)>

		<cfif StructKeyExists(arguments.uri, "getRoutePath")>
			<cfset setPath(arguments.uri.getRoutePath())>
		<cfelse>
			<cfset setPath(arguments.uri.getPath())>
		</cfif>

		<cfset detectLocale(arguments.config)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Gets the number of bytes of a post_max_size value.
	 *
	 * A value of 0 or less means unlimited.
	 *
	 * Difference: the value comes from ini_get("post_max_size"), which holds
	 * what ini_set() has kept, as the server has no ini file; an option that was
	 * not set is an empty string, which is 0 and so unlimited. The unlimited
	 * value is 9223372036854775807. The prefixes of hex, octal and binary
	 * (0x, 0, 0b, 0o) are read as the original does, with the suffix K, M or G.
	 *
	 * @param postMaxSize
	--->
	<cffunction name="getPostMaxSize" access="private" returntype="numeric" output="no">
		<cfargument name="postMaxSize" type="string" required="yes">
		<cfset var text = LCase(Trim(arguments.postMaxSize))>
		<cfset var match = REFind("^([-+]?)(0x[0-9a-f]+|0b[01]+|0o[0-7]+|[0-9]+)([kmg]?)", text, 1, true)>
		<cfset var sign = "">
		<cfset var digits = "">
		<cfset var suffix = "">
		<cfset var bytes = 0>
		<cfset var radix = 10>

		<cfif match.pos[1] EQ 0>
			<cfreturn 9223372036854775807>
		</cfif>

		<cfset sign = Mid(text, match.pos[2], match.len[2])>
		<cfset digits = Mid(text, match.pos[3], match.len[3])>
		<cfset suffix = Mid(text, match.pos[4], match.len[4])>

		<cfif Left(digits, 2) EQ "0x">
			<cfset radix = 16>
			<cfset digits = Mid(digits, 3, Len(digits))>
		<cfelseif Left(digits, 2) EQ "0o">
			<cfset radix = 8>
			<cfset digits = Mid(digits, 3, Len(digits))>
		<cfelseif Left(digits, 2) EQ "0b">
			<cfset radix = 2>
			<cfset digits = Mid(digits, 3, Len(digits))>
		<cfelseif Len(digits) GT 1 AND Left(digits, 1) EQ "0">
			<cfset radix = 8>
			<cfset digits = Mid(digits, 2, Len(digits))>
		</cfif>

		<cfif radix EQ 10>
			<cfset bytes = Val(digits)>
		<cfelse>
			<cfset bytes = CreateObject("java", "java.lang.Long").parseLong(JavaCast("string", digits), JavaCast("int", radix))>
		</cfif>

		<cfif suffix EQ "k">
			<cfset bytes = bytes * 1024>
		<cfelseif suffix EQ "m">
			<cfset bytes = bytes * 1048576>
		<cfelseif suffix EQ "g">
			<cfset bytes = bytes * 1073741824>
		</cfif>

		<cfif sign EQ "-">
			<cfset bytes = 0 - bytes>
		</cfif>

		<cfif bytes LTE 0>
			<cfreturn 9223372036854775807>
		</cfif>

		<cfreturn bytes>
	</cffunction>

	<!---
	 * Handles setting up the locale, perhaps auto-detecting through
	 * content negotiation.
	 *
	 * @param config
	--->
	<cffunction name="detectLocale" access="public" returntype="void" output="no">
		<cfargument name="config" type="any" required="yes">

		<cfset this.defaultLocale = arguments.config.defaultLocale>
		<cfset this.locale = this.defaultLocale>

		<cfif NOT arguments.config.negotiateLocale>
			<cfreturn>
		</cfif>

		<cfset setLocale_(negotiate("language", arguments.config.supportedLocales))>
	</cffunction>

	<!---
	 * Provides a convenient way to work with the Negotiate class
	 * for content negotiation.
	 *
	 * @param supported list of strings
	--->
	<cffunction name="negotiate" access="public" returntype="string" output="no">
		<cfargument name="type" type="string" required="yes">
		<cfargument name="supported" type="array" required="yes">
		<cfargument name="strictMatch" type="boolean" required="no" default="false">

		<cfif is_null(this.negotiator)>
			<cfset this.negotiator = service("negotiator", this, true)>
		</cfif>

		<cfswitch expression="#LCase(arguments.type)#">
			<cfcase value="media">
				<cfreturn this.negotiator.media(arguments.supported, arguments.strictMatch)>
			</cfcase>
			<cfcase value="charset">
				<cfreturn this.negotiator.charset(arguments.supported)>
			</cfcase>
			<cfcase value="encoding">
				<cfreturn this.negotiator.encoding(arguments.supported)>
			</cfcase>
			<cfcase value="language">
				<cfreturn this.negotiator.language(arguments.supported)>
			</cfcase>
		</cfswitch>

		<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="""#arguments.type#"" is not a valid negotiation type. Must be one of: media, charset, encoding, language.">
	</cffunction>

	<!---
	 * Checks this request type.
	--->
	<cffunction name="is" access="public" returntype="boolean" output="no">
		<cfargument name="type" type="string" required="yes">
		<cfset var valueUpper = UCase(arguments.type)>
		<cfset var httpMethods = static_("ColdIgniter\HTTP\Method").all()>

		<cfif in_array(valueUpper, httpMethods)>
			<cfreturn Compare(getMethod(), valueUpper) EQ 0>
		</cfif>

		<cfif valueUpper EQ "JSON">
			<cfreturn Find("application/json", getHeaderLine("Content-Type")) GT 0>
		</cfif>

		<cfif valueUpper EQ "AJAX">
			<cfreturn isAJAX()>
		</cfif>

		<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Unknown type: #arguments.type#">
	</cffunction>

	<!---
	 * Determines if this request was made from the command line (CLI).
	--->
	<cffunction name="isCLI" access="public" returntype="boolean" output="no">
		<cfreturn false>
	</cffunction>

	<!---
	 * Test to see if a request contains the HTTP_X_REQUESTED_WITH header.
	--->
	<cffunction name="isAJAX" access="public" returntype="boolean" output="no">
		<cfif NOT hasHeader("X-Requested-With")>
			<cfreturn false>
		</cfif>

		<cfreturn Compare(LCase(header("X-Requested-With").getValue()), "xmlhttprequest") EQ 0>
	</cffunction>

	<!---
	 * Attempts to detect if the current connection is secure through
	 * a few different methods.
	 *
	 * Difference: a request header can supply the HTTPS variable on the
	 * server (verified: "HTTPS: on" made the original check true), and the
	 * servlet request and SERVER_PORT_SECURE can be changed the same way,
	 * so no value of the server is safe on its own. The server value is
	 * read through server_value() (see Common.cfm), which returns nothing
	 * when the request has a header of that name, so a forged request is
	 * not secure.
	 *
	 * A front end that itself sets a header named HTTPS on real https
	 * requests makes the variable read as empty, so the request counts as
	 * not secure (and ForceHTTPS would redirect forever). Such a set-up has
	 * to be configured as a trusted proxy with X-Forwarded-Proto instead.
	 *
	 * X-Forwarded-Proto and Front-End-Https are request headers by nature.
	 * As in the original they count only when the request comes from a
	 * trusted proxy (App::proxyIPs), which is not changed.
	--->
	<cffunction name="isSecure" access="public" returntype="boolean" output="no">
		<cfset var https = service("superglobals").server("HTTPS")>
		<cfset var proto = "">
		<cfset var frontEndHttps = "">

		<cfif NOT is_null(https) AND LCase(https) NEQ "off">
			<cfreturn true>
		</cfif>

		<cfif NOT isFromTrustedProxy()>
			<cfreturn false>
		</cfif>

		<cfif hasHeader("X-Forwarded-Proto")>
			<cfset proto = header("X-Forwarded-Proto").getValue()>

			<cfif LCase(Trim(proto)) EQ "https">
				<cfreturn true>
			</cfif>
		</cfif>

		<cfif NOT hasHeader("Front-End-Https")>
			<cfreturn false>
		</cfif>

		<cfset frontEndHttps = header("Front-End-Https").getValue()>

		<cfreturn frontEndHttps NEQ "" AND Compare(frontEndHttps, "0") NEQ 0 AND LCase(frontEndHttps) NEQ "off">
	</cffunction>

	<!---
	 * Returns the URI path relative to baseURL,
	 * running detection as necessary.
	--->
	<cffunction name="getPath" access="public" returntype="string" output="no">
		<cfreturn this.path>
	</cffunction>

	<!---
	 * Sets the relative path and updates the URI object.
	 *
	 * Note: Since current_url() accesses the shared request
	 * instance, this can be used to change the "current URL"
	 * for testing.
	 *
	 * @param path URI path relative to baseURL
	--->
	<cffunction name="setPath" access="public" returntype="any" output="no">
		<cfargument name="path" type="string" required="yes">

		<cfset this.path = arguments.path>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the locale string for this request.
	 *
	 * Named with an underscore, because SetLocale is a built-in function.
	--->
	<cffunction name="setLocale_" access="public" returntype="any" output="no">
		<cfargument name="locale" type="string" required="yes">

		<!--- If it's not a valid locale, set it to the default locale for the site. --->
		<cfif NOT in_array(arguments.locale, this.validLocales)>
			<cfset arguments.locale = this.defaultLocale>
		</cfif>

		<cfset this.locale = arguments.locale>

		<!--- Not ported yet: Locale::setDefault, the locale of the server is not changed --->

		<cfreturn this>
	</cffunction>

	<!---
	 * Set the valid locales.
	 *
	 * @param locales list of strings
	--->
	<cffunction name="setValidLocales" access="public" returntype="any" output="no">
		<cfargument name="locales" type="array" required="yes">

		<cfset this.validLocales = arguments.locales>

		<cfreturn this>
	</cffunction>

	<!---
	 * Gets the current locale, with a fallback to the default
	 * locale if none is set.
	 *
	 * Named with an underscore, because GetLocale is a built-in function.
	--->
	<cffunction name="getLocale_" access="public" returntype="string" output="no">
		<cfreturn this.locale>
	</cffunction>

	<!---
	 * Returns the default locale as set in app/Config/App.cfc
	--->
	<cffunction name="getDefaultLocale" access="public" returntype="string" output="no">
		<cfreturn this.defaultLocale>
	</cffunction>

	<!---
	 * Fetch an item from JSON input stream with fallback to the request array. This is the simplest way
	 * to grab data from the request object and can be used in lieu of the
	 * other get* methods in most cases.
	 *
	 * @param index  A name, an array of names, or an empty string (null) for all values
	 * @param filter Filter constant
	 * @param flags
	--->
	<cffunction name="getVar" access="public" returntype="any" output="no">
		<cfargument name="index" type="any" required="no" default="">
		<cfargument name="filter" type="any" required="no" default="">
		<cfargument name="flags" type="any" required="no" default="">

		<cfif Find("application/json", getHeaderLine("Content-Type")) GT 0
			AND NOT is_null(this.body)>
			<cfreturn getJsonVar(arguments.index, false, arguments.filter, arguments.flags)>
		</cfif>

		<cfreturn fetchGlobal("request", arguments.index, arguments.filter, arguments.flags)>
	</cffunction>

	<!---
	 * A convenience method that grabs the raw input stream and decodes
	 * the JSON into an array.
	 *
	 * If assoc is true, then all objects in the response will be converted
	 * to associative arrays.
	 *
	 * @param assoc   Whether to return objects as associative arrays
	 * @param depth   How many levels deep to decode
	 * @param options Bitmask of options
	 *
	 * Difference: json_decode() has no assoc, depth or options arguments (an
	 * object is always a map, the depth is cut at 32), only the option
	 * JSON_THROW_ON_ERROR (4194304) is read. The text of a number, true,
	 * false comes back as it is written, and a bare null as an empty string (null), see json_decode(). The
	 * message of the exception is the one of the language file HTTP, which
	 * is not ported, written in place.
	 *
	 * @throws HTTPException When the body is invalid as JSON.
	--->
	<cffunction name="getJSON" access="public" returntype="any" output="no">
		<cfargument name="assoc" type="boolean" required="no" default="false">
		<cfargument name="depth" type="numeric" required="no" default="512">
		<cfargument name="options" type="numeric" required="no" default="0">

		<cfset var result = "">

		<cfif is_null(this.body)>
			<cfreturn "">
		</cfif>

		<cftry>
			<cfset result = json_decode(this.body, "", true)>

			<cfcatch type="ColdIgniter.JsonException">
				<!--- JSON_THROW_ON_ERROR (4194304) keeps the JsonException --->
				<cfif BitAnd(arguments.options, 4194304) NEQ 0>
					<cfrethrow>
				</cfif>

				<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="Failed to parse JSON string. Error: #cfcatch.message#">
			</cfcatch>
		</cftry>

		<cfreturn result>
	</cffunction>

	<!---
	 * Get a specific variable from a JSON input stream
	 *
	 * @param index  The variable that you want which can use dot syntax for getting specific values.
	 * @param assoc  If true, return the result as an associative array.
	 * @param filter Filter Constant
	 * @param flags  Option
	--->
	<cffunction name="getJsonVar" access="public" returntype="any" output="no">
		<cfargument name="index" type="any" required="no" default="">
		<cfargument name="assoc" type="boolean" required="no" default="false">
		<cfargument name="filter" type="any" required="no" default="">
		<cfargument name="flags" type="any" required="no" default="">
		<cfset var data = getJSON(true)>
		<cfset var result = "">
		<cfset var key = "">
		<cfset var i = 0>
		<cfset var filtering = true>

		<cfif NOT is_array(data)>
			<cfreturn "">
		</cfif>

		<cfif IsSimpleValue(arguments.index) AND NOT is_null(arguments.index)>
			<cfset data = static_("ColdIgniter\Helpers\Array\ArrayHelper").dotSearch(arguments.index, data)>
		<cfelseif IsArray(arguments.index)>
			<cfset result = CreateObject("java", "java.util.LinkedHashMap").init()>

			<cfloop from="1" to="#ArrayLen(arguments.index)#" index="i">
				<cfset key = arguments.index[i]>
				<cfset result[key] = static_("ColdIgniter\Helpers\Array\ArrayHelper").dotSearch(key, data)>
			</cfloop>

			<cfset data = result>
		</cfif>

		<!--- Difference: a value that is not there and a null are an empty string, which is not filtered. --->
		<!--- no filter (null or FILTER_UNSAFE_RAW) and no flags (null, 0 or an empty map): nothing to apply --->
		<cfif arguments.filter EQ "" OR arguments.filter EQ 516>
			<cfif IsSimpleValue(arguments.flags)>
				<cfif arguments.flags EQ "" OR arguments.flags EQ 0>
					<cfset filtering = false>
				</cfif>
			<cfelseif IsStruct(arguments.flags)>
				<cfif StructIsEmpty(arguments.flags)>
					<cfset filtering = false>
				</cfif>
			</cfif>
		</cfif>

		<cfif filtering AND NOT is_null(data)>
			<cfif IsArray(data) OR IsStruct(data)>
				<!--- array_walk_recursive with filter_var, on a copy --->
				<cfset data = filter_walk_(data, arguments.filter, arguments.flags)>
			<cfelseif IsSimpleValue(data)>
				<cfset data = filter_value_(data, arguments.filter, arguments.flags)>
			</cfif>
		</cfif>

		<!--- Difference: an object is a map whether assoc is set or not (there is no object type), so the conversion with json_decode(json_encode()) is not done. --->

		<cfreturn data>
	</cffunction>

	<!---
	 * A convenience method that grabs the raw input stream(send method in PUT, PATCH, DELETE) and decodes
	 * the String into an array.
	--->
	<cffunction name="getRawInput" access="public" returntype="any" output="no">
		<cfreturn parse_str(this.body)>
	</cffunction>

	<!---
	 * Gets a specific variable from raw input stream (send method in PUT, PATCH, DELETE).
	 *
	 * @param index  The variable that you want which can use dot syntax for getting specific values.
	 * @param filter Filter Constant
	 * @param flags  Option
	--->
	<cffunction name="getRawInputVar" access="public" returntype="any" output="no">
		<cfargument name="index" type="any" required="no" default="">
		<cfargument name="filter" type="any" required="no" default="">
		<cfargument name="flags" type="any" required="no" default="">
		<cfset var output = parse_str(this.body)>
		<cfset var data = "">
		<cfset var key = "">
		<cfset var i = 0>
		<cfset var filtering = true>

		<!--- Not ported yet: helper('array'), the helpers are not loaded. The array helper is called directly. --->

		<cfif IsSimpleValue(arguments.index) AND NOT is_null(arguments.index)>
			<cfset output = static_("ColdIgniter\Helpers\Array\ArrayHelper").dotSearch(arguments.index, output)>
		<cfelseif IsArray(arguments.index)>
			<cfset data = CreateObject("java", "java.util.LinkedHashMap").init()>

			<cfloop from="1" to="#ArrayLen(arguments.index)#" index="i">
				<cfset key = arguments.index[i]>
				<cfset data[key] = static_("ColdIgniter\Helpers\Array\ArrayHelper").dotSearch(key, output)>
			</cfloop>

			<cfset output = data>
		</cfif>

		<!--- Difference: a value that is not there and a null are an empty string, which is not filtered. --->
		<!--- no filter (null or FILTER_UNSAFE_RAW) and no flags (null, 0 or an empty map): nothing to apply --->
		<cfif arguments.filter EQ "" OR arguments.filter EQ 516>
			<cfif IsSimpleValue(arguments.flags)>
				<cfif arguments.flags EQ "" OR arguments.flags EQ 0>
					<cfset filtering = false>
				</cfif>
			<cfelseif IsStruct(arguments.flags)>
				<cfif StructIsEmpty(arguments.flags)>
					<cfset filtering = false>
				</cfif>
			</cfif>
		</cfif>

		<cfif filtering AND NOT is_null(output)>
			<cfif IsArray(output) OR IsStruct(output)>
				<!--- array_walk_recursive with filter_var, on a copy --->
				<cfreturn filter_walk_(output, arguments.filter, arguments.flags)>
			</cfif>

			<cfif IsSimpleValue(output)>
				<cfreturn filter_value_(output, arguments.filter, arguments.flags)>
			</cfif>
		</cfif>

		<cfreturn output>
	</cffunction>

	<!---
	 * Fetch an item from GET data.
	 *
	 * @param index  Index for item to fetch from the get values.
	 * @param filter A filter name to apply.
	 * @param flags
	--->
	<cffunction name="getGet" access="public" returntype="any" output="no">
		<cfargument name="index" type="any" required="no" default="">
		<cfargument name="filter" type="any" required="no" default="">
		<cfargument name="flags" type="any" required="no" default="">

		<cfreturn fetchGlobal("get", arguments.index, arguments.filter, arguments.flags)>
	</cffunction>

	<!---
	 * Fetch an item from POST.
	 *
	 * @param index  Index for item to fetch from the post values.
	 * @param filter A filter name to apply
	 * @param flags
	--->
	<cffunction name="getPost" access="public" returntype="any" output="no">
		<cfargument name="index" type="any" required="no" default="">
		<cfargument name="filter" type="any" required="no" default="">
		<cfargument name="flags" type="any" required="no" default="">

		<cfreturn fetchGlobal("post", arguments.index, arguments.filter, arguments.flags)>
	</cffunction>

	<!---
	 * Fetch an item from POST data with fallback to GET.
	 *
	 * @param index  Index for item to fetch from the post or get values
	 * @param filter A filter name to apply
	 * @param flags
	--->
	<cffunction name="getPostGet" access="public" returntype="any" output="no">
		<cfargument name="index" type="any" required="no" default="">
		<cfargument name="filter" type="any" required="no" default="">
		<cfargument name="flags" type="any" required="no" default="">
		<cfset var output = "">
		<cfset var key = "">
		<cfset var i = 0>

		<cfif is_null(arguments.index)>
			<cfreturn array_merge(getGet(arguments.index, arguments.filter, arguments.flags), getPost(arguments.index, arguments.filter, arguments.flags))>
		</cfif>

		<cfif IsArray(arguments.index)>
			<cfset output = CreateObject("java", "java.util.LinkedHashMap").init()>

			<cfloop from="1" to="#ArrayLen(arguments.index)#" index="i">
				<cfset key = arguments.index[i]>
				<cfset output[key] = getPostGet(key, arguments.filter, arguments.flags)>
			</cfloop>

			<cfreturn output>
		</cfif>

		<!---
		 Use the post values directly here, since filter_has_var only
		 checks the initial POST data, not anything that might
		 have been added since.
		--->
		<cfif array_key_exists(arguments.index, service("superglobals").getPostArray())>
			<cfreturn getPost(arguments.index, arguments.filter, arguments.flags)>
		<cfelseif array_key_exists(arguments.index, service("superglobals").getGetArray())>
			<cfreturn getGet(arguments.index, arguments.filter, arguments.flags)>
		</cfif>

		<cfreturn getPost(arguments.index, arguments.filter, arguments.flags)>
	</cffunction>

	<!---
	 * Fetch an item from GET data with fallback to POST.
	 *
	 * @param index  Index for item to be fetched from the get or post values
	 * @param filter A filter name to apply
	 * @param flags
	--->
	<cffunction name="getGetPost" access="public" returntype="any" output="no">
		<cfargument name="index" type="any" required="no" default="">
		<cfargument name="filter" type="any" required="no" default="">
		<cfargument name="flags" type="any" required="no" default="">
		<cfset var output = "">
		<cfset var key = "">
		<cfset var i = 0>

		<cfif is_null(arguments.index)>
			<cfreturn array_merge(getPost(arguments.index, arguments.filter, arguments.flags), getGet(arguments.index, arguments.filter, arguments.flags))>
		</cfif>

		<cfif IsArray(arguments.index)>
			<cfset output = CreateObject("java", "java.util.LinkedHashMap").init()>

			<cfloop from="1" to="#ArrayLen(arguments.index)#" index="i">
				<cfset key = arguments.index[i]>
				<cfset output[key] = getGetPost(key, arguments.filter, arguments.flags)>
			</cfloop>

			<cfreturn output>
		</cfif>

		<!---
		 Use the get values directly here, since filter_has_var only
		 checks the initial GET data, not anything that might
		 have been added since.
		--->
		<cfif array_key_exists(arguments.index, service("superglobals").getGetArray())>
			<cfreturn getGet(arguments.index, arguments.filter, arguments.flags)>
		<cfelseif array_key_exists(arguments.index, service("superglobals").getPostArray())>
			<cfreturn getPost(arguments.index, arguments.filter, arguments.flags)>
		</cfif>

		<cfreturn getGet(arguments.index, arguments.filter, arguments.flags)>
	</cffunction>

	<!---
	 * Fetch an item from the COOKIE array.
	 *
	 * @param index  Index for item to be fetched from the cookie values
	 * @param filter A filter name to be applied
	 * @param flags
	--->
	<cffunction name="getCookie" access="public" returntype="any" output="no">
		<cfargument name="index" type="any" required="no" default="">
		<cfargument name="filter" type="any" required="no" default="">
		<cfargument name="flags" type="any" required="no" default="">

		<cfreturn fetchGlobal("cookie", arguments.index, arguments.filter, arguments.flags)>
	</cffunction>

	<!---
	 * Fetch the user agent string
	 *
	 * @return UserAgent
	--->
	<cffunction name="getUserAgent" access="public" returntype="any" output="no">
		<cfreturn this.userAgent>
	</cffunction>

	<!---
	 * Attempts to get old Input data that has been flashed to the session
	 * with redirect_with_input(). It first checks for the data in the old
	 * POST data, then the old GET data and finally check for dot arrays
	--->
	<cffunction name="getOldInput" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfset var old = "">
		<cfset var value = "">

		<!--- If the session hasn't been started, we're done. --->
		<cfif Compare(session_status(), "active") NEQ 0>
			<cfreturn "">
		</cfif>

		<!--- Get previously saved in session --->
		<cfset old = session_("_ci_old_input")>

		<!--- If no data was previously saved, we're done. --->
		<cfif is_null(old)>
			<cfreturn "">
		</cfif>

		<!--- Check for the value in the POST array first. --->
		<cfif IsStruct(old) AND StructKeyExists(old, "post") AND IsStruct(old["post"]) AND StructKeyExists(old["post"], arguments.key)>
			<cfreturn old["post"][arguments.key]>
		</cfif>

		<!--- Next check in the GET array. --->
		<cfif IsStruct(old) AND StructKeyExists(old, "get") AND IsStruct(old["get"]) AND StructKeyExists(old["get"], arguments.key)>
			<cfreturn old["get"][arguments.key]>
		</cfif>

		<cfset helper("array")>

		<!--- Check for an array value in POST. --->
		<cfif IsStruct(old) AND StructKeyExists(old, "post")>
			<cfset value = dot_array_search(arguments.key, old["post"])>
			<cfif NOT is_null(value)>
				<cfreturn value>
			</cfif>
		</cfif>

		<!--- Check for an array value in GET. --->
		<cfif IsStruct(old) AND StructKeyExists(old, "get")>
			<cfset value = dot_array_search(arguments.key, old["get"])>
			<cfif NOT is_null(value)>
				<cfreturn value>
			</cfif>
		</cfif>

		<!--- requested session key not found --->
		<cfreturn "">
	</cffunction>

	<!---
	 * Returns an array of all files that have been uploaded with this
	 * request. Each file is represented by an UploadedFile instance.
	--->
	<cffunction name="getFiles" access="public" returntype="any" output="no">
		<cfif is_null(this.files)>
			<cfset this.files = new_("ColdIgniter\HTTP\Files\FileCollection")>
		</cfif>

		<cfreturn this.files.all()><!--- return all files --->
	</cffunction>

	<!---
	 * Verify if a file exist, by the name of the input field used to upload it, in the collection
	 * of uploaded files and if is have been uploaded with multiple option.
	--->
	<cffunction name="getFileMultiple" access="public" returntype="any" output="no">
		<cfargument name="fileID" type="string" required="yes">

		<cfif is_null(this.files)>
			<cfset this.files = new_("ColdIgniter\HTTP\Files\FileCollection")>
		</cfif>

		<cfreturn this.files.getFileMultiple(arguments.fileID)>
	</cffunction>

	<!---
	 * Retrieves a single file by the name of the input field used
	 * to upload it.
	--->
	<cffunction name="getFile" access="public" returntype="any" output="no">
		<cfargument name="fileID" type="string" required="yes">

		<cfif is_null(this.files)>
			<cfset this.files = new_("ColdIgniter\HTTP\Files\FileCollection")>
		</cfif>

		<cfreturn this.files.getFile(arguments.fileID)>
	</cffunction>

</cfcomponent>
