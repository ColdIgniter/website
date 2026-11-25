<!---
 * Class Security
 *
 * Provides methods that help protect your site against
 * Cross-Site Request Forgery attacks.
 *
 * Difference: the properties hash, cookie, request and session have a
 * trailing underscore (hash_, cookie_, request_, session_), as their
 * names are built-in functions or scopes. The method randomize() is
 * randomize_(), as Randomize() is a built-in function.
 *
 * Difference: a binary string is a Java byte array here (the engine drops
 * the NUL character from a string): see random_bytes(), hex2bin() and
 * bin2hex(). The token is built from hexadecimal text instead of by
 * joining two binary strings, with the same result.
 *
 * Difference: the token is compared by hash_equals(), which is a loop in
 * CFML (see the polyfill), as the Java of 6.1 has no constant-time compare.
 *
 * Difference: JSON has no types in json_decode() here (see the polyfill),
 * so a number or a true in the token member counts as the text it is
 * written with. As such a text is not a token it is refused all the same.
 *
 * Difference: the JSON body is not decoded and encoded again to remove
 * the token. The member is cut out of the text, with the comma next to it,
 * and the rest of the body is kept as it was written.
--->
<cfcomponent output="no" extends="SecurityInterface" hint="Provides methods that help protect your site against Cross-Site Request Forgery attacks">

	<cfset this.CSRF_PROTECTION_COOKIE = "cookie">
	<cfset this.CSRF_PROTECTION_SESSION = "session">
	<cfset this.CSRF_HASH_BYTES = 16>

	<!---
	 * CSRF Protection Method
	 *
	 * Protection Method for Cross Site Request Forgery protection.
	 *
	 * @var string 'cookie' or 'session'
	 *
	 * @deprecated 4.4.0 Use this.config.csrfProtection.
	--->
	<cfset this.csrfProtection = this.CSRF_PROTECTION_COOKIE>

	<!---
	 * CSRF Token Randomization
	 *
	 * @deprecated 4.4.0 Use this.config.tokenRandomize.
	--->
	<cfset this.tokenRandomize = "false">

	<!---
	 * CSRF Hash (without randomization)
	 *
	 * Random hash for Cross Site Request Forgery protection.
	 *
	 * An empty string stands for null.
	--->
	<cfset this.hash_ = "">

	<!---
	 * CSRF Token Name
	 *
	 * Token name for Cross Site Request Forgery protection.
	 *
	 * @deprecated 4.4.0 Use this.config.tokenName.
	--->
	<cfset this.tokenName = "csrf_token_name">

	<!---
	 * CSRF Header Name
	 *
	 * Header name for Cross Site Request Forgery protection.
	 *
	 * @deprecated 4.4.0 Use this.config.headerName.
	--->
	<cfset this.headerName = "X-CSRF-TOKEN">

	<!---
	 * The CSRF Cookie instance.
	--->
	<cfset this.cookie_ = "">

	<!---
	 * CSRF Cookie Name (with Prefix)
	 *
	 * Cookie name for Cross Site Request Forgery protection.
	--->
	<cfset this.cookieName = "csrf_cookie_name">

	<!---
	 * CSRF Expires
	 *
	 * Expiration time for Cross Site Request Forgery protection cookie.
	 *
	 * Defaults to two hours (in seconds).
	 *
	 * @deprecated 4.4.0 Use this.config.expires.
	--->
	<cfset this.expires = 7200>

	<!---
	 * CSRF Regenerate
	 *
	 * Regenerate CSRF Token on every request.
	 *
	 * @deprecated 4.4.0 Use this.config.regenerate.
	--->
	<cfset this.regenerate = "true">

	<!---
	 * CSRF Redirect
	 *
	 * Redirect to previous page with error on failure.
	 *
	 * @deprecated 4.4.0 Use this.config.redirect.
	--->
	<cfset this.redirect = "false">

	<!---
	 * CSRF SameSite
	 *
	 * Setting for CSRF SameSite cookie token.
	 *
	 * Allowed values are: None - Lax - Strict - ''.
	 *
	 * Defaults to `Lax` as recommended in this link:
	 *
	 * @see https://portswigger.net/web-security/csrf/samesite-cookies
	 *
	 * @deprecated `Config\Cookie` samesite property is used.
	--->
	<cfset this.samesite = "Lax">

	<!---
	 * The request (private readonly in the original)
	--->
	<cfset this.request_ = "">

	<!---
	 * CSRF Cookie Name without Prefix
	--->
	<cfset this.rawCookieName = "">

	<!---
	 * Session instance.
	--->
	<cfset this.session_ = "">

	<!---
	 * CSRF Hash in Request Cookie
	 *
	 * The cookie value is always CSRF hash (without randomization) even if
	 * tokenRandomize is true.
	--->
	<cfset this.hashInCookie = "">

	<!---
	 * Security Config
	--->
	<cfset this.config = "">

	<!---
	 * Constructor.
	 *
	 * Stores our configuration and fires off the init() method to setup
	 * initial state.
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfset var cookie = "">

		<cfset this.config = arguments.config>

		<cfset this.rawCookieName = arguments.config.cookieName>

		<cfif isCSRFCookie()>
			<cfset cookie = variables.config("Config\Cookie")>

			<cfset configureCookie(cookie)>
		<cfelse>
			<!--- Session based CSRF protection --->
			<cfset configureSession()>
		</cfif>

		<cfset this.request_ = service("request")>
		<cfset this.hashInCookie = this.request_.getCookie(this.cookieName)>

		<cfset restoreHash()>
		<cfif is_null(this.hash_)>
			<cfset generateHash()>
		</cfif>

		<cfreturn this>
	</cffunction>

	<cffunction name="isCSRFCookie" access="private" returntype="boolean" output="no">

		<cfreturn Compare(this.config.csrfProtection, this.CSRF_PROTECTION_COOKIE) EQ 0>
	</cffunction>

	<cffunction name="configureSession" access="private" returntype="void" output="no">

		<cfset this.session_ = service("session")>
	</cffunction>

	<cffunction name="configureCookie" access="private" returntype="void" output="no">
		<cfargument name="cookie" type="any" required="yes">
		<cfset var cookiePrefix = arguments.cookie.prefix>

		<cfset this.cookieName = cookiePrefix & this.rawCookieName>
		<cfset static_("ColdIgniter\Cookie\Cookie").setDefaults(arguments.cookie)>
	</cffunction>

	<!---
	 * CSRF Verify
	 *
	 * @param request_ The request
	 *
	 * @return $this
	 *
	 * @throws SecurityException when the token is missing or wrong
	--->
	<cffunction name="verify" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfset var method = arguments.request_.getMethod()>
		<cfset var postedToken = "">
		<cfset var token = "">

		<!--- Protect POST, PUT, DELETE, PATCH requests only --->
		<cfif ListFind("POST,PUT,DELETE,PATCH", method) EQ 0>
			<cfreturn this>
		</cfif>

		<cfset postedToken = getPostedToken(arguments.request_)>

		<cftry>
			<cfif NOT is_null(postedToken) AND this.config.tokenRandomize>
				<cfset token = derandomize(postedToken)>
			<cfelse>
				<cfset token = postedToken>
			</cfif>

			<!--- the original catches InvalidArgumentException --->
			<cfcatch type="ColdIgniter.InvalidArgumentException">
				<cfset token = "">
			</cfcatch>
		</cftry>

		<cfif is_null(token) OR is_null(this.hash_) OR NOT hash_equals(this.hash_, token)>
			<cfset static_("ColdIgniter\Security\Exceptions\SecurityException").forDisallowedAction()>
		</cfif>

		<cfset removeTokenInRequest(arguments.request_)>

		<cfif this.config.regenerate>
			<cfset generateHash()>
		</cfif>

		<cfset log_message("info", "CSRF token verified.")>

		<cfreturn this>
	</cffunction>

	<!---
	 * Remove token in POST or JSON request data
	--->
	<cffunction name="removeTokenInRequest" access="private" returntype="void" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfset var superglobals = service("superglobals")>
		<cfset var tokenName = this.config.tokenName>
		<cfset var body = arguments.request_.getBody()>
		<cfset var json = "">
		<cfset var spans = ArrayNew(1)>
		<cfset var result = "">
		<cfset var parsed = false>
		<cfset var found = true>
		<cfset var i = 0>

		<!--- If the token is found in POST data, we can safely remove it. --->
		<!--- is_string() of the original: the key exists and holds a simple value, an empty string too --->
		<cfif array_key_exists(tokenName, superglobals.getPostArray()) AND IsSimpleValue(superglobals.post(tokenName))>
			<cfset superglobals.unsetPost(tokenName)>
			<cfset arguments.request_.setGlobal("post", superglobals.getPostArray())>

			<cfreturn>
		</cfif>

		<cfif is_null(body)>
			<cfreturn>
		</cfif>

		<!--- If the token is found in JSON data, we can safely remove it. --->
		<cftry>
			<cfset json = json_decode(body, spans)>
			<cfset parsed = true>

			<cfcatch type="ColdIgniter.JsonException">
				<cfset parsed = false>
			</cfcatch>
		</cftry>

		<cfif NOT parsed>
			<!--- The body is not valid JSON - check for form-encoded data. --->
			<cfset result = parse_str(body)>

			<cfif NOT array_key_exists(tokenName, result)>
				<cfreturn>
			</cfif>

			<cfset StructDelete(result, tokenName)>
			<cfset arguments.request_.setBody(http_build_query(result))>

			<cfreturn>
		</cfif>

		<!--- Valid JSON never falls through to form-encoded processing. --->
		<cfif IsStruct(json) AND array_key_exists(tokenName, json)>
			<!--- cut the members out of the text; a name that repeats is cut once for each time, the last first --->
			<cfloop condition="found">
				<cfset found = false>

				<cfloop from="#ArrayLen(spans)#" to="1" index="i" step="-1">
					<cfif Compare(spans[i].key, tokenName) EQ 0>
						<cfset body = removeJsonMember(body, spans, i)>
						<cfset found = true>
						<cfbreak>
					</cfif>
				</cfloop>

				<cfif found>
					<cfset spans = ArrayNew(1)>
					<cfset json_decode(body, spans)>
				</cfif>
			</cfloop>

			<cfset arguments.request_.setBody(body)>
		</cfif>
	</cffunction>

	<!---
	 * Cuts one member out of the top-level object of a JSON text, with the
	 * comma that joins it to the one next to it.
	 *
	 * Difference: this stands in for json_encode() of the original (see the
	 * header). It is part of the port of removeTokenInRequest().
	 *
	 * @param body  The JSON text
	 * @param spans The members, as json_decode() lists them
	 * @param index The number of the member to cut out
	--->
	<cffunction name="removeJsonMember" access="private" returntype="string" output="no">
		<cfargument name="body" type="string" required="yes">
		<cfargument name="spans" type="any" required="yes">
		<cfargument name="index" type="numeric" required="yes">
		<cfset var start = arguments.spans[arguments.index].start>
		<cfset var end = arguments.spans[arguments.index].end>
		<cfset var count = ArrayLen(arguments.spans)>
		<cfset var comma = 0>

		<cfif arguments.index LT count>
			<!--- the comma after the member goes, with the white space up to the next one --->
			<cfset end = arguments.spans[arguments.index + 1].start - 1>
		<cfelseif arguments.index GT 1>
			<!--- the last member: the comma before it goes, with the white space around it --->
			<cfset comma = Find(",", arguments.body, arguments.spans[arguments.index - 1].end + 1)>
			<cfset start = comma>
		<cfelse>
			<!--- the only member: the white space in the braces stays --->
			<cfset end = arguments.spans[arguments.index].end>
		</cfif>

		<cfreturn Mid(arguments.body, 1, start - 1) & Mid(arguments.body, end + 1, Len(arguments.body))>
	</cffunction>

	<cffunction name="getPostedToken" access="private" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfset var tokenName = this.config.tokenName>
		<cfset var headerName = this.config.headerName>
		<cfset var token = "">
		<cfset var body = "">
		<cfset var json = "">
		<cfset var result = "">

		<!--- 1. Check POST data first. --->
		<cfset token = arguments.request_.getPost(tokenName)>

		<cfif isNonEmptyTokenString(token)>
			<cfreturn token>
		</cfif>

		<!--- 2. Check header data next. --->
		<cfif arguments.request_.hasHeader(headerName)>
			<cfset token = arguments.request_.header(headerName).getValue()>

			<cfif isNonEmptyTokenString(token)>
				<cfreturn token>
			</cfif>
		</cfif>

		<!--- 3. Finally, check the raw input data for JSON or form-encoded data. --->
		<cfset body = arguments.request_.getBody()>

		<cfif is_null(body)>
			<cfreturn "">
		</cfif>

		<!--- 3a. Check if a JSON payload exists and contains the token. --->
		<cftry>
			<cfset json = json_decode(body)>

			<cfcatch type="ColdIgniter.JsonException">
				<cfset json = "">
			</cfcatch>
		</cftry>

		<cfif IsStruct(json) AND array_key_exists(tokenName, json)>
			<cfset token = json[tokenName]>

			<cfif isNonEmptyTokenString(token)>
				<cfreturn token>
			</cfif>
		</cfif>

		<!--- 3b. Check if form-encoded data exists and contains the token. --->
		<cfset result = parse_str(body)>
		<cfset token = "">

		<cfif array_key_exists(tokenName, result)>
			<cfset token = result[tokenName]>
		</cfif>

		<cfif isNonEmptyTokenString(token)>
			<cfreturn token>
		</cfif>

		<cfreturn "">
	</cffunction>

	<cffunction name="isNonEmptyTokenString" access="private" returntype="boolean" output="no">
		<cfargument name="token" type="any" required="yes">

		<cfreturn IsSimpleValue(arguments.token) AND NOT is_null(arguments.token)>
	</cffunction>

	<!---
	 * Returns the CSRF Token.
	--->
	<cffunction name="getHash" access="public" returntype="any" output="no">

		<cfif this.config.tokenRandomize>
			<cfreturn randomize_(this.hash_)>
		</cfif>

		<cfreturn this.hash_>
	</cffunction>

	<!---
	 * Randomize hash to avoid BREACH attacks.
	 *
	 * @param hash_ CSRF hash
	 *
	 * @return string CSRF token
	--->
	<cffunction name="randomize_" access="private" returntype="string" output="no">
		<cfargument name="hash_" type="string" required="yes">
		<cfset var keyBinary = random_bytes(this.CSRF_HASH_BYTES)>
		<cfset var hashBinary = "">

		<cftry>
			<cfset hashBinary = hex2bin(arguments.hash_)>

			<cfcatch type="ColdIgniter.ErrorException">
				<cfthrow type="ColdIgniter.LogicException" message="$hash is invalid: #arguments.hash_#">
			</cfcatch>
		</cftry>

		<!--- the joined binary string of the original is the hexadecimal text of both parts here --->
		<cfreturn bin2hex(bitxor_(hashBinary, keyBinary)) & bin2hex(keyBinary)>
	</cffunction>

	<!---
	 * Derandomize the token.
	 *
	 * @param token CSRF token
	 *
	 * @return string CSRF hash
	 *
	 * @throws InvalidArgumentException "hex2bin(): Hexadecimal input string must have an even length"
	--->
	<cffunction name="derandomize" access="private" returntype="string" output="no">
		<cfargument name="token" type="string" required="yes">
		<cfset var key = substr(arguments.token, -this.CSRF_HASH_BYTES * 2)>
		<cfset var value = substr(arguments.token, 0, this.CSRF_HASH_BYTES * 2)>

		<cftry>
			<cfreturn bin2hex(bitxor_(hex2bin(value), hex2bin(key)))>

			<cfcatch type="ColdIgniter.ErrorException">
				<!--- "hex2bin(): Hexadecimal input string must have an even length" --->
				<cfthrow type="ColdIgniter.InvalidArgumentException" message="#cfcatch.message#">
			</cfcatch>
		</cftry>
	</cffunction>

	<!---
	 * Returns the CSRF Token Name.
	--->
	<cffunction name="getTokenName" access="public" returntype="string" output="no">

		<cfreturn this.config.tokenName>
	</cffunction>

	<!---
	 * Returns the CSRF Header Name.
	--->
	<cffunction name="getHeaderName" access="public" returntype="string" output="no">

		<cfreturn this.config.headerName>
	</cffunction>

	<!---
	 * Returns the CSRF Cookie Name.
	--->
	<cffunction name="getCookieName" access="public" returntype="string" output="no">

		<cfreturn this.config.cookieName>
	</cffunction>

	<!---
	 * Check if request should be redirect on failure.
	--->
	<cffunction name="shouldRedirect" access="public" returntype="boolean" output="no">

		<cfreturn this.config.redirect>
	</cffunction>

	<!---
	 * Sanitize Filename
	 *
	 * Tries to sanitize filenames in order to prevent directory traversal attempts
	 * and other security threats, which is particularly useful for files that
	 * were supplied via user input.
	 *
	 * If it is acceptable for the user input to include relative paths,
	 * e.g. file/in/some/approved/folder.txt, you can set the second optional
	 * parameter, relativePath to true.
	 *
	 * @deprecated 4.6.2 Use `sanitize_filename()` instead
	 *
	 * @param str          Input file name
	 * @param relativePath Whether to preserve paths
	--->
	<cffunction name="sanitizeFilename" access="public" returntype="string" output="no">
		<cfargument name="str" type="string" required="yes">
		<cfargument name="relativePath" type="boolean" required="no" default="false">

		<cfset helper("security")>

		<cfreturn sanitize_filename(arguments.str, arguments.relativePath)>
	</cffunction>

	<!---
	 * Restore hash from Session or Cookie
	--->
	<cffunction name="restoreHash" access="private" returntype="void" output="no">

		<cfif isCSRFCookie()>
			<cfif isHashInCookie()>
				<cfset this.hash_ = this.hashInCookie>
			</cfif>
		<cfelseif this.session_.has(this.config.tokenName)>
			<!--- Session based CSRF protection --->
			<cfset this.hash_ = this.session_.get(this.config.tokenName)>
		</cfif>
	</cffunction>

	<!---
	 * Generates (Regenerates) the CSRF Hash.
	--->
	<cffunction name="generateHash" access="public" returntype="string" output="no">

		<cfset this.hash_ = bin2hex(random_bytes(this.CSRF_HASH_BYTES))>

		<cfif isCSRFCookie()>
			<cfset saveHashInCookie()>
		<cfelse>
			<!--- Session based CSRF protection --->
			<cfset saveHashInSession()>
		</cfif>

		<cfreturn this.hash_>
	</cffunction>

	<cffunction name="isHashInCookie" access="private" returntype="boolean" output="no">
		<cfset var length = this.CSRF_HASH_BYTES * 2>
		<cfset var pattern = "">

		<cfif is_null(this.hashInCookie) OR NOT IsSimpleValue(this.hashInCookie)>
			<cfreturn false>
		</cfif>

		<cfset pattern = "##^[0-9a-f]{" & length & "}$##iS">

		<!--- unguarded: the pattern is linear, and a long cookie must give false, not an error --->
		<cfreturn preg_match(pattern, this.hashInCookie, true) EQ 1>
	</cffunction>

	<cffunction name="saveHashInCookie" access="private" returntype="void" output="no">
		<cfset var expires = 0>
		<cfset var response = "">

		<cfif this.config.expires NEQ 0>
			<cfset expires = time() + this.config.expires>
		</cfif>

		<cfset this.cookie_ = new_("ColdIgniter\Cookie\Cookie", this.rawCookieName, this.hash_, array_("expires", expires))>

		<cfset response = service("response")>
		<cfset response.setCookie(this.cookie_)>
	</cffunction>

	<cffunction name="saveHashInSession" access="private" returntype="void" output="no">

		<cfset this.session_.set(this.config.tokenName, this.hash_)>
	</cffunction>

</cfcomponent>
