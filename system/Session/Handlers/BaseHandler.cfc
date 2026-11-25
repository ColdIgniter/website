<!---
 * Base class for session handling.
 *
 * Difference: there is no SessionHandlerInterface (the engine of the
 * original has it built in) and so no abstract methods; a handler defines
 * open(), close(), read(), write(), destroy() and gc(), which the
 * session_* functions of system/Polyfills call. LoggerAwareTrait is not
 * ported, so setLogger() is written here, and the logger is this.logger.
 *
 * Difference: destroyCookie() does not call setcookie(); it puts the
 * deleting cookie on the response (Response.deleteCookie), which sends it
 * with the other cookies.
--->
<cfcomponent output="no" hint="Base class for session handling">

	<!---
	 * LoggerAwareTrait: the logger
	--->
	<cfset this.logger = "">

	<!---
	 * The Data fingerprint.
	 *
	 * @var string
	--->
	<cfset this.fingerprint = "">

	<!---
	 * Lock placeholder.
	 *
	 * @var bool|string
	--->
	<cfset this.lock = false>

	<!---
	 * Cookie prefix.
	 *
	 * The Config\Cookie::$prefix setting is completely ignored.
	 * See https://codeigniter.com/user_guide/libraries/sessions.html#session-preferences
	 *
	 * @var string
	--->
	<cfset this.cookiePrefix = "">

	<!---
	 * Cookie domain.
	 *
	 * @var string
	--->
	<cfset this.cookieDomain = "">

	<!---
	 * Cookie path.
	 *
	 * @var string
	--->
	<cfset this.cookiePath = "/">

	<!---
	 * Cookie secure?
	 *
	 * @var bool
	--->
	<cfset this.cookieSecure = false>

	<!---
	 * Cookie name to use.
	 *
	 * @var string
	--->
	<cfset this.cookieName = "">

	<!---
	 * Match IP addresses for cookies?
	 *
	 * @var bool
	--->
	<cfset this.matchIP = false>

	<!---
	 * Current session ID.
	 *
	 * @var string|null
	--->
	<cfset this.sessionID = "">

	<!---
	 * The 'save path' for the session
	 * varies between.
	 *
	 * @var string
	--->
	<cfset this.savePath = "">

	<!---
	 * User's IP address.
	 *
	 * @var string
	--->
	<cfset this.ipAddress = "">

	<!---
	 * @param config    The session configuration (Config\Session)
	 * @param ipAddress The IP address of the client
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfargument name="ipAddress" type="string" required="yes">

		<cfset configure_(arguments.config, arguments.ipAddress)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Not in the original: the work of the constructor. The database
	 * handlers are mixed in, where super does not reach this class, so
	 * DatabaseHandler calls this in place of super.__construct().
	--->
	<cffunction name="configure_" access="private" returntype="void" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfargument name="ipAddress" type="string" required="yes">
		<cfset var cookie_ = variables.config("Config\Cookie")>

		<!--- Store Session configurations --->
		<cfset this.cookieName = arguments.config.cookieName>
		<cfset this.matchIP = arguments.config.matchIP>
		<cfset this.savePath = arguments.config.savePath>

		<!--- Session cookies have no prefix. --->
		<cfset this.cookieDomain = cookie_.domain>
		<cfset this.cookiePath = cookie_.path>
		<cfset this.cookieSecure = cookie_.secure>

		<cfset this.ipAddress = arguments.ipAddress>
	</cffunction>

	<!---
	 * Sets a logger instance on the object.
	--->
	<cffunction name="setLogger" access="public" returntype="void" output="no">
		<cfargument name="logger" type="any" required="yes">

		<cfset this.logger = arguments.logger>
	</cffunction>

	<!---
	 * Internal method to force removal of a cookie by the client
	 * when session_destroy() is called.
	--->
	<cffunction name="destroyCookie" access="private" returntype="boolean" output="no">
		<cfset var cookie_ = "">

		<!--- Difference: the cookie goes to the response, as no engine function sets one; the prefix is forced empty, as the prefix of Config\Cookie is ignored here; the line also carries the SameSite of the Cookie defaults, which the original does not send --->
		<cfset cookie_ = new_("ColdIgniter\Cookie\Cookie", this.cookieName, "", array_("prefix", "", "path", this.cookiePath, "domain", this.cookieDomain, "secure", this.cookieSecure, "httponly", true)).withExpired()>

		<cfset service("response").setCookie(cookie_)>

		<cfreturn true>
	</cffunction>

	<!---
	 * A dummy method allowing drivers with no locking functionality
	 * (databases other than PostgreSQL and MySQL) to act as if they
	 * do acquire a lock.
	--->
	<cffunction name="lockSession" access="private" returntype="boolean" output="no">
		<cfargument name="sessionID" type="string" required="yes">

		<cfset this.lock = true>

		<cfreturn true>
	</cffunction>

	<!---
	 * Releases the lock, if any.
	--->
	<cffunction name="releaseLock" access="private" returntype="boolean" output="no">

		<cfset this.lock = false>

		<cfreturn true>
	</cffunction>

	<!---
	 * Drivers other than the 'files' one don't (need to) use the
	 * session.save_path INI setting, but that leads to confusing
	 * error messages emitted by the engine when open() or write() fail,
	 * as the message contains session.save_path ...
	 *
	 * To work around the problem, the drivers will call this method
	 * so that the INI is set just in time for the error message to
	 * be properly generated.
	--->
	<cffunction name="fail" access="private" returntype="boolean" output="no">

		<cfset ini_set("session.save_path", this.savePath)>

		<cfreturn false>
	</cffunction>

</cfcomponent>
