<!---
 * Representation of an outgoing, server-side response.
 *
 * Per the HTTP specification, this interface includes properties for
 * each of the following:
 *
 * - Protocol version
 * - Status code and reason phrase
 * - Headers
 * - Message body
 *
 * The body is not written to the client here. No output can leave a
 * method, so send() leaves the body in request.ColdIgniter.output and
 * the front controller writes it.
 *
 * Not ported yet: download, setJSON, setXML, setDate, setLastModified and setCache.
--->
<cfcomponent output="no" extends="Message" hint="Representation of an outgoing, server-side response">

	<!---
	 * HTTP status codes
	--->
	<cfset this.statusCodes = CreateObject("java", "java.util.LinkedHashMap").init()>
	<!--- 1xx: Informational --->
	<cfset this.statusCodes["100"] = "Continue">
	<cfset this.statusCodes["101"] = "Switching Protocols">
	<cfset this.statusCodes["102"] = "Processing"> <!--- http://www.iana.org/go/rfc2518 --->
	<cfset this.statusCodes["103"] = "Early Hints"> <!--- http://www.ietf.org/rfc/rfc8297.txt --->
	<!--- 2xx: Success --->
	<cfset this.statusCodes["200"] = "OK">
	<cfset this.statusCodes["201"] = "Created">
	<cfset this.statusCodes["202"] = "Accepted">
	<cfset this.statusCodes["203"] = "Non-Authoritative Information"> <!--- 1.1 --->
	<cfset this.statusCodes["204"] = "No Content">
	<cfset this.statusCodes["205"] = "Reset Content">
	<cfset this.statusCodes["206"] = "Partial Content">
	<cfset this.statusCodes["207"] = "Multi-Status"> <!--- http://www.iana.org/go/rfc4918 --->
	<cfset this.statusCodes["208"] = "Already Reported"> <!--- http://www.iana.org/go/rfc5842 --->
	<cfset this.statusCodes["226"] = "IM Used"> <!--- 1.1; http://www.ietf.org/rfc/rfc3229.txt --->
	<!--- 3xx: Redirection --->
	<cfset this.statusCodes["300"] = "Multiple Choices">
	<cfset this.statusCodes["301"] = "Moved Permanently">
	<cfset this.statusCodes["302"] = "Found"> <!--- Formerly 'Moved Temporarily' --->
	<cfset this.statusCodes["303"] = "See Other"> <!--- 1.1 --->
	<cfset this.statusCodes["304"] = "Not Modified">
	<cfset this.statusCodes["305"] = "Use Proxy"> <!--- 1.1 --->
	<cfset this.statusCodes["306"] = "Switch Proxy"> <!--- No longer used --->
	<cfset this.statusCodes["307"] = "Temporary Redirect"> <!--- 1.1 --->
	<cfset this.statusCodes["308"] = "Permanent Redirect"> <!--- 1.1; Experimental; http://www.ietf.org/rfc/rfc7238.txt --->
	<!--- 4xx: Client error --->
	<cfset this.statusCodes["400"] = "Bad Request">
	<cfset this.statusCodes["401"] = "Unauthorized">
	<cfset this.statusCodes["402"] = "Payment Required">
	<cfset this.statusCodes["403"] = "Forbidden">
	<cfset this.statusCodes["404"] = "Not Found">
	<cfset this.statusCodes["405"] = "Method Not Allowed">
	<cfset this.statusCodes["406"] = "Not Acceptable">
	<cfset this.statusCodes["407"] = "Proxy Authentication Required">
	<cfset this.statusCodes["408"] = "Request Timeout">
	<cfset this.statusCodes["409"] = "Conflict">
	<cfset this.statusCodes["410"] = "Gone">
	<cfset this.statusCodes["411"] = "Length Required">
	<cfset this.statusCodes["412"] = "Precondition Failed">
	<cfset this.statusCodes["413"] = "Content Too Large"> <!--- https://www.iana.org/assignments/http-status-codes/http-status-codes.xml --->
	<cfset this.statusCodes["414"] = "URI Too Long"> <!--- https://www.iana.org/assignments/http-status-codes/http-status-codes.xml --->
	<cfset this.statusCodes["415"] = "Unsupported Media Type">
	<cfset this.statusCodes["416"] = "Requested Range Not Satisfiable">
	<cfset this.statusCodes["417"] = "Expectation Failed">
	<cfset this.statusCodes["418"] = "I'm a teapot"> <!--- April's Fools joke; http://www.ietf.org/rfc/rfc2324.txt --->
	<!--- 419 (Authentication Timeout) is a non-standard status code with unknown origin --->
	<cfset this.statusCodes["421"] = "Misdirected Request"> <!--- http://www.iana.org/go/rfc7540 Section 9.1.2 --->
	<cfset this.statusCodes["422"] = "Unprocessable Content"> <!--- https://www.iana.org/assignments/http-status-codes/http-status-codes.xml --->
	<cfset this.statusCodes["423"] = "Locked"> <!--- http://www.iana.org/go/rfc4918 --->
	<cfset this.statusCodes["424"] = "Failed Dependency"> <!--- http://www.iana.org/go/rfc4918 --->
	<cfset this.statusCodes["425"] = "Too Early"> <!--- https://datatracker.ietf.org/doc/draft-ietf-httpbis-replay/ --->
	<cfset this.statusCodes["426"] = "Upgrade Required">
	<cfset this.statusCodes["428"] = "Precondition Required"> <!--- 1.1; http://www.ietf.org/rfc/rfc6585.txt --->
	<cfset this.statusCodes["429"] = "Too Many Requests"> <!--- 1.1; http://www.ietf.org/rfc/rfc6585.txt --->
	<cfset this.statusCodes["431"] = "Request Header Fields Too Large"> <!--- 1.1; http://www.ietf.org/rfc/rfc6585.txt --->
	<cfset this.statusCodes["451"] = "Unavailable For Legal Reasons"> <!--- http://tools.ietf.org/html/rfc7725 --->
	<cfset this.statusCodes["499"] = "Client Closed Request"> <!--- http://lxr.nginx.org/source/src/http/ngx_http_request.h#L133 --->
	<!--- 5xx: Server error --->
	<cfset this.statusCodes["500"] = "Internal Server Error">
	<cfset this.statusCodes["501"] = "Not Implemented">
	<cfset this.statusCodes["502"] = "Bad Gateway">
	<cfset this.statusCodes["503"] = "Service Unavailable">
	<cfset this.statusCodes["504"] = "Gateway Timeout">
	<cfset this.statusCodes["505"] = "HTTP Version Not Supported">
	<cfset this.statusCodes["506"] = "Variant Also Negotiates"> <!--- 1.1; http://www.ietf.org/rfc/rfc2295.txt --->
	<cfset this.statusCodes["507"] = "Insufficient Storage"> <!--- http://www.iana.org/go/rfc4918 --->
	<cfset this.statusCodes["508"] = "Loop Detected"> <!--- http://www.iana.org/go/rfc5842 --->
	<cfset this.statusCodes["510"] = "Not Extended"> <!--- http://www.ietf.org/rfc/rfc2774.txt --->
	<cfset this.statusCodes["511"] = "Network Authentication Required"> <!--- http://www.ietf.org/rfc/rfc6585.txt --->
	<cfset this.statusCodes["599"] = "Network Connect Timeout Error"> <!--- https://httpstatuses.com/599 --->

	<!---
	 * The current reason phrase for this response.
	 * If empty string, will use the default provided for the status code.
	--->
	<cfset this.reason = "">

	<!---
	 * The current status code for this response.
	 * The status code is a 3-digit integer result code of the server's attempt
	 * to understand and satisfy the request.
	--->
	<cfset this.statusCode = 200>

	<!---
	 * If true, will not write output. Useful during testing.
	 *
	 * Named with an underscore, because pretend() is a method.
	--->
	<cfset this.pretend_ = false>

	<!---
	 * Our cookie store (a CookieStore). It is made in the constructor.
	--->
	<cfset this.cookieStore = "">

	<!---
	 * Content security policy (a ContentSecurityPolicy).
	 *
	 * Difference: the original makes it in the constructor, as the policy
	 * has to be there even when it is off. Here it is made by getCSP() on
	 * the first call, so a request with the policy off pays nothing for it.
	 * An empty string until then.
	--->
	<cfset this.CSP = "">

	<!---
	 * Constructor
	 *
	 * @param config
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfset var cookieConfig = variables.config("Config\Cookie")>
		<cfset var cookieStatic = static_("ColdIgniter\Cookie\Cookie")>

		<!---
		 Default to a non-caching page.
		 Also ensures that a Cache-control header exists.
		--->
		<cfset noCache()>

		<!---
		 Difference: the setting is read once here, as upstream does, so
		 that send() does not look at the config on each request.
		--->
		<cfif IsObject(arguments.config)>
			<cfset variables.CSPEnabled = arguments.config.CSPEnabled>
		<cfelse>
			<cfset variables.CSPEnabled = variables.config("Config\App").CSPEnabled>
		</cfif>

		<cfset this.cookieStore = new_("ColdIgniter\Cookie\CookieStore", ArrayNew(1))>

		<cfset cookieStatic.setDefaults(cookieConfig)>

		<!--- Default to an HTML Content-Type. Devs can override if needed. --->
		<cfset setContentType("text/html")>

		<cfreturn this>
	</cffunction>

	<!---
	 * Turns "pretend" mode on or off to aid in testing.
	 *
	 * Note that this is not a part of the interface so
	 * should not be relied on outside of internal testing.
	--->
	<cffunction name="pretend" access="public" returntype="any" output="no">
		<cfargument name="pretend" type="boolean" required="no" default="true">

		<cfset this.pretend_ = arguments.pretend>

		<cfreturn this>
	</cffunction>

	<!---
	 * Gets the response status code.
	 *
	 * The status code is a 3-digit integer result code of the server's attempt
	 * to understand and satisfy the request.
	 *
	 * @return Status code.
	--->
	<cffunction name="getStatusCode" access="public" returntype="numeric" output="no">
		<cfif this.statusCode EQ 0>
			<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="HTTP Response is missing a status code">
		</cfif>

		<cfreturn this.statusCode>
	</cffunction>

	<!---
	 * Gets the response reason phrase associated with the status code.
	 *
	 * Because a reason phrase is not a required element in a response
	 * status line, the reason phrase value MAY be null. Implementations MAY
	 * choose to return the default RFC 7231 recommended reason phrase (or those
	 * listed in the IANA HTTP Status Code Registry) for the response's
	 * status code.
	 *
	 * @see http://tools.ietf.org/html/rfc7231#section-6
	 * @see http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml
	 *
	 * @return Reason phrase; must return an empty string if none present.
	--->
	<cffunction name="getReasonPhrase" access="public" returntype="string" output="no">
		<cfif this.reason EQ "">
			<cfif this.statusCode EQ 0>
				<cfreturn "">
			</cfif>

			<cfreturn this.statusCodes[JavaCast("string", this.statusCode)]>
		</cfif>

		<cfreturn this.reason>
	</cffunction>

	<!---
	 * Return an instance with the specified status code and, optionally, reason phrase.
	 *
	 * If no reason phrase is specified, will default recommended reason phrase for
	 * the response's status code.
	 *
	 * @see http://tools.ietf.org/html/rfc7231#section-6
	 * @see http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml
	 *
	 * @param code   The 3-digit integer result code to set.
	 * @param reason The reason phrase to use with the
	 *               provided status code; if none is provided, will
	 *               default to the IANA name.
	--->
	<cffunction name="setStatusCode" access="public" returntype="any" output="no">
		<cfargument name="code" type="numeric" required="yes">
		<cfargument name="reason" type="string" required="no" default="">

		<!--- Valid range? --->
		<cfif arguments.code LT 100 OR arguments.code GT 599>
			<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="#arguments.code# is not a valid HTTP return status code">
		</cfif>

		<!--- Unknown and no message? --->
		<cfif NOT StructKeyExists(this.statusCodes, JavaCast("string", arguments.code)) AND arguments.reason EQ "">
			<cfthrow type="ColdIgniter.HTTP.Exceptions.HTTPException" message="Unknown HTTP status code provided with no message: #arguments.code#">
		</cfif>

		<cfset this.statusCode = arguments.code>

		<cfif arguments.reason NEQ "">
			<cfset this.reason = arguments.reason>
		<cfelse>
			<cfset this.reason = this.statusCodes[JavaCast("string", arguments.code)]>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the Content Type header for this response with the mime type
	 * and, optionally, the charset.
	--->
	<cffunction name="setContentType" access="public" returntype="any" output="no">
		<cfargument name="mime" type="string" required="yes">
		<cfargument name="charset" type="string" required="no" default="UTF-8">

		<!--- add charset attribute if not already there and provided as parm --->
		<cfif Find("charset=", arguments.mime) LT 2 AND arguments.charset NEQ "">
			<cfset arguments.mime = arguments.mime & "; charset=" & arguments.charset>
		</cfif>

		<cfset removeHeader("Content-Type")> <!--- replace existing content type --->
		<cfset setHeader("Content-Type", arguments.mime)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the appropriate headers to ensure this response
	 * is not cached by the browsers.
	--->
	<cffunction name="noCache" access="public" returntype="any" output="no">
		<cfset var value = ArrayNew(1)>

		<cfset ArrayAppend(value, "no-store")>
		<cfset ArrayAppend(value, "max-age=0")>
		<cfset ArrayAppend(value, "no-cache")>

		<cfset removeHeader("Cache-Control")>
		<cfset setHeader("Cache-Control", value)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sends the output to the browser.
	--->
	<cffunction name="send" access="public" returntype="any" output="no">
		<!---
		 If we're enforcing a Content Security Policy,
		 we need to give it a chance to build out it's headers.

		 Difference: the policy object is not made when the policy is off.
		 The default nonce tags are taken out of the body here then, after
		 a single Find() that tells if there is one; a tag the config renamed
		 is only taken out when the policy object exists.
		--->
		<cfif IsObject(this.CSP) OR variables.CSPEnabled>
			<cfset getCSP().finalize(this)>
		<cfelseif IsSimpleValue(this.body) AND Find("{csp-", this.body) GT 0>
			<cfset this.body = Replace(this.body, "{csp-style-nonce}", "", "all")>
			<cfset this.body = Replace(this.body, "{csp-script-nonce}", "", "all")>
		</cfif>

		<cfset sendHeaders()>
		<cfset sendCookies()>
		<cfset sendBody()>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sends the headers of this HTTP response to the browser.
	--->
	<cffunction name="sendHeaders" access="public" returntype="any" output="no">
		<cfset var headers = "">
		<cfset var name = "">
		<cfset var i = 0>

		<!--- Have the headers already been sent? --->
		<cfif this.pretend_>
			<cfreturn this>
		</cfif>

		<!--- Not ported yet: the Date header --->

		<!--- HTTP Status --->
		<cfheader statuscode="#getStatusCode()#" statustext="#getReasonPhrase()#">

		<!--- Send all of our headers --->
		<cfset headers = this.headers()>
		<cfloop collection="#headers#" item="name">
			<cfif IsArray(headers[name])>
				<!--- several headers of the same name (see addHeader) --->
				<cfloop from="1" to="#ArrayLen(headers[name])#" index="i">
					<cfheader name="#name#" value="#headers[name][i].getValueLine()#">
				</cfloop>
			<cfelseif name EQ "Content-Type">
				<cfcontent type="#headers[name].getValueLine()#">
			<cfelse>
				<cfheader name="#name#" value="#headers[name].getValueLine()#">
			</cfif>
		</cfloop>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sends the Body of the message to the browser.
	--->
	<cffunction name="sendBody" access="public" returntype="any" output="no">
		<cfset request.ColdIgniter.output = request.ColdIgniter.output & this.body>

		<cfreturn this>
	</cffunction>

	<!---
	 * Set a cookie
	 *
	 * Accepts an arbitrary number of binds (up to 7) or a map in the first
	 * parameter containing all the values.
	 *
	 * @param name     Cookie name / map containing binds / Cookie object
	 * @param value    Cookie value
	 * @param expire   Cookie expiration time in seconds
	 * @param domain   Cookie domain (e.g.: '.yourdomain.com')
	 * @param path     Cookie path (default: '/')
	 * @param prefix   Cookie name prefix ('': the default prefix)
	 * @param secure   Whether to only transfer cookies via SSL; an empty string takes the config
	 * @param httponly Whether only make the cookie accessible via HTTP (no javascript); an empty string takes the config
	 * @param samesite An empty string takes the config
	 *
	 * @return $this
	 *
	 * Difference: a null is an empty string. A false for secure or httponly is
	 * kept as false.
	--->
	<cffunction name="setCookie" access="public" returntype="any" output="no">
		<cfargument name="name" type="any" required="yes">
		<cfargument name="value" type="string" required="no" default="">
		<cfargument name="expire" type="any" required="no" default="0">
		<cfargument name="domain" type="string" required="no" default="">
		<cfargument name="path" type="string" required="no" default="/">
		<cfargument name="prefix" type="string" required="no" default="">
		<cfargument name="secure" type="any" required="no" default="">
		<cfargument name="httponly" type="any" required="no" default="">
		<cfargument name="samesite" type="any" required="no" default="">
		<cfset var name_ = arguments.name>
		<cfset var value_ = arguments.value>
		<cfset var expire_ = arguments.expire>
		<cfset var domain_ = arguments.domain>
		<cfset var path_ = arguments.path>
		<cfset var prefix_ = arguments.prefix>
		<cfset var secure_ = arguments.secure>
		<cfset var httponly_ = arguments.httponly>
		<cfset var samesite_ = arguments.samesite>
		<cfset var cookieConfig = "">
		<cfset var items = "samesite,value,expire,domain,path,prefix,secure,httponly,name">
		<cfset var item = "">
		<cfset var cookie_ = "">

		<cfif instanceof_(name_, "ColdIgniter\Cookie\Cookie")>
			<cfset this.cookieStore = this.cookieStore.put(name_)>

			<cfreturn this>
		</cfif>

		<cfset cookieConfig = config("Config\Cookie")>

		<cfif is_null(secure_)>
			<cfset secure_ = cookieConfig.secure>
		</cfif>

		<cfif is_null(httponly_)>
			<cfset httponly_ = cookieConfig.httponly>
		</cfif>

		<cfif is_null(samesite_)>
			<cfset samesite_ = cookieConfig.samesite>
		</cfif>

		<cfif IsStruct(name_)>
			<!--- always leave 'name' in last place, as the original does --->
			<cfloop list="#items#" index="item">
				<cfif StructKeyExists(arguments.name, item) AND NOT is_null(arguments.name[item])>
					<cfif Compare(item, "samesite") EQ 0>
						<cfset samesite_ = arguments.name[item]>
					<cfelseif Compare(item, "value") EQ 0>
						<cfset value_ = arguments.name[item]>
					<cfelseif Compare(item, "expire") EQ 0>
						<cfset expire_ = arguments.name[item]>
					<cfelseif Compare(item, "domain") EQ 0>
						<cfset domain_ = arguments.name[item]>
					<cfelseif Compare(item, "path") EQ 0>
						<cfset path_ = arguments.name[item]>
					<cfelseif Compare(item, "prefix") EQ 0>
						<cfset prefix_ = arguments.name[item]>
					<cfelseif Compare(item, "secure") EQ 0>
						<cfset secure_ = arguments.name[item]>
					<cfelseif Compare(item, "httponly") EQ 0>
						<cfset httponly_ = arguments.name[item]>
					<cfelse>
						<cfset name_ = arguments.name[item]>
					</cfif>
				</cfif>
			</cfloop>
		</cfif>

		<cfif IsNumeric(expire_)>
			<cfif expire_ GT 0>
				<cfset expire_ = time() + expire_>
			<cfelse>
				<cfset expire_ = 0>
			</cfif>
		<cfelse>
			<cfset expire_ = 0>
		</cfif>

		<cfset cookie_ = new_("ColdIgniter\Cookie\Cookie", name_, value_, array_("expires", expire_, "domain", domain_, "path", path_, "prefix", prefix_, "secure", secure_, "httponly", httponly_, "samesite", samesite_))>

		<cfset this.cookieStore = this.cookieStore.put(cookie_)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Returns the current Content Security Policy object, made on the first call.
	 *
	 * We need the object even if the policy is not enabled, to avoid
	 * calls to non existing methods.
	--->
	<cffunction name="getCSP" access="public" returntype="any" output="no">
		<cfif NOT IsObject(this.CSP)>
			<cfset this.CSP = service("csp")>
		</cfif>

		<cfreturn this.CSP>
	</cffunction>

	<!---
	 * Returns the `CookieStore` instance.
	 *
	 * @return CookieStore
	--->
	<cffunction name="getCookieStore" access="public" returntype="any" output="no">
		<cfreturn this.cookieStore>
	</cffunction>

	<!---
	 * Checks to see if the Response has a specified cookie or not.
	 *
	 * @param value An empty string stands for null: any value
	--->
	<cffunction name="hasCookie" access="public" returntype="boolean" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="value" type="any" required="no" default="">
		<cfargument name="prefix" type="string" required="no" default="">
		<cfset var prefix_ = arguments.prefix>
		<cfset var defaults = "">

		<cfif prefix_ EQ "">
			<cfset defaults = static_("ColdIgniter\Cookie\Cookie").setDefaults()>
			<cfset prefix_ = defaults["prefix"]><!--- to retain BC --->
		</cfif>

		<cfreturn this.cookieStore.has(arguments.name, prefix_, arguments.value)>
	</cffunction>

	<!---
	 * Returns the cookie
	 *
	 * @param prefix Cookie prefix. '': the default prefix
	 *
	 * @return A map of Cookie, a Cookie, or an empty string (null)
	--->
	<cffunction name="getCookie" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="no" default="">
		<cfargument name="prefix" type="string" required="no" default="">
		<cfset var prefix_ = arguments.prefix>
		<cfset var defaults = "">
		<cfset var result = "">

		<cfif arguments.name EQ "">
			<cfreturn this.cookieStore.display()>
		</cfif>

		<cftry>
			<cfif prefix_ EQ "">
				<cfset defaults = static_("ColdIgniter\Cookie\Cookie").setDefaults()>
			<cfset prefix_ = defaults["prefix"]><!--- to retain BC --->
			</cfif>

			<cfset result = this.cookieStore.get(arguments.name, prefix_)>

			<cfcatch type="ColdIgniter.Cookie.Exceptions.CookieException">
				<cfset log_message("error", cfcatch.type & ": " & cfcatch.message)>
				<cfset result = "">
			</cfcatch>
		</cftry>

		<cfreturn result>
	</cffunction>

	<!---
	 * Sets a cookie to be deleted when the response is sent.
	 *
	 * @return $this
	--->
	<cffunction name="deleteCookie" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="no" default="">
		<cfargument name="domain" type="string" required="no" default="">
		<cfargument name="path" type="string" required="no" default="/">
		<cfargument name="prefix" type="string" required="no" default="">
		<cfset var prefix_ = arguments.prefix>
		<cfset var defaults = "">
		<cfset var prefixed = "">
		<cfset var store = this.cookieStore>
		<cfset var found = false>
		<cfset var cookie_ = "">
		<cfset var list = "">
		<cfset var i = 0>

		<cfif arguments.name EQ "">
			<cfreturn this>
		</cfif>

		<cfif prefix_ EQ "">
			<cfset defaults = static_("ColdIgniter\Cookie\Cookie").setDefaults()>
			<cfset prefix_ = defaults["prefix"]><!--- to retain BC --->
		</cfif>

		<cfset prefixed = prefix_ & arguments.name>
		<cfset list = store.getIterator()>

		<cfloop from="1" to="#ArrayLen(list)#" index="i">
			<cfif NOT found AND Compare(list[i].getPrefixedName(), prefixed) EQ 0>
				<cfif Compare(arguments.domain, list[i].getDomain()) EQ 0 AND Compare(arguments.path, list[i].getPath()) EQ 0>
					<cfset cookie_ = list[i].withValue("").withExpired()>
					<cfset found = true>
					<cfset this.cookieStore = store.put(cookie_)>
				</cfif>
			</cfif>
		</cfloop>

		<cfif NOT found>
			<cfset setCookie(arguments.name, "", 0, arguments.domain, arguments.path, prefix_)>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Returns all cookies currently set.
	 *
	 * @return A map of Cookie, by id
	--->
	<cffunction name="getCookies" access="public" returntype="any" output="no">
		<cfreturn this.cookieStore.display()>
	</cffunction>

	<!---
	 * Actually sets the cookies.
	--->
	<cffunction name="sendCookies" access="private" returntype="void" output="no">
		<cfif this.pretend_>
			<cfreturn>
		</cfif>

		<cfset dispatchCookies()>
	</cffunction>

	<!---
	 * Sends each cookie as a Set-Cookie header and empties the store.
	 *
	 * Difference: the original hands each cookie to the engine's cookie
	 * function. Here the header is written by hand, one cfheader for each
	 * cookie (the built in cfcookie upper-cases the name and has no
	 * HttpOnly). The name, the value, the path, the domain, the prefix and
	 * the SameSite are checked by Cookie, so the header text cannot carry a
	 * line break.
	--->
	<cffunction name="dispatchCookies" access="private" returntype="void" output="no">
		<cfset var request_ = service("request")>
		<cfset var list = this.cookieStore.getIterator()>
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(list)#" index="i">
			<cfif list[i].isSecure() AND NOT request_.isSecure()>
				<cfset static_("ColdIgniter\Security\Exceptions\SecurityException").forInsecureCookie()>
			</cfif>

			<cfheader name="Set-Cookie" value="#list[i].toHeaderString()#">
		</cfloop>

		<cfset this.cookieStore.clear()>
	</cffunction>

	<!---
	 * Perform a redirect to a new URL, in two flavors: header or location.
	 *
	 * @param uri    The URI to redirect to
	 * @param method The flavor, 'auto', 'location' or 'refresh'
	 * @param code   The type of redirection, defaults to 302 (an empty
	 *               string stands for null)
	 *
	 * @return this
	 *
	 * @throws HTTPException For invalid status code.
	--->
	<cffunction name="redirect" access="public" returntype="any" output="no">
		<cfargument name="uri" type="string" required="yes">
		<cfargument name="method" type="string" required="no" default="auto">
		<cfargument name="code" type="any" required="no" default="">
		<cfset var superglobals = "">
		<cfset var serverSoftware = "">
		<cfset var serverProtocol = "">
		<cfset var requestMethod = "">

		<!--- IIS environment likely? Use 'refresh' for better compatibility --->
		<cfset superglobals = service("superglobals")>
		<cfset serverSoftware = superglobals.server("SERVER_SOFTWARE")>
		<cfif Compare(arguments.method, "auto") EQ 0
			AND NOT is_null(serverSoftware)
			AND Find("Microsoft-IIS", serverSoftware) GT 0>
			<cfset arguments.method = "refresh">
		<cfelseif Compare(arguments.method, "refresh") NEQ 0 AND is_null(arguments.code)>
			<!--- override status code for HTTP/1.1 & higher --->
			<cfset serverProtocol = superglobals.server("SERVER_PROTOCOL")>
			<cfset requestMethod = superglobals.server("REQUEST_METHOD")>
			<cfif NOT is_null(serverProtocol)
				AND NOT is_null(requestMethod)
				AND getProtocolVersion() GTE 1.1>
				<cfif Compare(requestMethod, static_("ColdIgniter\HTTP\Method").GET) EQ 0>
					<cfset arguments.code = 302>
				<cfelseif Compare(requestMethod, static_("ColdIgniter\HTTP\Method").POST) EQ 0
					OR Compare(requestMethod, static_("ColdIgniter\HTTP\Method").PUT) EQ 0
					OR Compare(requestMethod, static_("ColdIgniter\HTTP\Method").DELETE) EQ 0>
					<!--- reference: https://en.wikipedia.org/wiki/Post/Redirect/Get --->
					<cfset arguments.code = 303>
				<cfelse>
					<cfset arguments.code = 307>
				</cfif>
			</cfif>
		</cfif>

		<cfif is_null(arguments.code)>
			<cfset arguments.code = 302>
		</cfif>

		<cfif Compare(arguments.method, "refresh") EQ 0>
			<cfset setHeader("Refresh", "0;url=" & arguments.uri)>
		<cfelse>
			<cfset setHeader("Location", arguments.uri)>
		</cfif>

		<cfset setStatusCode(arguments.code)>

		<cfreturn this>
	</cffunction>

</cfcomponent>
