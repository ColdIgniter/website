<!---
 * ColdIgniter Cookie Helpers
 *
 * Not ported yet: the input filters, so get_cookie() has no xssClean that
 * does anything (the argument is kept and ignored), and the Cookie object
 * and map forms of the options (expire as a date object).
 *
 * A function here has no guard against a second definition (the original
 * checks function_exists): helper() keeps the first definition of a name.
 *
 * Where the original takes null for secure, httpOnly, sameSite or value,
 * the argument is left out or is an empty string, because null and an
 * empty string cannot be told apart.
--->

<!---
 * Set cookie
 *
 * Accepts seven parameters, or you can submit a map (see array_()) in the
 * first parameter containing all the values:
 * name, value, prefix, expire, path, domain, secure, httponly, samesite.
 *
 * @param name     Cookie name / map containing binds / Cookie object
 * @param value    The value of the cookie
 * @param expire   The number of seconds until expiration
 * @param domain   For site-wide cookie. Usually: .yourdomain.com
 * @param path     The cookie path
 * @param prefix   The cookie prefix ('': the default prefix)
 * @param secure   True makes the cookie secure; an empty string takes the config
 * @param httpOnly True makes the cookie accessible via http(s) only (no javascript); an empty string takes the config
 * @param sameSite The cookie SameSite value; an empty string takes the config
 *
 * @see Response.setCookie()
--->
<cffunction name="set_cookie" returntype="void" output="no" hint="Set cookie">
	<cfargument name="name" type="any" required="yes">
	<cfargument name="value" type="string" required="no" default="">
	<cfargument name="expire" type="any" required="no" default="0">
	<cfargument name="domain" type="string" required="no" default="">
	<cfargument name="path" type="string" required="no" default="/">
	<cfargument name="prefix" type="string" required="no" default="">
	<cfargument name="secure" type="any" required="no" default="">
	<cfargument name="httpOnly" type="any" required="no" default="">
	<cfargument name="sameSite" type="any" required="no" default="">
	<cfset var response = service("response")>

	<cfset response.setCookie(arguments.name, arguments.value, arguments.expire, arguments.domain, arguments.path, arguments.prefix, arguments.secure, arguments.httpOnly, arguments.sameSite)>
</cffunction>

<!---
 * Fetch an item from the cookie array
 *
 * @param index
 * @param xssClean Not ported yet: it is ignored
 * @param prefix   Cookie name prefix. '': the prefix in Config\Cookie
 *
 * @return The value, or an empty string (null)
 *
 * @see IncomingRequest.getCookie()
--->
<cffunction name="get_cookie" returntype="any" output="no" hint="Fetch an item from the cookie array">
	<cfargument name="index" type="string" required="yes">
	<cfargument name="xssClean" type="boolean" required="no" default="false">
	<cfargument name="prefix" type="string" required="no" default="">
	<cfset var prefix_ = arguments.prefix>

	<cfif prefix_ EQ "">
		<cfset prefix_ = config("Config\Cookie").prefix>
	</cfif>

	<cfreturn service("request").getCookie(prefix_ & arguments.index)>
</cffunction>

<!---
 * Delete a cookie
 *
 * @param name
 * @param domain the cookie domain. Usually: .yourdomain.com
 * @param path   the cookie path
 * @param prefix the cookie prefix
 *
 * @see Response.deleteCookie()
--->
<cffunction name="delete_cookie" returntype="void" output="no" hint="Delete a cookie">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="domain" type="string" required="no" default="">
	<cfargument name="path" type="string" required="no" default="/">
	<cfargument name="prefix" type="string" required="no" default="">

	<cfset service("response").deleteCookie(arguments.name, arguments.domain, arguments.path, arguments.prefix)>
</cffunction>

<!---
 * Checks if a cookie exists by name.
 *
 * @param value An empty string stands for null: any value
--->
<cffunction name="has_cookie" returntype="boolean" output="no" hint="Checks if a cookie exists by name">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="value" type="any" required="no" default="">
	<cfargument name="prefix" type="string" required="no" default="">

	<cfreturn service("response").hasCookie(arguments.name, arguments.value, arguments.prefix)>
</cffunction>
