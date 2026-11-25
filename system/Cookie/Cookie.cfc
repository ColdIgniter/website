<!---
 * A `Cookie` class represents an immutable HTTP cookie value object.
 * Being immutable, modifying one or more of its attributes will return
 * a new `Cookie` instance, rather than modifying itself. Users should
 * reassign this new instance to a new variable to capture it.
 *
 *     <cfset cookie = new_("ColdIgniter\Cookie\Cookie", "test_cookie", "test_value")>
 *     cookie.getName()   -> test_cookie
 *     cookie.withName("prod_cookie")
 *     cookie.getName()   -> test_cookie
 *     cookie2 = cookie.withName("prod_cookie")
 *     cookie2.getName()  -> prod_cookie
 *
 * Difference: the options are a map made with array_() (or a struct), the
 * keys are the lower case names: prefix, max-age, expires, path, domain,
 * secure, httponly, samesite, raw. The expires time is a Unix timestamp,
 * or a string of digits; a date object and a date text are not ported.
 * The static members (the defaults) live on static_("ColdIgniter\Cookie\Cookie").
 * A clone is made by clone_(), because the copy of an object is not
 * possible here. The cookie has no ArrayAccess, so offsetExists(),
 * offsetGet(), offsetSet() and offsetUnset() are called by name.
--->
<cfcomponent output="no" extends="CloneableCookieInterface" hint="An immutable HTTP cookie value object">

	<!---
	 * @var string
	--->
	<cfset this.prefix = "">

	<!---
	 * @var string
	--->
	<cfset this.name = "">

	<!---
	 * @var string
	--->
	<cfset this.value = "">

	<!---
	 * @var int Unix timestamp
	--->
	<cfset this.expires = 0>

	<!---
	 * @var string
	--->
	<cfset this.path = "/">

	<!---
	 * @var string
	--->
	<cfset this.domain = "">

	<!---
	 * @var bool
	--->
	<cfset this.secure = false>

	<!---
	 * @var bool
	--->
	<cfset this.httponly = true>

	<!---
	 * @var string
	--->
	<cfset this.samesite = this.SAMESITE_LAX>

	<!---
	 * @var bool
	--->
	<cfset this.raw = false>

	<!---
	 * Default attributes for a Cookie object. The keys here are the
	 * lowercase attribute names. Do not camelCase!
	 *
	 * Static: read it with static_("ColdIgniter\Cookie\Cookie").defaults.
	 *
	 * @var a map (see array_())
	--->
	<cfset this.defaults = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.defaults["prefix"] = "">
	<cfset this.defaults["expires"] = 0>
	<cfset this.defaults["path"] = "/">
	<cfset this.defaults["domain"] = "">
	<cfset this.defaults["secure"] = false>
	<cfset this.defaults["httponly"] = true>
	<cfset this.defaults["samesite"] = this.SAMESITE_LAX>
	<cfset this.defaults["raw"] = false>

	<!---
	 * A cookie name can be any US-ASCII characters, except control characters,
	 * spaces, tabs, or separator characters.
	 *
	 * @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#attributes
	 * @see https://tools.ietf.org/html/rfc2616#section-2.2
	 *
	 * @var string
	--->
	<cfset this.reservedCharsList = "=,; " & Chr(9) & Chr(13) & Chr(10) & Chr(11) & Chr(12) & Chr(0) & "()<>@:\""/[]?{}">

	<!---
	 * Prohibited characters in cookie prefix and name.
	 *
	 * @var string
	--->
	<cfset this.reservedPrefixCharsList = "=,; " & Chr(9) & Chr(13) & Chr(10) & Chr(11) & Chr(12) & Chr(0)>

	<!---
	 * Prohibited characters in a cookie value, a path and a domain.
	 *
	 * @var string
	--->
	<cfset this.reservedValueCharsList = ",; " & Chr(9) & Chr(13) & Chr(10) & Chr(11) & Chr(12) & Chr(0)>

	<!---
	 * Set the default attributes to a Cookie instance by injecting
	 * the values from the `CookieConfig` config or a map.
	 * This method is called from Response::__construct().
	 *
	 * Static: call it on static_("ColdIgniter\Cookie\Cookie").
	 *
	 * @param config A config of Config\Cookie, or a map
	 *
	 * @return The old defaults map. Useful for resetting.
	--->
	<cffunction name="setDefaults" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfset var self = static_("ColdIgniter\Cookie\Cookie")>
		<cfset var oldDefaults = array_merge(self.defaults)>
		<cfset var newDefaults = CreateObject("java", "java.util.LinkedHashMap").init()>

		<cfif IsObject(arguments.config)>
			<cfset newDefaults["prefix"] = arguments.config.prefix>
			<cfset newDefaults["expires"] = arguments.config.expires>
			<cfset newDefaults["path"] = arguments.config.path>
			<cfset newDefaults["domain"] = arguments.config.domain>
			<cfset newDefaults["secure"] = arguments.config.secure>
			<cfset newDefaults["httponly"] = arguments.config.httponly>
			<cfset newDefaults["samesite"] = arguments.config.samesite>
			<cfset newDefaults["raw"] = arguments.config.raw>
		<cfelseif IsStruct(arguments.config)>
			<cfset newDefaults = array_merge(arguments.config)>
		</cfif>

		<!--- this union ensures that even if the passed config is not a config or a map, no empty defaults will occur --->
		<cfset self.defaults = array_merge(oldDefaults, newDefaults)>

		<cfreturn oldDefaults>
	</cffunction>

	<!---
	 * Create a new Cookie instance from a `Set-Cookie` header.
	 *
	 * Static: call it on static_("ColdIgniter\Cookie\Cookie").
	 *
	 * @throws CookieException
	--->
	<cffunction name="fromHeaderString" access="public" returntype="any" output="no">
		<cfargument name="cookie_" type="string" required="yes">
		<cfargument name="raw" type="boolean" required="no" default="false">
		<cfset var data = array_merge(static_("ColdIgniter\Cookie\Cookie").defaults)>
		<cfset var parts = CreateObject("java", "java.lang.String").init(arguments.cookie_).split(";[\s]*")>
		<cfset var first = explode("=", parts[1], 2)>
		<cfset var decoder = CreateObject("java", "java.net.URLDecoder")>
		<cfset var name = "">
		<cfset var value = "">
		<cfset var pair = "">
		<cfset var i = 0>

		<cfset data["raw"] = arguments.raw>

		<cfif arguments.raw>
			<cfset name = first[1]>
		<cfelse>
			<cfset name = decoder.decode(Replace(first[1], "+", "%2B", "all"), "UTF-8")>
		</cfif>

		<cfif ArrayLen(first) GT 1>
			<cfif arguments.raw>
				<cfset value = first[2]>
			<cfelse>
				<cfset value = decoder.decode(Replace(first[2], "+", "%2B", "all"), "UTF-8")>
			</cfif>
		</cfif>

		<cfloop from="2" to="#ArrayLen(parts)#" index="i">
			<cfif Find("=", parts[i]) GT 0>
				<cfset pair = explode("=", parts[i])>
				<cfset data[LCase(pair[1])] = pair[2]>
			<cfelse>
				<cfset data[LCase(parts[i])] = true>
			</cfif>
		</cfloop>

		<cfreturn new_("ColdIgniter\Cookie\Cookie", name, value, data)>
	</cffunction>

	<!---
	 * Construct a new Cookie instance.
	 *
	 * @param name    The cookie's name
	 * @param value   The cookie's value
	 * @param options The cookie's options: a map with the keys prefix,
	 *                max-age, expires, path, domain, secure, httponly,
	 *                samesite and raw
	 *
	 * @throws CookieException
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="value" type="string" required="no" default="">
		<cfargument name="options" type="any" required="no" default="">
		<cfset var defaults = static_("ColdIgniter\Cookie\Cookie").defaults>
		<cfset var opts = array_merge(defaults)>
		<cfset var key = "">
		<cfset var prefix = "">
		<cfset var path = "">
		<cfset var domain = "">
		<cfset var samesite = "">
		<cfset var raw = false>
		<cfset var secure = false>
		<cfset var httponly = true>

		<!--- the options of the caller win over the defaults --->
		<cfif IsStruct(arguments.options)>
			<cfloop collection="#arguments.options#" item="key">
				<cfset opts[key] = arguments.options[key]>
			</cfloop>
		</cfif>

		<cfset opts["expires"] = convertExpiresTimestamp(opts["expires"])>

		<!--- If both `Expires` and `Max-Age` are set, `Max-Age` has precedence. --->
		<cfif StructKeyExists(opts, "max-age") AND IsNumeric(opts["max-age"])>
			<cfset opts["expires"] = time() + Int(opts["max-age"])>
			<cfset StructDelete(opts, "max-age")>
		</cfif>

		<!--- to preserve backward compatibility with array-based cookies in previous CI versions --->
		<cfif Len(opts["prefix"]) EQ 0>
			<cfset prefix = defaults["prefix"]>
		<cfelse>
			<cfset prefix = opts["prefix"]>
		</cfif>

		<cfif Len(opts["path"]) EQ 0 OR Compare(opts["path"], "0") EQ 0>
			<cfset path = defaults["path"]>
		<cfelse>
			<cfset path = opts["path"]>
		</cfif>

		<cfif Len(opts["domain"]) EQ 0>
			<cfset domain = defaults["domain"]>
		<cfelse>
			<cfset domain = opts["domain"]>
		</cfif>

		<!--- empty string SameSite should use the default for browsers --->
		<cfif Len(opts["samesite"]) EQ 0>
			<cfset samesite = defaults["samesite"]>
		<cfelse>
			<cfset samesite = opts["samesite"]>
		</cfif>

		<cfset raw = opts["raw"]>
		<cfset secure = opts["secure"]>
		<cfset httponly = opts["httponly"]>

		<cfset validateName(arguments.name, raw)>
		<cfset validateValue(arguments.value, raw)>
		<cfset validatePath(path)>
		<cfset validateDomain(domain)>
		<cfset validatePrefix(prefix, secure, path, domain)>
		<cfset validateSameSite(samesite, secure)>

		<cfset this.prefix = prefix>
		<cfset this.name = arguments.name>
		<cfset this.value = arguments.value>
		<cfset this.expires = convertExpiresTimestamp(opts["expires"])>
		<cfset this.path = path>
		<cfset this.domain = domain>
		<cfset this.secure = secure>
		<cfset this.httponly = httponly>
		<cfset this.samesite = ucfirst(LCase(samesite))>
		<cfset this.raw = raw>

		<cfreturn this>
	</cffunction>

	<!--- ===================================================================== --->
	<!--- GETTERS --->
	<!--- ===================================================================== --->

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="getId" access="public" returntype="string" output="no">
		<cfset var parts = ArrayNew(1)>

		<cfset ArrayAppend(parts, getPrefixedName())>
		<cfset ArrayAppend(parts, getPath())>
		<cfset ArrayAppend(parts, getDomain())>

		<cfreturn implode(";", parts)>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="getPrefix" access="public" returntype="string" output="no">
		<cfreturn this.prefix>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="getName" access="public" returntype="string" output="no">
		<cfreturn this.name>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="getPrefixedName" access="public" returntype="string" output="no">
		<cfset var name = getPrefix()>
		<cfset var body = getName()>
		<cfset var i = 0>
		<cfset var char = "">

		<cfif isRaw()>
			<cfset name = name & body>
		<cfelse>
			<cfloop from="1" to="#Len(this.reservedCharsList)#" index="i">
				<cfset char = Mid(this.reservedCharsList, i, 1)>
				<cfset body = Replace(body, char, rawurlencode(char), "all")>
			</cfloop>

			<cfset name = name & body>
		</cfif>

		<cfreturn name>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="getValue" access="public" returntype="string" output="no">
		<cfreturn this.value>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="getExpiresTimestamp" access="public" returntype="numeric" output="no">
		<cfreturn this.expires>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="getExpiresString" access="public" returntype="string" output="no">
		<cfreturn gmdate(this.EXPIRES_FORMAT, this.expires)>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="isExpired" access="public" returntype="boolean" output="no">
		<cfreturn this.expires EQ 0 OR this.expires LT time()>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="getMaxAge" access="public" returntype="numeric" output="no">
		<cfset var maxAge = this.expires - time()>

		<cfif maxAge LT 0>
			<cfreturn 0>
		</cfif>

		<cfreturn maxAge>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="getPath" access="public" returntype="string" output="no">
		<cfreturn this.path>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="getDomain" access="public" returntype="string" output="no">
		<cfreturn this.domain>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="isSecure" access="public" returntype="boolean" output="no">
		<cfreturn this.secure>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="isHTTPOnly" access="public" returntype="boolean" output="no">
		<cfreturn this.httponly>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="getSameSite" access="public" returntype="string" output="no">
		<cfreturn this.samesite>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="isRaw" access="public" returntype="boolean" output="no">
		<cfreturn this.raw>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="getOptions" access="public" returntype="any" output="no">
		<cfset var samesite = this.samesite>

		<cfif Len(samesite) EQ 0>
			<cfset samesite = ucfirst(this.SAMESITE_LAX)>
		</cfif>

		<!--- This is the order of options of the cookie function. DO NOT CHANGE. --->
		<cfreturn array_("expires", this.expires, "path", this.path, "domain", this.domain, "secure", this.secure, "httponly", this.httponly, "samesite", samesite)>
	</cffunction>

	<!--- ===================================================================== --->
	<!--- CLONING --->
	<!--- ===================================================================== --->

	<!---
	 * Makes a copy of this cookie, that the with* methods then change.
	 *
	 * Difference: the original uses the clone operator. A component cannot
	 * be copied here (Duplicate() is never used), so a new object is made
	 * without calling __construct() and the properties are copied, which
	 * keeps an empty prefix empty.
	--->
	<cffunction name="clone_" access="private" returntype="any" output="no">
		<cfset var cookie_ = request.ColdIgniter.autoloader.instantiate(this.__class)>

		<cfset cookie_.prefix = this.prefix>
		<cfset cookie_.name = this.name>
		<cfset cookie_.value = this.value>
		<cfset cookie_.expires = this.expires>
		<cfset cookie_.path = this.path>
		<cfset cookie_.domain = this.domain>
		<cfset cookie_.secure = this.secure>
		<cfset cookie_.httponly = this.httponly>
		<cfset cookie_.samesite = this.samesite>
		<cfset cookie_.raw = this.raw>

		<cfreturn cookie_>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="withPrefix" access="public" returntype="any" output="no">
		<cfargument name="prefix" type="string" required="no" default="">
		<cfset var cookie_ = "">

		<cfset validatePrefix(arguments.prefix, this.secure, this.path, this.domain)>

		<cfset cookie_ = clone_()>
		<cfset cookie_.prefix = arguments.prefix>

		<cfreturn cookie_>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="withName" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfset var cookie_ = "">

		<cfset validateName(arguments.name, this.raw)>

		<cfset cookie_ = clone_()>
		<cfset cookie_.name = arguments.name>

		<cfreturn cookie_>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="withValue" access="public" returntype="any" output="no">
		<cfargument name="value" type="string" required="yes">
		<cfset var cookie_ = "">

		<cfset validateValue(arguments.value, this.raw)>

		<cfset cookie_ = clone_()>
		<cfset cookie_.value = arguments.value>

		<cfreturn cookie_>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="withExpires" access="public" returntype="any" output="no">
		<cfargument name="expires" type="any" required="yes">
		<cfset var cookie_ = clone_()>

		<cfset cookie_.expires = convertExpiresTimestamp(arguments.expires)>

		<cfreturn cookie_>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="withExpired" access="public" returntype="any" output="no">
		<cfset var cookie_ = clone_()>

		<cfset cookie_.expires = 0>

		<cfreturn cookie_>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="withPath" access="public" returntype="any" output="no">
		<cfargument name="path" type="string" required="no" default="">
		<cfset var defaults = static_("ColdIgniter\Cookie\Cookie").defaults>
		<cfset var path_ = arguments.path>
		<cfset var cookie_ = "">

		<cfif Len(path_) EQ 0 OR Compare(path_, "0") EQ 0>
			<cfset path_ = defaults["path"]>
		</cfif>

		<cfset validatePath(path_)>
		<cfset validatePrefix(this.prefix, this.secure, path_, this.domain)>

		<cfset cookie_ = clone_()>
		<cfset cookie_.path = path_>

		<cfreturn cookie_>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="withDomain" access="public" returntype="any" output="no">
		<cfargument name="domain" type="string" required="no" default="">
		<cfset var defaults = static_("ColdIgniter\Cookie\Cookie").defaults>
		<cfset var domain_ = arguments.domain>
		<cfset var cookie_ = "">

		<cfif Len(domain_) EQ 0>
			<cfset domain_ = defaults["domain"]>
		</cfif>

		<cfset validateDomain(domain_)>
		<cfset validatePrefix(this.prefix, this.secure, this.path, domain_)>

		<cfset cookie_ = clone_()>
		<cfset cookie_.domain = domain_>

		<cfreturn cookie_>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="withSecure" access="public" returntype="any" output="no">
		<cfargument name="secure" type="boolean" required="no" default="true">
		<cfset var cookie_ = "">

		<cfset validatePrefix(this.prefix, arguments.secure, this.path, this.domain)>
		<cfset validateSameSite(this.samesite, arguments.secure)>

		<cfset cookie_ = clone_()>
		<cfset cookie_.secure = arguments.secure>

		<cfreturn cookie_>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="withHTTPOnly" access="public" returntype="any" output="no">
		<cfargument name="httponly" type="boolean" required="no" default="true">
		<cfset var cookie_ = clone_()>

		<cfset cookie_.httponly = arguments.httponly>

		<cfreturn cookie_>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="withSameSite" access="public" returntype="any" output="no">
		<cfargument name="samesite" type="string" required="yes">
		<cfset var cookie_ = "">

		<cfset validateSameSite(arguments.samesite, this.secure)>

		<cfset cookie_ = clone_()>
		<cfset cookie_.samesite = ucfirst(LCase(arguments.samesite))>

		<cfreturn cookie_>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="withRaw" access="public" returntype="any" output="no">
		<cfargument name="raw" type="boolean" required="no" default="true">
		<cfset var cookie_ = "">

		<cfset validateName(this.name, arguments.raw)>
		<cfset validateValue(this.value, arguments.raw)>

		<cfset cookie_ = clone_()>
		<cfset cookie_.raw = arguments.raw>

		<cfreturn cookie_>
	</cffunction>

	<!--- ===================================================================== --->
	<!--- ARRAY ACCESS FOR BC --->
	<!--- ===================================================================== --->

	<!---
	 * Whether an offset exists.
	 *
	 * @param offset string
	--->
	<cffunction name="offsetExists" access="public" returntype="boolean" output="no">
		<cfargument name="offset" type="string" required="yes">

		<cfif Compare(arguments.offset, "expire") EQ 0>
			<cfreturn true>
		</cfif>

		<cfreturn ListFind("prefix,name,value,expires,path,domain,secure,httponly,samesite,raw", arguments.offset) GT 0>
	</cffunction>

	<!---
	 * Offset to retrieve.
	 *
	 * @param offset string
	 *
	 * @throws InvalidArgumentException
	--->
	<cffunction name="offsetGet" access="public" returntype="any" output="no">
		<cfargument name="offset" type="string" required="yes">

		<cfif NOT offsetExists(arguments.offset)>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Undefined offset ""#arguments.offset#"".">
		</cfif>

		<cfif Compare(arguments.offset, "expire") EQ 0>
			<cfreturn this.expires>
		</cfif>

		<cfreturn this[arguments.offset]>
	</cffunction>

	<!---
	 * Offset to set.
	 *
	 * @param offset string|null
	 * @param value  bool|int|string
	 *
	 * @throws LogicException
	--->
	<cffunction name="offsetSet" access="public" returntype="void" output="no">
		<cfargument name="offset" type="string" required="yes">
		<cfargument name="value" type="any" required="yes">

		<cfthrow type="ColdIgniter.Exceptions.LogicException" message="Cannot set values of properties of #this.__class# as it is immutable.">
	</cffunction>

	<!---
	 * Offset to unset.
	 *
	 * @param offset string
	 *
	 * @throws LogicException
	--->
	<cffunction name="offsetUnset" access="public" returntype="void" output="no">
		<cfargument name="offset" type="string" required="yes">

		<cfthrow type="ColdIgniter.Exceptions.LogicException" message="Cannot unset values of properties of #this.__class# as it is immutable.">
	</cffunction>

	<!--- ===================================================================== --->
	<!--- CONVERTERS --->
	<!--- ===================================================================== --->

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="toHeaderString" access="public" returntype="string" output="no">
		<cfreturn __toString()>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="__toString" access="public" returntype="string" output="no">
		<cfset var cookieHeader = ArrayNew(1)>
		<cfset var value = "">
		<cfset var samesite = getSameSite()>

		<cfif getValue() EQ "">
			<cfset ArrayAppend(cookieHeader, getPrefixedName() & "=deleted")>
			<cfset ArrayAppend(cookieHeader, "Expires=" & gmdate(this.EXPIRES_FORMAT, 0))>
			<cfset ArrayAppend(cookieHeader, "Max-Age=0")>
		<cfelse>
			<cfif isRaw()>
				<cfset value = getValue()>
			<cfelse>
				<cfset value = rawurlencode(getValue())>
			</cfif>

			<cfset ArrayAppend(cookieHeader, getPrefixedName() & "=" & value)>

			<cfif getExpiresTimestamp() NEQ 0>
				<cfset ArrayAppend(cookieHeader, "Expires=" & getExpiresString())>
				<cfset ArrayAppend(cookieHeader, "Max-Age=" & getMaxAge())>
			</cfif>
		</cfif>

		<cfif getPath() NEQ "">
			<cfset ArrayAppend(cookieHeader, "Path=" & getPath())>
		</cfif>

		<cfif getDomain() NEQ "">
			<cfset ArrayAppend(cookieHeader, "Domain=" & getDomain())>
		</cfif>

		<cfif isSecure()>
			<cfset ArrayAppend(cookieHeader, "Secure")>
		</cfif>

		<cfif isHTTPOnly()>
			<cfset ArrayAppend(cookieHeader, "HttpOnly")>
		</cfif>

		<cfif samesite EQ "">
			<!--- modern browsers warn in console logs that an empty SameSite attribute will be given the `Lax` value --->
			<cfset samesite = this.SAMESITE_LAX>
		</cfif>

		<cfset ArrayAppend(cookieHeader, "SameSite=" & ucfirst(LCase(samesite)))>

		<cfreturn implode("; ", cookieHeader)>
	</cffunction>

	<!---
	 * {@inheritDoc}
	--->
	<cffunction name="toArray" access="public" returntype="any" output="no">
		<cfreturn array_merge(array_("name", this.name, "value", this.value, "prefix", this.prefix, "raw", this.raw), getOptions())>
	</cffunction>

	<!---
	 * Converts expires time to Unix format.
	 *
	 * Not ported yet: a date object (DateTimeInterface) and a date text
	 * (strtotime). A text that is not a number is refused with
	 * forInvalidExpiresValue.
	 *
	 * @param expires A Unix timestamp, or a string of digits
	--->
	<cffunction name="convertExpiresTimestamp" access="private" returntype="numeric" output="no">
		<cfargument name="expires" type="any" required="no" default="0">

		<cfif NOT IsSimpleValue(arguments.expires)>
			<cfset static_("ColdIgniter\Cookie\Exceptions\CookieException").forInvalidExpiresTime("array")>
		</cfif>

		<cfif NOT IsNumeric(arguments.expires)>
			<cfset static_("ColdIgniter\Cookie\Exceptions\CookieException").forInvalidExpiresValue()>
		</cfif>

		<cfif arguments.expires GT 0>
			<cfreturn Int(arguments.expires)>
		</cfif>

		<cfreturn 0>
	</cffunction>

	<!--- ===================================================================== --->
	<!--- VALIDATION --->
	<!--- ===================================================================== --->

	<!---
	 * Validates the cookie name per RFC 2616.
	 * If `raw` is true, names should not contain invalid characters.
	 *
	 * @throws CookieException
	--->
	<cffunction name="validateName" access="private" returntype="void" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="raw" type="boolean" required="yes">

		<cfif arguments.raw AND strpbrk(arguments.name, this.reservedCharsList) NEQ "">
			<cfset static_("ColdIgniter\Cookie\Exceptions\CookieException").forInvalidCookieName(arguments.name)>
		</cfif>

		<cfif arguments.name EQ "">
			<cfset static_("ColdIgniter\Cookie\Exceptions\CookieException").forEmptyCookieName()>
		</cfif>
	</cffunction>

	<!---
	 * Validates the cookie value.
	 * If `raw` is true, values should not contain invalid characters.
	 *
	 * @throws CookieException
	--->
	<cffunction name="validateValue" access="private" returntype="void" output="no">
		<cfargument name="value" type="string" required="yes">
		<cfargument name="raw" type="boolean" required="yes">

		<cfif arguments.raw AND strpbrk(arguments.value, this.reservedValueCharsList) NEQ "">
			<cfset static_("ColdIgniter\Cookie\Exceptions\CookieException").forInvalidCookieValue()>
		</cfif>
	</cffunction>

	<!---
	 * Validates the cookie path.
	 *
	 * @throws CookieException
	--->
	<cffunction name="validatePath" access="private" returntype="void" output="no">
		<cfargument name="path" type="string" required="yes">

		<cfif strpbrk(arguments.path, this.reservedValueCharsList) NEQ "">
			<cfset static_("ColdIgniter\Cookie\Exceptions\CookieException").forInvalidCookiePath()>
		</cfif>
	</cffunction>

	<!---
	 * Validates the cookie domain.
	 *
	 * @throws CookieException
	--->
	<cffunction name="validateDomain" access="private" returntype="void" output="no">
		<cfargument name="domain" type="string" required="yes">

		<cfif arguments.domain NEQ "" AND strpbrk(arguments.domain, this.reservedValueCharsList) NEQ "">
			<cfset static_("ColdIgniter\Cookie\Exceptions\CookieException").forInvalidCookieDomain()>
		</cfif>
	</cffunction>

	<!---
	 * Validates the special prefixes if some attribute requirements are met,
	 * and ensures the prefix contains no prohibited characters.
	 *
	 * @throws CookieException
	--->
	<cffunction name="validatePrefix" access="private" returntype="void" output="no">
		<cfargument name="prefix" type="string" required="yes">
		<cfargument name="secure" type="boolean" required="yes">
		<cfargument name="path" type="string" required="yes">
		<cfargument name="domain" type="string" required="yes">

		<cfif strpbrk(arguments.prefix, this.reservedPrefixCharsList) NEQ "">
			<cfset static_("ColdIgniter\Cookie\Exceptions\CookieException").forInvalidCookieName(arguments.prefix)>
		</cfif>

		<cfif Compare(Left(arguments.prefix, 9), "__Secure-") EQ 0 AND NOT arguments.secure>
			<cfset static_("ColdIgniter\Cookie\Exceptions\CookieException").forInvalidSecurePrefix()>
		</cfif>

		<cfif Compare(Left(arguments.prefix, 7), "__Host-") EQ 0 AND (NOT arguments.secure OR arguments.domain NEQ "" OR Compare(arguments.path, "/") NEQ 0)>
			<cfset static_("ColdIgniter\Cookie\Exceptions\CookieException").forInvalidHostPrefix()>
		</cfif>
	</cffunction>

	<!---
	 * Validates the `SameSite` to be within the allowed types.
	 *
	 * @throws CookieException
	 *
	 * @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite
	--->
	<cffunction name="validateSameSite" access="private" returntype="void" output="no">
		<cfargument name="samesite" type="string" required="yes">
		<cfargument name="secure" type="boolean" required="yes">
		<cfset var defaults = static_("ColdIgniter\Cookie\Cookie").defaults>
		<cfset var samesite_ = arguments.samesite>

		<cfif samesite_ EQ "">
			<cfset samesite_ = defaults["samesite"]>
		</cfif>

		<cfif samesite_ EQ "">
			<cfset samesite_ = this.SAMESITE_LAX>
		</cfif>

		<cfif NOT in_array(ucfirst(LCase(samesite_)), this.ALLOWED_SAMESITE_VALUES)>
			<cfset static_("ColdIgniter\Cookie\Exceptions\CookieException").forInvalidSameSite(samesite_)>
		</cfif>

		<cfif Compare(ucfirst(LCase(samesite_)), this.SAMESITE_NONE) EQ 0 AND NOT arguments.secure>
			<cfset static_("ColdIgniter\Cookie\Exceptions\CookieException").forInvalidSameSiteNone()>
		</cfif>
	</cffunction>

</cfcomponent>
