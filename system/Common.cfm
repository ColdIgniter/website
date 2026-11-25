<!---
 * Common Functions
 *
 * Several application-wide utility methods.
 *
 * Not ported yet: every function that is not listed below.
--->

<!---
 * A convenience method to get the cache service, or an item of it.
 *
 * Examples:
 *    cache("foo")      // Returns the item "foo", or an empty string (null)
 *    cache()           // Returns the cache service
 *
 * Difference: a cached empty string reads as a miss.
 *
 * @param key The key of an item, or omitted (null) for the service
--->
<cffunction name="cache" returntype="any" output="no" hint="A convenience method that provides access to the cache object">
	<cfargument name="key" type="string" required="no">
	<cfset var cache_ = service("cache")>

	<cfif NOT StructKeyExists(arguments, "key")>
		<cfreturn cache_>
	</cfif>

	<cfreturn cache_.get(arguments.key)>
</cffunction>

<!---
 * A convenience method to clean paths for
 * a nicer looking output. Useful for exception
 * handling, error logging, etc.
 *
 * Not ported yet: VENDORPATH
--->
<cffunction name="clean_path" returntype="string" output="no" hint="A convenience method to clean paths for a nicer looking output">
	<cfargument name="path" type="string" required="yes">
	<cfset var resolved = "">

	<!--- Resolve relative paths --->
	<cfset resolved = realpath(arguments.path)>
	<cfif resolved NEQ "">
		<cfset arguments.path = resolved>
	</cfif>

	<cfif Compare(Left(arguments.path, Len(request.APPPATH)), request.APPPATH) EQ 0>
		<cfreturn "APPPATH" & request.DIRECTORY_SEPARATOR & Mid(arguments.path, Len(request.APPPATH) + 1, Len(arguments.path))>
	<cfelseif Compare(Left(arguments.path, Len(request.SYSTEMPATH)), request.SYSTEMPATH) EQ 0>
		<cfreturn "SYSTEMPATH" & request.DIRECTORY_SEPARATOR & Mid(arguments.path, Len(request.SYSTEMPATH) + 1, Len(arguments.path))>
	<cfelseif Compare(Left(arguments.path, Len(request.FCPATH)), request.FCPATH) EQ 0>
		<cfreturn "FCPATH" & request.DIRECTORY_SEPARATOR & Mid(arguments.path, Len(request.FCPATH) + 1, Len(arguments.path))>
	<cfelseif Compare(Left(arguments.path, Len(request.ROOTPATH)), request.ROOTPATH) EQ 0>
		<cfreturn "ROOTPATH" & request.DIRECTORY_SEPARATOR & Mid(arguments.path, Len(request.ROOTPATH) + 1, Len(arguments.path))>
	</cfif>

	<cfreturn arguments.path>
</cffunction>

<!---
 * More simple way of getting config instances from Factories
 *
 * @param name     The config class name
 * @param getShared Whether to return the shared instance
 *
 * @return The config instance, or an empty string if it is not found
--->
<cffunction name="config" returntype="any" output="no" hint="More simple way of getting config instances from Factories">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="getShared" type="boolean" required="no" default="true">
	<cfset var arguments_ = ArrayNew(1)>
	<cfset var options = StructNew()>

	<cfif arguments.getShared>
		<cfreturn static_("ColdIgniter\Config\Factories").get("config", arguments.name)>
	</cfif>

	<cfset options["getShared"] = arguments.getShared>
	<cfset ArrayAppend(arguments_, arguments.name)>
	<cfset ArrayAppend(arguments_, options)>

	<cfreturn static_("ColdIgniter\Config\Factories").__callStatic("config", arguments_)>
</cffunction>

<!---
 * Returns the nonce attribute for style tags, or an empty string when the
 * content security policy is off.
 *
 * Difference: the policy object is only asked once the config says that the
 * policy is on, so a request with the policy off does not make it.
--->
<cffunction name="csp_style_nonce" returntype="string" output="no" hint="Returns the nonce attribute for style tags">

	<cfif NOT config("Config\App").CSPEnabled>
		<cfreturn "">
	</cfif>

	<cfreturn 'nonce="' & service("csp").getStyleNonce() & '"'>
</cffunction>

<!---
 * Returns the nonce attribute for script tags, or an empty string when the
 * content security policy is off. See csp_style_nonce().
--->
<cffunction name="csp_script_nonce" returntype="string" output="no" hint="Returns the nonce attribute for script tags">

	<cfif NOT config("Config\App").CSPEnabled>
		<cfreturn "">
	</cfif>

	<cfreturn 'nonce="' & service("csp").getScriptNonce() & '"'>
</cffunction>

<!---
 * Returns the CSRF token name.
 * Can be used in Views when building hidden inputs manually,
 * or used in javascript vars when using APIs.
--->
<cffunction name="csrf_token" returntype="string" output="no" hint="Returns the CSRF token name">

	<cfreturn service("security").getTokenName()>
</cffunction>

<!---
 * Returns the CSRF header name.
 * Can be used in Views by adding it to the meta tag
 * or used in javascript to define a header name when using APIs.
--->
<cffunction name="csrf_header" returntype="string" output="no" hint="Returns the CSRF header name">

	<cfreturn service("security").getHeaderName()>
</cffunction>

<!---
 * Returns the current hash value for the CSRF protection.
 * Can be used in Views when building hidden inputs manually,
 * or used in javascript vars for API usage.
--->
<cffunction name="csrf_hash" returntype="string" output="no" hint="Returns the current hash value for the CSRF protection">

	<cfreturn service("security").getHash()>
</cffunction>

<!---
 * Generates a hidden input field for use within manually generated forms.
 *
 * @param id An empty string (null), or a non-empty string
--->
<cffunction name="csrf_field" returntype="string" output="no" hint="Generates a hidden input field for use within manually generated forms">
	<cfargument name="id" type="string" required="no" default="">
	<cfset var idAttribute = "">

	<cfif NOT is_null(arguments.id)>
		<cfset idAttribute = ' id="' & esc(arguments.id, "attr") & '"'>
	</cfif>

	<cfreturn '<input type="hidden"' & idAttribute & ' name="' & csrf_token() & '" value="' & csrf_hash() & '"' & _solidus() & '>'>
</cffunction>

<!---
 * Generates a meta tag for use within javascript calls.
 *
 * @param id An empty string (null), or a non-empty string
--->
<cffunction name="csrf_meta" returntype="string" output="no" hint="Generates a meta tag for use within javascript calls">
	<cfargument name="id" type="string" required="no" default="">
	<cfset var idAttribute = "">

	<cfif NOT is_null(arguments.id)>
		<cfset idAttribute = ' id="' & esc(arguments.id, "attr") & '"'>
	</cfif>

	<cfreturn '<meta' & idAttribute & ' name="' & csrf_header() & '" content="' & csrf_hash() & '"' & _solidus() & '>'>
</cffunction>

<!---
 * Grabs the current database connection instance, or creates it.
 *
 * Difference: the original calls Config\Database::connect(), a static
 * method. The one object of static_() stands in for that class, and it is
 * ColdIgniter\Database\Config, which Config\Database extends in the
 * original.
 *
 * Difference: an empty string (null) is the default group, and a map of
 * settings is made with array_().
 *
 * @param db       A group name, a map of settings, a connection, or an empty string
 * @param getShared Whether to return a shared instance of the connection
 *
 * @return BaseConnection
--->
<cffunction name="db_connect" returntype="any" output="no" hint="Grabs the current database connection instance, or creates it">
	<cfargument name="db" type="any" required="no" default="">
	<cfargument name="getShared" type="boolean" required="no" default="true">

	<cfreturn static_("ColdIgniter\Database\Config").connect(arguments.db, arguments.getShared)>
</cffunction>

<!---
 * Allows user to retrieve values from the environment
 * variables that have been set. Especially useful for
 * retrieving values set from the .env file for
 * use in config files.
 *
 * Difference: the values are in request.ColdIgniter.env (see
 * Config/DotEnv.cfc), then the CGI variables of the server stand in for
 * $_SERVER. The name is not case-sensitive in the first place. There is no
 * null, so "null" gives an empty string, and so does a variable that is
 * not found and has no default. Not ported yet: getenv().
 *
 * Difference: only the server variables of server_value() and the names
 * that start with "HTTP_" are read from the CGI scope, and a server
 * variable that a request header has supplied is not used (see
 * server_value()). So any other name, such as "CI_ENVIRONMENT" or
 * "app.baseURL", cannot be supplied by a client with a header. The
 * original has the same split: $_SERVER holds the headers only as
 * "HTTP_*".
 *
 * @param key     The name
 * @param default The value when it is not found
 *
 * @return The value: true, false or an empty string for the words "true",
 *         "false", "empty" and "null" in any case, else the string
--->
<cffunction name="env" returntype="any" output="no" hint="Allows user to retrieve values from the environment variables that have been set">
	<cfargument name="key" type="string" required="yes">
	<cfargument name="default" type="any" required="no" default="">
	<cfset var value = "">
	<cfset var found = false>

	<cfif StructKeyExists(request.ColdIgniter.env, arguments.key)>
		<cfset value = request.ColdIgniter.env[arguments.key]>
		<cfset found = true>
	<cfelse>
		<cfset value = server_value(arguments.key)>
		<cfset found = value NEQ "">
	</cfif>

	<!--- Not found? Return the default value --->
	<cfif NOT found>
		<cfreturn arguments.default>
	</cfif>

	<!--- Handle any boolean values --->
	<!--- Difference: Compare() is used, since CFML equality treats "yes" as true and "no" as false --->
	<cfif Compare(LCase(value), "true") EQ 0>
		<cfreturn true>
	<cfelseif Compare(LCase(value), "false") EQ 0>
		<cfreturn false>
	<cfelseif Compare(LCase(value), "empty") EQ 0>
		<cfreturn "">
	<cfelseif Compare(LCase(value), "null") EQ 0>
		<cfreturn "">
	</cfif>

	<cfreturn value>
</cffunction>

<!---
 * Performs simple auto-escaping of data for security reasons.
 * Might consider making this more complex at a later date.
 *
 * If data is a string, then it simply escapes and returns it.
 *
 * Not ported yet: the "css" context and the encoding (the Escaper
 * library is not ported). The "js" context is a small stand-in for
 * Escaper::escapeJs().
 *
 * Differs from the original: a list or a map is escaped into a copy,
 * value by value, and the copy is returned (arrays are not copied on
 * the way in here).
 *
 * @param data     The string
 * @param context  'attr', 'css', 'html', 'js', 'raw' or 'url'
--->
<cffunction name="esc" returntype="any" output="no" hint="Performs simple auto-escaping of data for security reasons">
	<cfargument name="data" type="any" required="yes">
	<cfargument name="context" type="string" required="no" default="html">
	<cfargument name="encoding" type="string" required="no" default="">
	<cfset var escaped = "">
	<cfset var char = "">
	<cfset var code = 0>
	<cfset var i = 0>
	<cfset var result = "">
	<cfset var key = "">

	<cfset arguments.context = LCase(arguments.context)>

	<!---
	 Provide a way to NOT escape data since
	 this could be called automatically by
	 the View library.
	--->
	<cfif arguments.context EQ "raw">
		<cfreturn arguments.data>
	</cfif>

	<cfif IsArray(arguments.data)>
		<cfset result = ArrayNew(1)>
		<cfloop from="1" to="#ArrayLen(arguments.data)#" index="i">
			<cfset ArrayAppend(result, esc(arguments.data[i], arguments.context, arguments.encoding))>
		</cfloop>

		<cfreturn result>
	</cfif>

	<cfif IsStruct(arguments.data) AND NOT IsObject(arguments.data)>
		<cfset result = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfloop collection="#arguments.data#" item="key">
			<cfset result[key] = esc(arguments.data[key], arguments.context, arguments.encoding)>
		</cfloop>

		<cfreturn result>
	</cfif>

	<cfif IsSimpleValue(arguments.data)>
		<cfif NOT ListFind("html,js,attr,url", arguments.context)>
			<cfthrow type="ColdIgniter.InvalidArgumentException" message="Invalid escape context provided.">
		</cfif>

		<!--- Everything but letters, digits and ",._" becomes \xHH or \uHHHH. --->
		<cfif arguments.context EQ "js">
			<cfloop from="1" to="#Len(arguments.data)#" index="i">
				<cfset char = Mid(arguments.data, i, 1)>
				<cfif REFind("[A-Za-z0-9,._]", char) GT 0>
					<cfset escaped = escaped & char>
				<cfelse>
					<cfset code = Asc(char)>
					<cfif code LT 256>
						<cfset escaped = escaped & "\x" & UCase(Right("0" & FormatBaseN(code, 16), 2))>
					<cfelse>
						<cfset escaped = escaped & "\u" & UCase(Right("000" & FormatBaseN(code, 16), 4))>
					</cfif>
				</cfif>
			</cfloop>

			<cfreturn escaped>
		</cfif>

		<cfif arguments.context EQ "url">
			<cfreturn URLEncodedFormat(arguments.data)>
		</cfif>

		<cfset arguments.data = HTMLEditFormat(arguments.data)>
		<cfif arguments.context EQ "attr">
			<cfset arguments.data = Replace(arguments.data, "'", "&##39;", "all")>
		<cfelseif arguments.context EQ "html">
			<!--- The original escapes the single quote too (ENT_QUOTES) --->
			<cfset arguments.data = Replace(arguments.data, "'", "&##039;", "all")>
		</cfif>
	</cfif>

	<cfreturn arguments.data>
</cffunction>

<!---
 * Used to force a page to be accessed in via HTTPS.
 * Uses a standard redirect, plus will set the HSTS header
 * for modern browsers that support, which gives best
 * protection against man-in-the-middle attacks.
 *
 * @see https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security
 *
 * @param duration How long should the SSL header be set for? (in seconds)
 *                 Defaults to 1 year.
 * @param request_ An empty string for the shared request
 * @param response An empty string for the shared response
 *
 * The response is changed to the redirect, and then
 * ColdIgniter.HTTP.Exceptions.RedirectException is thrown (see
 * RedirectException): the caller takes the redirect from the response it
 * passed in.
 *
 * Not ported yet: is_cli(), the session ID regeneration, the testing
 * environment, withScheme() (the scheme is replaced in the string of the
 * URI) and clearing the cookies of the response (there is no cookie store).
--->
<cffunction name="force_https" returntype="void" output="no" hint="Used to force a page to be accessed in via HTTPS">
	<cfargument name="duration" type="numeric" required="no" default="31536000">
	<cfargument name="request_" type="any" required="no" default="">
	<cfargument name="response" type="any" required="no" default="">
	<cfset var uri = "">
	<cfset var scheme = "">

	<cfif is_null(arguments.request_)>
		<cfset arguments.request_ = service("request")>
	</cfif>

	<cfif NOT instanceof_(arguments.request_, "ColdIgniter\HTTP\IncomingRequest")>
		<cfreturn>
	</cfif>

	<cfif is_null(arguments.response)>
		<cfset arguments.response = service("response")>
	</cfif>

	<cfif arguments.request_.isSecure() OR Compare(arguments.request_.getServer("HTTPS"), "test") EQ 0>
		<cfreturn>
	</cfif>

	<cfset scheme = arguments.request_.getUri().getScheme()>
	<cfset uri = "https" & Mid(arguments.request_.getUri().__toString(), Len(scheme) + 1, Len(arguments.request_.getUri().__toString()))>

	<!--- Set an HSTS header --->
	<cfset arguments.response.setHeader("Strict-Transport-Security", "max-age=" & arguments.duration)>
	<cfset arguments.response.redirect(uri)>
	<cfset arguments.response.setStatusCode(307)>
	<cfset arguments.response.setBody("")>

	<cfset static_("ColdIgniter\HTTP\Exceptions\RedirectException").forResponse()>
</cffunction>

<!---
 * Loads a helper file into memory. Supports namespaced helpers,
 * both in and out of the 'Helpers' directory of a namespaced directory.
 *
 * Will load ALL helpers of the matching name, in the following order:
 *   1. app/Helpers
 *   2. {namespace}/Helpers
 *   3. system/Helpers
 *
 * Not ported yet: the file locator, so only app/Helpers and
 * system/Helpers are searched and a namespaced name is never found.
 *
 * The functions of a helper file become global (see require_once) and
 * the first definition of a name wins, which is how an app helper
 * overrides a system one. The caller gets the functions at once, also
 * when another object loaded the file earlier.
 *
 * @param filenames Array of names, or one name
 *
 * @throws FileNotFoundException
--->
<cffunction name="helper" returntype="void" output="no" hint="Loads a helper file into memory">
	<cfargument name="filenames" type="any" required="yes">
	<cfset var loaded = request.ColdIgniter.helpers>

	<!--- Store a list of all files to include... --->
	<cfset var includes = ArrayNew(1)>
	<cfset var filename = "">
	<cfset var systemHelper = "">
	<cfset var appHelper = "">
	<cfset var i = 0>

	<!--- Not ported yet: loader = service("locator") --->

	<cfif NOT IsArray(arguments.filenames)>
		<cfset filename = arguments.filenames>
		<cfset arguments.filenames = ArrayNew(1)>
		<cfset ArrayAppend(arguments.filenames, filename)>
	</cfif>

	<cfloop from="1" to="#ArrayLen(arguments.filenames)#" index="i">
		<cfset filename = arguments.filenames[i]>

		<!---
		 Store our system and application helper
		 versions so that we can control the load ordering.
		--->
		<cfset systemHelper = "">
		<cfset appHelper = "">

		<cfif Find("_helper", filename) EQ 0>
			<cfset filename = filename & "_helper">
		</cfif>

		<!--- Check if this helper has already been loaded --->
		<cfif NOT StructKeyExists(loaded, filename)>
			<!---
			 If the file is namespaced, we'll just grab that
			 file and not search for any others
			--->
			<cfif Find("\", filename) GT 0>
				<!--- Not ported yet: loader.locateFile(filename, "Helpers"), so the file is never found --->
				<cfthrow type="ColdIgniter.Files.Exceptions.FileNotFoundException" message="File not found: ""#filename#""">
			<cfelse>
				<!--- No namespaces, so search in all available locations --->
				<!--- Not ported yet: loader.search("Helpers/" & filename), and the namespace locations --->
				<cfif is_file(request.APPPATH & "Helpers" & request.DIRECTORY_SEPARATOR & filename & ".cfm")>
					<cfset appHelper = request.APPPATH & "Helpers" & request.DIRECTORY_SEPARATOR & filename & ".cfm">
				</cfif>
				<cfif is_file(request.SYSTEMPATH & "Helpers" & request.DIRECTORY_SEPARATOR & filename & ".cfm")>
					<cfset systemHelper = request.SYSTEMPATH & "Helpers" & request.DIRECTORY_SEPARATOR & filename & ".cfm">
				</cfif>

				<!--- App-level helpers should override all others --->
				<cfif appHelper NEQ "">
					<cfset ArrayAppend(includes, appHelper)>
					<cfset loaded[filename] = true>
				</cfif>

				<!--- And the system default one should be added in last. --->
				<cfif systemHelper NEQ "">
					<cfset ArrayAppend(includes, systemHelper)>
					<cfset loaded[filename] = true>
				</cfif>
			</cfif>
		</cfif>
	</cfloop>

	<!--- Now actually include all of the files --->
	<cfloop from="1" to="#ArrayLen(includes)#" index="i">
		<cfset require_once(includes[i])>
	</cfloop>

	<!--- The functions are global: this object gets them too --->
	<cfset StructAppend(variables, request.ColdIgniter.functions.__functions(), false)>
</cffunction>

<!---
 * A convenience method to translate a string or array of them and format
 * the result.
 *
 * Not ported yet: the intl extension's MessageFormatter, see Language.
 *
 * lang(line, args, locale)
 *
 * @param line
 * @param args   A map (see array_()) of named values, a list of values, or an empty string for none
 * @param locale An empty string (null) for the active locale
 *
 * @return A list of strings, or a string
--->
<cffunction name="lang" returntype="any" output="no" hint="A convenience method to translate a string or array of them and format the result">
	<cfargument name="line" type="string" required="yes">
	<cfargument name="args" type="any" required="no" default="">
	<cfargument name="locale" type="string" required="no" default="">
	<cfset var language = service("language")>
	<cfset var activeLocale = "">
	<cfset var lines = "">

	<!--- Get active locale --->
	<cfset activeLocale = language.getLocale_()>

	<cfif arguments.locale NEQ "" AND Compare(arguments.locale, activeLocale) NEQ 0>
		<cfset language.setLocale_(arguments.locale)>
	</cfif>

	<cfset lines = language.getLine(arguments.line, arguments.args)>

	<cfif arguments.locale NEQ "" AND Compare(arguments.locale, activeLocale) NEQ 0>
		<!--- Reset to active locale --->
		<cfset language.setLocale_(activeLocale)>
	</cfif>

	<cfreturn lines>
</cffunction>

<!---
 * A convenience/compatibility method for logging events through
 * the Log system.
 *
 * Allowed log levels are:
 *  - emergency
 *  - alert
 *  - critical
 *  - error
 *  - warning
 *  - notice
 *  - info
 *  - debug
 *
 * Not ported yet: the TestLogger of the "testing" environment.
 *
 * @param level   The level
 * @param message The message
 * @param context A map (see array_())
--->
<cffunction name="log_message" returntype="void" output="no" hint="A convenience/compatibility method for logging events through the Log system">
	<cfargument name="level" type="string" required="yes">
	<cfargument name="message" type="string" required="yes">
	<cfargument name="context" type="any" required="no" default="">

	<!--- Not ported yet: when running tests, the TestLogger is used --->

	<cfset service("logger").log_(arguments.level, arguments.message, arguments.context)>
</cffunction>

<!---
 * Provides access to "old input" that was set in the session
 * during a redirect().withInput().
 *
 * Differs from the original: an escape of false is a real boolean or the
 * text "false".
 *
 * @param key     The key of the input
 * @param default A string
 * @param escape  attr, html, js, raw, url or false (css is not ported yet, see esc())
 *
 * @return A string, a list or a map
--->
<cffunction name="old" returntype="any" output="no" hint="Provides access to old input that was set in the session during a redirect().withInput()">
	<cfargument name="key" type="string" required="yes">
	<cfargument name="default" type="any" required="no" default="">
	<cfargument name="escape" type="any" required="no" default="html">
	<cfset var request_obj = "">
	<cfset var value = "">

	<!--- Ensure the session is loaded --->
	<cfif Compare(session_status(), "none") EQ 0 AND Compare(request.ENVIRONMENT, "testing") NEQ 0>
		<cfset session_()>
	</cfif>

	<cfset request_obj = service("request")>

	<cfset value = request_obj.getOldInput(arguments.key)>

	<!--- Return the default value if nothing found in the old input. --->
	<cfif is_null(value)>
		<cfreturn arguments.default>
	</cfif>

	<cfif (is_bool(arguments.escape) AND NOT arguments.escape) OR Compare(arguments.escape, "false") EQ 0>
		<cfreturn value>
	</cfif>

	<cfreturn esc(value, arguments.escape)>
</cffunction>

<!---
 * Convenience method that works with the current global request and
 * router instances to redirect using named/reverse-routed routes
 * to determine the URL to go to.
 *
 * If more control is needed, you must use response.redirect explicitly.
 *
 * @param route Route name or Controller::method
--->
<cffunction name="redirect" returntype="any" output="no" hint="Convenience method that works with the current global request and router instances to redirect">
	<cfargument name="route" type="string" required="no" default="">
	<cfset var response = service("redirectresponse")>

	<cfif arguments.route NEQ "">
		<cfreturn response.route(arguments.route)>
	</cfif>

	<cfreturn response>
</cffunction>

<!---
 * Generates the solidus character (`/`) depending on the HTML5 compatibility flag in `Config\DocTypes`
 *
 * Not ported yet: Config\DocTypes. Its html5 flag is true in the original
 * by default, which is the answer here (an empty string).
 *
 * @internal
--->
<cffunction name="_solidus" returntype="string" output="no" hint="Generates the solidus character depending on the HTML5 compatibility flag">

	<cfreturn "">
</cffunction>

<!---
 * Remove Invisible Characters
 *
 * This prevents sandwiching null characters
 * between ascii characters, like Java\0script.
--->
<cffunction name="remove_invisible_characters" returntype="string" output="no" hint="Remove Invisible Characters">
	<cfargument name="str" type="string" required="yes">
	<cfargument name="urlEncoded" type="boolean" required="no" default="true">
	<cfset var nonDisplayables = ArrayNew(1)>
	<cfset var previous = "">
	<cfset var passes = 0>
	<cfset var buffer = "">
	<cfset var character = "">
	<cfset var i = 0>

	<!--- every control character except newline (dec 10), carriage return (dec 13) and horizontal tab (dec 09) --->
	<cfif arguments.urlEncoded>
		<cfset ArrayAppend(nonDisplayables, "/%0[0-8bcef]/")> <!--- url encoded 00-08, 11, 12, 14, 15 --->
		<cfset ArrayAppend(nonDisplayables, "/%1[0-9a-f]/")> <!--- url encoded 16-31 --->
	</cfif>

	<cfset ArrayAppend(nonDisplayables, "/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]+/S")> <!--- 00-08, 11, 12, 14-31, 127 --->

	<!--- Difference: the loop ends when a pass changes nothing, where the original counts the replacements. --->
	<cfloop condition="true">
		<cfset previous = arguments.str>
		<cfset arguments.str = preg_replace(nonDisplayables, "", arguments.str, true)>

		<cfif Compare(previous, arguments.str) EQ 0>
			<cfbreak>
		</cfif>

		<!---
		 Difference: nested codes ("%0%000") peel one level per pass, so a long
		 nest is quadratic. After a few passes the rest is done in one walk:
		 the control characters go first (removing a code never makes one),
		 then each code is dropped as soon as its last character is read.
		 The result is the same.
		--->
		<cfset passes = passes + 1>
		<cfif passes GTE 4 AND arguments.urlEncoded>
			<cfset arguments.str = preg_replace(nonDisplayables[ArrayLen(nonDisplayables)], "", arguments.str, true)>
			<cfset buffer = CreateObject("java", "java.lang.StringBuffer").init()>

			<cfloop from="1" to="#Len(arguments.str)#" index="i">
				<cfset character = Mid(arguments.str, i, 1)>
				<cfset buffer.append(JavaCast("string", character))>

				<cfif Compare(character, "%") NEQ 0 AND buffer.length() GTE 3>
					<cfif buffer.substring(JavaCast("int", buffer.length() - 3)).matches("%(?:0[0-8bcef]|1[0-9a-f])")>
						<cfset buffer.setLength(JavaCast("int", buffer.length() - 3))>
					</cfif>
				</cfif>
			</cfloop>

			<cfset arguments.str = buffer.toString()>
			<cfbreak>
		</cfif>
	</cfloop>

	<cfreturn arguments.str>
</cffunction>

<!---
 * Renders a backtrace.
 *
 * Difference: the rows are the ones of the tagContext of a caught error
 * (template, line and id). The id is the name of a function when the engine
 * knows it, else "??". The rows have no class, type or arguments.
 *
 * @param backtrace A list of rows (structs)
--->
<cffunction name="render_backtrace" returntype="string" output="no" hint="Renders a backtrace">
	<cfargument name="backtrace" type="array" required="yes">
	<cfset var backtraces = ArrayNew(1)>
	<cfset var frame = "">
	<cfset var file = "">
	<cfset var idx = "">
	<cfset var functionName = "">
	<cfset var index = 0>

	<cfloop from="1" to="#ArrayLen(arguments.backtrace)#" index="index">
		<cfset frame = arguments.backtrace[index]>

		<cfset file = "[internal function]">
		<cfif StructKeyExists(frame, "template")>
			<cfset file = frame.template & "(" & frame.line & ")">
		</cfif>

		<cfset functionName = "">
		<cfif StructKeyExists(frame, "id")>
			<cfset functionName = frame.id>
		</cfif>

		<cfset idx = RJustify(index, 2)>

		<cfset ArrayAppend(backtraces, idx & " " & clean_path(file) & ": " & functionName & "()")>
	</cfloop>

	<cfreturn implode(Chr(10), backtraces)>
</cffunction>

<!---
 * Returns the shared Request.
 *
 * Named with an underscore, because "request" is a scope.
 *
 * @return CLIRequest|IncomingRequest
--->
<cffunction name="request_" returntype="any" output="no" hint="Returns the shared Request">
	<cfreturn service("request")>
</cffunction>

<!---
 * Given a route name or controller/method string and any params,
 * will attempt to build the relative URL to the
 * matching route.
 *
 * NOTE: This requires the controller/method to
 * have a route defined in the routes Config file.
 *
 * Not ported yet: RouteCollection::reverseRoute, so no route is found.
 *
 * @param method Route name or Controller::method
 * @param params One or more parameters to be passed to the route.
 *               The last parameter allows you to set the locale.
 *
 * @return false|string The route (URI path relative to baseURL) or false if not found.
--->
<cffunction name="route_to" returntype="any" output="no" hint="Builds the relative URL to a route name or controller method">
	<cfargument name="method" type="string" required="yes">

	<!--- Not ported yet: service("routes").reverseRoute(method, params) --->
	<cfreturn false>
</cffunction>

<!---
 * Returns a value of the server (the CGI scope), or an empty string.
 *
 * Difference: this has no counterpart in the original, where $_SERVER holds
 * only what the web server sets. On the server (verified) the engine's
 * connector puts a request header and a server variable in one table, and
 * the header wins: a header "Server-Port-Secure: 1" or "HTTPS: on" changes
 * CGI.SERVER_PORT_SECURE, CGI.HTTPS and the secure flag of the servlet
 * request, "Remote-Addr: 192.0.2.9" changes the client address and
 * "Request-Method: POST" the method, and the servlet request has no value
 * that a header cannot reach. What a client cannot change is the list of
 * the header names it sent (the engine gives every name in upper case, and
 * "Server_Port" and "Server-Port" are one name; dots stay as they are). The
 * names are compared with everything but letters and digits removed, on both
 * sides, so no spelling of a variable's name can get past. So the CGI
 * scope is read for a name only if
 *  - it starts with "HTTP_" (a request header, as in the original), or
 *  - it is in the fixed list below and no request header has that name
 *    (in the stripped form).
 * A server variable that a header has supplied reads as empty (a client
 * that forges one gets no value, for HTTPS that means "not secure"). Any
 * other name is not read: a header can supply any name.
 * CONTENT_TYPE and CONTENT_LENGTH are request headers by nature and are
 * read as they are.
 * This list names the server variables: env() and the server array of
 * Superglobals use it. Cache/FrontPage.cfm has a copy in the stripped
 * form, as it runs before this file is read. Keep the two lists the same.
 *
 * @param key The name of the variable
 *
 * @return The value, or an empty string
--->
<cffunction name="server_value" returntype="string" output="no" hint="Returns a value of the server (the CGI scope) unless a request header supplied it">
	<cfargument name="key" type="string" required="yes">
	<cfset var store = request.ColdIgniter>
	<cfset var headers = "">
	<cfset var name = "">
	<cfset var value = "">

	<!---
	 * Once per request: the names of the server variables and of the
	 * request headers as keys (a key lookup takes the place of a search of
	 * the list for every call), and the values that were read. The CGI
	 * scope does not change within a request, so a value is read once.
	--->
	<cfif NOT StructKeyExists(store, "serverValues")>
		<cfset store.serverNames = StructNew()>

		<cfloop list="#server_names()#" index="name">
			<cfset store.serverNames[name] = true>
		</cfloop>

		<cfset headers = http_request_data().headers>
		<cfset store.headerNames = StructNew()>

		<cfloop collection="#headers#" item="name">
			<cfset store.headerNames[REReplace(UCase(name), "[^A-Z0-9]", "", "all")] = true>
		</cfloop>

		<cfset store.serverValues = StructNew()>
	</cfif>

	<cfif StructKeyExists(store.serverValues, arguments.key)>
		<cfreturn store.serverValues[arguments.key]>
	</cfif>

	<cfif Left(arguments.key, 5) EQ "HTTP_" AND REFindNoCase("^HTTP_[A-Z0-9_]+$", arguments.key) GT 0>
		<cfset value = CGI[arguments.key]>
	<cfelseif NOT StructKeyExists(store.serverNames, arguments.key)>
		<cfreturn "">
	<cfelseif arguments.key EQ "CONTENT_TYPE" OR arguments.key EQ "CONTENT_LENGTH">
		<cfset value = CGI[arguments.key]>
	<!--- Difference: names are compared with everything but letters and digits removed, so a header spelled with dashes, dots or doubled separators still counts as the variable (a name of the list has only letters and "_") --->
	<cfelseif NOT StructKeyExists(store.headerNames, Replace(arguments.key, "_", "", "all"))>
		<cfset value = CGI[arguments.key]>
	</cfif>

	<cfset store.serverValues[arguments.key] = value>

	<cfreturn value>
</cffunction>

<!---
 * The headers and the body of the request, as GetHttpRequestData() gives
 * them.
 *
 * Difference: this has no counterpart in the original. The engine builds
 * the structure anew for every call (about half a millisecond on the
 * server), and a request reads it several times, so it is read once and
 * kept for the request. Cache/FrontPage.cfm reads it first for a GET
 * request.
 *
 * @return A structure with the keys headers, content, method and protocol
--->
<cffunction name="http_request_data" returntype="struct" output="no" hint="The headers and the body of the request, read once per request">
	<cfif NOT StructKeyExists(request, "ColdIgniterRequestData")>
		<cfset request.ColdIgniterRequestData = GetHttpRequestData()>
	</cfif>

	<cfreturn request.ColdIgniterRequestData>
</cffunction>

<!---
 * The names of the server variables that server_value() reads (see there).
 * The real variables of the server and of the engine, as found on the
 * server; the list is the one place that has them.
 *
 * @return A comma separated list
--->
<cffunction name="server_names" returntype="string" output="no" hint="The names of the server variables that server_value() reads">
	<cfreturn "APPL_MD_PATH,APPL_PHYSICAL_PATH,AUTH_TYPE,AUTH_USER,CERT_COOKIE,CERT_FLAGS,CERT_ISSUER,CERT_KEYSIZE,CERT_SECRETKEYSIZE,CERT_SERIALNUMBER,CERT_SERVER_ISSUER,CERT_SERVER_SUBJECT,CERT_SUBJECT,CF_TEMPLATE_PATH,CONTENT_LENGTH,CONTENT_TYPE,CONTEXT_PATH,GATEWAY_INTERFACE,HTTPS,HTTPS_KEYSIZE,HTTPS_SECRETKEYSIZE,HTTPS_SERVER_ISSUER,HTTPS_SERVER_SUBJECT,INSTANCE_ID,LOCAL_ADDR,PATH_INFO,PATH_TRANSLATED,QUERY_STRING,REMOTE_ADDR,REMOTE_HOST,REMOTE_PORT,REMOTE_USER,REQUEST_METHOD,REQUEST_URI,SCRIPT_NAME,SERVER_NAME,SERVER_PORT,SERVER_PORT_SECURE,SERVER_PROTOCOL,SERVER_SOFTWARE">
</cffunction>

<!---
 * Allows cleaner access to the Services Config file.
 * Always returns a SHARED instance of the class, so
 * calling the function multiple times should always
 * return the same instance.
 *
 * These are equal:
 *  - timer = service("timer")
 *  - timer = static_("ColdIgniter\Config\Services").timer()
 *
 * service(name, param, param, ...)
--->
<cffunction name="service" returntype="any" output="no" hint="Allows cleaner access to the Services Config file">
	<cfargument name="name" type="string" required="yes">
	<cfset var params = ArrayNew(1)>
	<cfset var i = 0>

	<cfloop from="2" to="#ArrayLen(arguments)#" index="i">
		<cfset ArrayAppend(params, arguments[i])>
	</cfloop>

	<cfif ArrayLen(params) EQ 0>
		<cfreturn static_("Config\Services").get(arguments.name)>
	</cfif>

	<cfreturn static_("Config\Services").__callStatic(arguments.name, params)>
</cffunction>

<!---
 * A convenience method for accessing the session instance,
 * or an item that has been set in the session.
 *
 * Examples:
 *    session_().set("foo", "bar");
 *    foo = session_("bar");
 *
 * Difference: the name has a trailing underscore, because the name of a
 * scope (session) is not known to be safe for a global function.
 *
 * @param val An empty string for the session, or the key of an item
 *
 * @return The Session when val is empty, else the item
--->
<cffunction name="session_" returntype="any" output="no" hint="A convenience method for accessing the session instance, or an item that has been set in the session">
	<cfargument name="val" type="any" required="no" default="">
	<cfset var sessionObj = service("session")>

	<!--- Returning a single item? --->
	<cfif NOT is_null(arguments.val)>
		<cfreturn sessionObj.get(arguments.val)>
	</cfif>

	<cfreturn sessionObj>
</cffunction>

<!---
 * Stringify attributes for use in HTML tags.
 *
 * Helper function used to convert a string, array, or object
 * of attributes to a string.
 *
 * An array with string keys is made with array_() (or a struct, which
 * has no order).
 *
 * @param attributes Struct, array (map) or string
--->
<cffunction name="stringify_attributes" returntype="string" output="no" hint="Stringify attributes for use in HTML tags">
	<cfargument name="attributes" type="any" required="yes">
	<cfargument name="js" type="boolean" required="no" default="false">
	<cfset var atts = "">
	<cfset var key = "">

	<cfif IsSimpleValue(arguments.attributes) AND arguments.attributes EQ "">
		<cfreturn atts>
	</cfif>

	<cfif IsSimpleValue(arguments.attributes)>
		<cfreturn " " & arguments.attributes>
	</cfif>

	<cfif IsStruct(arguments.attributes)>
		<cfloop collection="#arguments.attributes#" item="key">
			<cfif arguments.js>
				<cfset atts = atts & key & "=" & esc(arguments.attributes[key], "js") & ",">
			<cfelse>
				<cfset atts = atts & " " & key & "=""" & esc(arguments.attributes[key]) & """">
			</cfif>
		</cfloop>
	<cfelse>
		<cfloop from="1" to="#ArrayLen(arguments.attributes)#" index="key">
			<cfif arguments.js>
				<cfset atts = atts & (key - 1) & "=" & esc(arguments.attributes[key], "js") & ",">
			<cfelse>
				<cfset atts = atts & " " & (key - 1) & "=""" & esc(arguments.attributes[key]) & """">
			</cfif>
		</cfloop>
	</cfif>

	<cfreturn rtrim_(atts, ",")>
</cffunction>

<!---
 * Grabs the current RendererInterface-compatible class
 * and tells it to render the specified view. Simply provides
 * a convenience method that can be used in Controllers,
 * libraries, and routed closures.
 *
 * NOTE: Does not provide any escaping of the data, so that must
 * all be handled manually by the developer.
 *
 * @param options Options for saveData or third-party extensions.
--->
<cffunction name="view" returntype="string" output="no" hint="Renders the specified view">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="data" type="any" required="no" default="#StructNew()#">
	<cfargument name="options" type="any" required="no" default="#StructNew()#">
	<cfset var renderer = service("renderer")>

	<cfset var config = variables.config("Config\View")>
	<cfset var saveData = config.saveData>

	<cfif StructKeyExists(arguments.options, "saveData")>
		<cfset saveData = arguments.options["saveData"] IS true>
		<cfset StructDelete(arguments.options, "saveData")>
	</cfif>

	<cfreturn renderer.setData(arguments.data, "raw").render(arguments.name, arguments.options, saveData)>
</cffunction>
