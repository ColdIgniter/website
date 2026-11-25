<!---
 * Implementation of ColdIgniter session container.
 *
 * Session configuration is done through session variables and cookie related
 * variables in `Config\Session`.
 *
 * Difference: the session data of the original is the superglobal
 * $_SESSION. Here it is the map session_state().data (see the session_*
 * functions in system/Polyfills), a java.util.LinkedHashMap, read and
 * written below through its Java methods so the case of a key is kept. A
 * null is an empty string, so a key whose value is empty counts as not set
 * in has() and in the flash and temp data methods, where the original
 * checks isset().
 *
 * Difference: the data is stored as a WDDX packet, which turns a number
 * into a string. So the marks in __ci_vars are told apart by IsNumeric(): a
 * number is the expiry time of temp data, "new" and "old" mark flash data
 * (is_int() in the original), and a number that is stored in a map given
 * to markAsTempdata() is read as a time to live, even when it was a string.
 *
 * Difference: the packet also drops the order of the keys and treats keys
 * that differ only in case as one (the last value wins, under the case of
 * the first), so after a request the data is read back unordered and
 * without a key that only differs by case from another. The case of a key
 * is kept.
 *
 * Difference: the session is written when the request ends normally (see
 * ColdIgniter.run()); a request that ends in an error does not write it.
 *
 * Difference: there are no magic methods, so __set(), __get() and
 * __isset() are plain methods that have to be called by name.
 *
 * Difference: the engine of the original sends the session cookie, and
 * does it only for a new or regenerated ID. Here setCookie() sends it
 * through the response, and start() calls it for a new ID where the
 * original lets the engine do it. session_set_cookie_params() is not
 * called, because nothing reads it.
 *
 * Not ported yet: LoggerAwareTrait (setLogger() is written here),
 * is_cli(), the ENVIRONMENT "testing" shortcuts of start(), destroy() and
 * close(), the array helper (dot_array_search() in get(), so a key with
 * dots is only found as a whole), and SessionHandlerInterface (there is
 * none; the handler is a component that defines open(), close(), read(),
 * write(), destroy() and gc()).
--->
<cfcomponent output="no" extends="SessionInterface" hint="Implementation of ColdIgniter session container">

	<!---
	 * LoggerAwareTrait: the logger
	--->
	<cfset this.logger = "">

	<!---
	 * Instance of the driver to use.
	 *
	 * @var SessionHandlerInterface
	--->
	<cfset this.driver = "">

	<!---
	 * The session cookie instance.
	 *
	 * @var Cookie
	 *
	 * Named with an underscore, because cookie is also a scope.
	--->
	<cfset this.cookie_ = "">

	<!---
	 * Session ID regex expression.
	 *
	 * @var string
	--->
	<cfset this.sidRegexp = "">

	<cfset this.config = "">

	<!---
	 * Extract configuration settings and save them here.
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="driver" type="any" required="yes">
		<cfargument name="config" type="any" required="yes">
		<cfset var cookieConfig = variables.config("Config\Cookie")>
		<cfset var expires = 0>
		<cfset var options = "">

		<cfset this.driver = arguments.driver>
		<cfset this.config = arguments.config>

		<cfif arguments.config.expiration NEQ 0>
			<cfset expires = time() + arguments.config.expiration>
		</cfif>

		<cfset options = array_("expires", expires, "path", cookieConfig.path, "domain", cookieConfig.domain, "secure", cookieConfig.secure, "httponly", true, "samesite", cookieConfig.samesite, "raw", cookieConfig.raw)>

		<!--- httponly is always true, for security --->
		<cfset this.cookie_ = new_("ColdIgniter\Cookie\Cookie", arguments.config.cookieName, "", options).withPrefix("")> <!--- Cookie prefix should be ignored. --->

		<!--- Not ported yet: helper('array') --->

		<cfreturn this>
	</cffunction>

	<!---
	 * LoggerAwareTrait: sets a logger instance on the object.
	--->
	<cffunction name="setLogger" access="public" returntype="void" output="no">
		<cfargument name="logger" type="any" required="yes">

		<cfset this.logger = arguments.logger>
	</cffunction>

	<!---
	 * Initialize the session container and starts up the session.
	 *
	 * Returns this, or an empty string (null).
	--->
	<cffunction name="start" access="public" returntype="any" output="no">
		<cfset var cookie_ = "">
		<cfset var requestedWith = "">
		<cfset var regenerateTime = this.config.timeToUpdate>
		<cfset var data = session_state().data>
		<cfset var now = time()>

		<!--- Not ported yet: the is_cli() check --->

		<cfif Compare(ini_get("session.auto_start"), "1") EQ 0>
			<cfset this.logger.error("Session: session.auto_start is enabled. Aborting.")>

			<cfreturn "">
		</cfif>

		<cfif Compare(session_status(), "active") EQ 0>
			<cfset this.logger.warning("Session: Sessions is enabled, and one exists. Please don't call start() again.")>

			<cfreturn "">
		</cfif>

		<cfset configure()>
		<cfset setSaveHandler()>

		<!--- Sanitize the cookie, because the engine does not do that for userspace handlers --->
		<cfset cookie_ = service("superglobals").cookie(this.config.cookieName)>

		<cfif NOT is_null(cookie_) AND NOT (IsSimpleValue(cookie_) AND CreateObject("java", "java.lang.String").init(cookie_).matches(this.sidRegexp))>
			<cfset service("superglobals").unsetCookie(this.config.cookieName)>
			<cfset cookie_ = "">
		</cfif>

		<cfset startSession()>

		<!--- Difference: the engine of the original sends the cookie of a new ID; here it is done below --->
		<cfif Compare(cookie_, session_id()) NEQ 0>
			<cfset setCookie()>
		</cfif>

		<!--- Is session ID auto-regeneration configured? (ignoring ajax requests) --->
		<cfset requestedWith = service("superglobals").server("HTTP_X_REQUESTED_WITH")>

		<cfif (is_null(requestedWith) OR Compare(LCase(requestedWith), "xmlhttprequest") NEQ 0) AND regenerateTime GT 0>
			<cfset data = session_state().data>

			<cfif NOT data.containsKey("__ci_last_regenerate")>
				<cfset data.put("__ci_last_regenerate", now & "")>
			<cfelseif data.get("__ci_last_regenerate") LT (now - regenerateTime)>
				<cfset regenerate(this.config.regenerateDestroy)>
			</cfif>

		<!--- Another work-around ... the engine does not seem to send the session cookie unless it is being currently created or regenerated --->
		<cfelseif NOT is_null(cookie_) AND Compare(cookie_, session_id()) EQ 0>
			<cfset setCookie()>
		</cfif>

		<cfset initVars()>

		<cfset this.logger.debug("Session: Class initialized using '" & this.config.driver & "' driver.")>

		<cfreturn this>
	</cffunction>

	<!---
	 * Configuration.
	 *
	 * Handle input binds and configuration defaults.
	--->
	<cffunction name="configure" access="private" returntype="void" output="no">
		<cfset var sameSite = this.cookie_.getSameSite()>

		<cfset ini_set("session.name", this.config.cookieName)>

		<cfif Compare(sameSite, "") EQ 0>
			<cfset sameSite = ucfirst(this.cookie_.SAMESITE_LAX)>
		</cfif>

		<!--- HTTP only; Yes, this is intentional and not configurable for security reasons. --->
		<cfset ini_set("session.cookie_samesite", sameSite)>

		<!--- Not ported yet: session_set_cookie_params() (see the note at the top) --->

		<cfif this.config.expiration GT 0>
			<cfset ini_set("session.gc_maxlifetime", this.config.expiration)>
		</cfif>

		<cfif Compare(this.config.savePath, "") NEQ 0>
			<cfset ini_set("session.save_path", this.config.savePath)>
		</cfif>

		<!--- Security is king --->
		<cfset ini_set("session.use_trans_sid", "0")>
		<cfset ini_set("session.use_strict_mode", "1")>
		<cfset ini_set("session.use_cookies", "1")>
		<cfset ini_set("session.use_only_cookies", "1")>

		<cfset configureSidLength()>
	</cffunction>

	<!---
	 * Configure session ID length. To make life easier, we force the defaults.
	--->
	<cffunction name="configureSidLength" access="private" returntype="void" output="no">

		<cfif Compare(ini_get("session.sid_bits_per_character"), "4") NEQ 0>
			<cfset ini_set("session.sid_bits_per_character", "4")>
		</cfif>

		<cfif Compare(ini_get("session.sid_length"), "32") NEQ 0>
			<cfset ini_set("session.sid_length", "32")>
		</cfif>

		<cfset this.sidRegexp = "[0-9a-f]{32}">
	</cffunction>

	<!---
	 * Handle temporary variables.
	 *
	 * Clears old "flash" data, marks the new one for deletion and handles
	 * "temp" data deletion.
	--->
	<cffunction name="initVars" access="private" returntype="void" output="no">
		<cfset var data = session_state().data>
		<cfset var vars = "">
		<cfset var keys = "">
		<cfset var key = "">
		<cfset var value = "">
		<cfset var currentTime = time()>
		<cfset var i = 0>

		<cfif NOT data.containsKey("__ci_vars")>
			<cfreturn>
		</cfif>

		<cfset vars = data.get("__ci_vars")>
		<cfset keys = array_keys(vars)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset key = keys[i]>
			<cfset value = vars.get(key)>

			<cfif Compare(value, "new") EQ 0>
				<cfset vars.put(key, "old")>
			<!--- DO NOT move this above the 'new' check! --->
			<cfelseif Compare(value, "old") EQ 0 OR (IsNumeric(value) AND value LT currentTime)>
				<cfset data.remove(key)>
				<cfset vars.remove(key)>
			</cfif>
		</cfloop>

		<cfif vars.isEmpty()>
			<cfset data.remove("__ci_vars")>
		</cfif>
	</cffunction>

	<!---
	 * Regenerates the session ID.
	 *
	 * @param destroy Should old session data be destroyed?
	--->
	<cffunction name="regenerate" access="public" returntype="void" output="no">
		<cfargument name="destroy" type="boolean" required="no" default="false">

		<cfset session_state().data.put("__ci_last_regenerate", time() & "")>

		<cfset session_regenerate_id(arguments.destroy)>

		<cfset removeOldSessionCookie()>

		<!--- Difference: the engine of the original sends the cookie of the new ID --->
		<cfset setCookie()>
	</cffunction>

	<cffunction name="removeOldSessionCookie" access="private" returntype="void" output="no">
		<cfset var response = service("response")>
		<cfset var cookieStoreInResponse = response.getCookieStore()>
		<cfset var newCookieStore = "">
		<cfset var cookies = "">
		<cfset var i = 0>

		<cfif NOT cookieStoreInResponse.has(this.config.cookieName)>
			<cfreturn>
		</cfif>

		<!--- CookieStore is immutable. --->
		<cfset newCookieStore = cookieStoreInResponse.remove(this.config.cookieName)>

		<!--- But clear() method clears cookies in the object (not immutable). --->
		<cfset cookieStoreInResponse.clear()>

		<cfset cookies = newCookieStore.getIterator()>

		<cfloop from="1" to="#ArrayLen(cookies)#" index="i">
			<cfset response.setCookie(cookies[i])>
		</cfloop>
	</cffunction>

	<!---
	 * Destroys the current session.
	--->
	<cffunction name="destroy" access="public" returntype="void" output="no">

		<!--- Not ported yet: the ENVIRONMENT "testing" check --->

		<cfset session_destroy()>
	</cffunction>

	<!---
	 * Writes session data and close the current session.
	--->
	<cffunction name="close" access="public" returntype="void" output="no">

		<!--- Not ported yet: the ENVIRONMENT "testing" check --->

		<cfset session_write_close()>
	</cffunction>

	<!---
	 * Sets user data into the session.
	 *
	 * If data is a string, then it is interpreted as a session property
	 * key, and value is expected to be non-null.
	 *
	 * If data is a map, it is expected to be a map of key/value pairs
	 * to be set as session properties. A list is a list of keys that
	 * are set to null.
	 *
	 * @param data  Property name or map of properties.
	 * @param value Property value if single key provided.
	--->
	<cffunction name="set" access="public" returntype="void" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="value" type="any" required="no" default="">
		<cfset var sessionData = session_state().data>
		<cfset var keys = "">
		<cfset var i = 0>

		<cfif IsArray(arguments.data)>
			<cfloop from="1" to="#ArrayLen(arguments.data)#" index="i">
				<cfset sessionData.put(JavaCast("string", arguments.data[i]), "")>
			</cfloop>
		<cfelseif IsStruct(arguments.data)>
			<cfset keys = array_keys(arguments.data)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset sessionData.put(JavaCast("string", keys[i]), arguments.data.get(keys[i]))>
			</cfloop>
		<cfelse>
			<cfset sessionData.put(JavaCast("string", arguments.data), arguments.value)>
		</cfif>
	</cffunction>

	<!---
	 * Get user data that has been set in the session.
	 *
	 * If the property exists as "normal", returns it.
	 * Otherwise, returns an array of any temp or flash data values with the
	 * property key.
	 *
	 * @param key Identifier of the session property to retrieve.
	--->
	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="no" default="">
		<cfset var sessionData = session_state().data>
		<cfset var userdata = array_()>
		<cfset var exclude = "">
		<cfset var keys = "">
		<cfset var k = "">
		<cfset var i = 0>

		<cfif sessionData.isEmpty()>
			<cfif is_null(arguments.key)>
				<cfreturn array_()>
			</cfif>

			<cfreturn "">
		</cfif>

		<cfif Compare(arguments.key, "") NEQ 0>
			<cfif sessionData.containsKey(JavaCast("string", arguments.key))>
				<cfreturn sessionData.get(JavaCast("string", arguments.key))>
			</cfif>

			<!--- Not ported yet: dot_array_search() --->
			<cfreturn "">
		</cfif>

		<cfset exclude = ArrayNew(1)>
		<cfset ArrayAppend(exclude, "__ci_vars")>
		<cfset exclude = array_merge(exclude, getFlashKeys(), getTempKeys())>

		<cfset keys = array_keys(sessionData)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset k = keys[i]>

			<cfif NOT in_array(k, exclude, true)>
				<cfset userdata.put(k, sessionData.get(k))>
			</cfif>
		</cfloop>

		<cfreturn userdata>
	</cffunction>

	<!---
	 * Returns whether an index exists in the session array.
	 *
	 * @param key Identifier of the session property we are interested in.
	--->
	<cffunction name="has" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfreturn isset_(session_state().data, arguments.key)>
	</cffunction>

	<!---
	 * Push new value onto session value that is array.
	 *
	 * @param key  Identifier of the session property we are interested in.
	 * @param data value to be pushed to existing session key.
	--->
	<cffunction name="push" access="public" returntype="void" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="data" type="any" required="yes">
		<cfset var value = "">

		<cfif has(arguments.key)>
			<cfset value = get(arguments.key)>

			<cfif is_array(value)>
				<cfset set(arguments.key, array_merge(value, arguments.data))>
			</cfif>
		</cfif>
	</cffunction>

	<!---
	 * Remove one or more session properties.
	 *
	 * If key is a list, it is interpreted as a list of string property
	 * identifiers to remove. Otherwise, it is interpreted as the identifier
	 * of a specific session property to remove.
	 *
	 * @param key Identifier of the session property or properties to remove.
	--->
	<cffunction name="remove" access="public" returntype="void" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfset var keys = arguments.key>
		<cfset var i = 0>

		<cfif NOT IsArray(keys)>
			<cfset keys = ArrayNew(1)>
			<cfset ArrayAppend(keys, arguments.key)>
		</cfif>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset session_state().data.remove(JavaCast("string", keys[i]))>
		</cfloop>
	</cffunction>

	<!---
	 * Magic method to set variables in the session by simply calling
	 *  $session->foo = 'bar';
	 *
	 * Difference: not magic, call it by name.
	--->
	<cffunction name="__set" access="public" returntype="void" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="value" type="any" required="yes">

		<cfset session_state().data.put(JavaCast("string", arguments.key), arguments.value)>
	</cffunction>

	<!---
	 * Magic method to get session variables by simply calling
	 *  $foo = $session->foo;
	 *
	 * Difference: not magic, call it by name.
	--->
	<cffunction name="__get" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">

		<!--- Note: Keep this order the same, just in case somebody wants to use 'session_id' as a session data key, for whatever reason --->
		<cfif isset_(session_state().data, arguments.key)>
			<cfreturn session_state().data.get(JavaCast("string", arguments.key))>
		</cfif>

		<cfif Compare(arguments.key, "session_id") EQ 0>
			<cfreturn session_id()>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * Magic method to check for session variables.
	 *
	 * Different from `has()` in that it will validate 'session_id' as well.
	 * Mostly used by internal engine functions, users should stick to `has()`.
	 *
	 * Difference: not magic, call it by name.
	--->
	<cffunction name="__isset" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfreturn isset_(session_state().data, arguments.key) OR Compare(arguments.key, "session_id") EQ 0>
	</cffunction>

	<!---
	 * Sets data into the session that will only last for a single request.
	 * Perfect for use with single-use status update messages.
	 *
	 * If data is a map, it is interpreted as a map of
	 * key/value pairs for flashdata properties.
	 * Otherwise, it is interpreted as the identifier of a specific
	 * flashdata property, with value containing the property value.
	 *
	 * @param data  Property identifier or map of properties
	 * @param value Property value if data is a scalar
	--->
	<cffunction name="setFlashdata" access="public" returntype="void" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="value" type="any" required="no" default="">

		<cfset set(arguments.data, arguments.value)>

		<cfif IsStruct(arguments.data)>
			<cfset markAsFlashdata(array_keys(arguments.data))>
		<cfelse>
			<cfset markAsFlashdata(arguments.data)>
		</cfif>
	</cffunction>

	<!---
	 * Retrieve one or more items of flash data from the session.
	 *
	 * If the item key is null, return all flashdata.
	 *
	 * @param key Property identifier.
	--->
	<cffunction name="getFlashdata" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="no" default="">
		<cfset var sessionData = session_state().data>
		<cfset var vars = ciVarsRead()>
		<cfset var flashdata = array_()>
		<cfset var keys = "">
		<cfset var k = "">
		<cfset var i = 0>

		<cfif NOT is_null(arguments.key)>
			<cfif NOT isset_(vars, arguments.key) OR IsNumeric(vars.get(JavaCast("string", arguments.key)))>
				<cfreturn "">
			</cfif>

			<cfif sessionData.containsKey(JavaCast("string", arguments.key))>
				<cfreturn sessionData.get(JavaCast("string", arguments.key))>
			</cfif>

			<cfreturn "">
		</cfif>

		<cfset keys = array_keys(vars)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset k = keys[i]>

			<cfif NOT IsNumeric(vars.get(k))>
				<cfif sessionData.containsKey(k)>
					<cfset flashdata.put(k, sessionData.get(k))>
				<cfelse>
					<cfset flashdata.put(k, "")>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn flashdata>
	</cffunction>

	<!---
	 * Keeps a single piece of flash data alive for one more request.
	 *
	 * @param key Property identifier or list of them.
	--->
	<cffunction name="keepFlashdata" access="public" returntype="void" output="no">
		<cfargument name="key" type="any" required="yes">

		<cfset markAsFlashdata(arguments.key)>
	</cffunction>

	<!---
	 * Mark a session property or properties as flashdata. This returns
	 * `false` if any of the properties were not already set.
	 *
	 * @param key Property identifier or list of them.
	--->
	<cffunction name="markAsFlashdata" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfset var keys = arguments.key>
		<cfset var vars = "">
		<cfset var i = 0>

		<cfif NOT IsArray(keys)>
			<cfset keys = ArrayNew(1)>
			<cfset ArrayAppend(keys, arguments.key)>
		</cfif>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfif NOT isset_(session_state().data, keys[i])>
				<cfreturn false>
			</cfif>
		</cfloop>

		<cfset vars = ciVars()>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset vars.put(JavaCast("string", keys[i]), "new")>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<!---
	 * Unmark data in the session as flashdata.
	 *
	 * @param key Property identifier or list of them.
	--->
	<cffunction name="unmarkFlashdata" access="public" returntype="void" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfset var data = session_state().data>
		<cfset var vars = "">
		<cfset var keys = arguments.key>
		<cfset var i = 0>

		<cfif NOT data.containsKey("__ci_vars")>
			<cfreturn>
		</cfif>

		<cfif NOT IsArray(keys)>
			<cfset keys = ArrayNew(1)>
			<cfset ArrayAppend(keys, arguments.key)>
		</cfif>

		<cfset vars = data.get("__ci_vars")>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfif isset_(vars, keys[i])>
				<cfif NOT IsNumeric(vars.get(JavaCast("string", keys[i])))>
					<cfset vars.remove(JavaCast("string", keys[i]))>
				</cfif>
			</cfif>
		</cfloop>

		<cfif vars.isEmpty()>
			<cfset data.remove("__ci_vars")>
		</cfif>
	</cffunction>

	<!---
	 * Retrieve all of the keys for session data marked as flashdata.
	--->
	<cffunction name="getFlashKeys" access="public" returntype="array" output="no">
		<cfset var data = session_state().data>
		<cfset var vars = "">
		<cfset var names = "">
		<cfset var keys = ArrayNew(1)>
		<cfset var i = 0>

		<cfif NOT data.containsKey("__ci_vars")>
			<cfreturn keys>
		</cfif>

		<cfset vars = data.get("__ci_vars")>
		<cfset names = array_keys(vars)>

		<cfloop from="1" to="#ArrayLen(names)#" index="i">
			<cfif NOT IsNumeric(vars.get(names[i]))>
				<cfset ArrayAppend(keys, names[i])>
			</cfif>
		</cfloop>

		<cfreturn keys>
	</cffunction>

	<!---
	 * Sets new data into the session, and marks it as temporary data
	 * with a set lifespan.
	 *
	 * @param data  Session data key or map of items.
	 * @param value Value to store.
	 * @param ttl   Time-to-live in seconds.
	--->
	<cffunction name="setTempdata" access="public" returntype="void" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="value" type="any" required="no" default="">
		<cfargument name="ttl" type="numeric" required="no" default="300">

		<cfset set(arguments.data, arguments.value)>
		<cfset markAsTempdata(arguments.data, arguments.ttl)>
	</cffunction>

	<!---
	 * Returns either a single piece of tempdata, or all temp data currently
	 * in the session.
	 *
	 * @param key Session data key.
	--->
	<cffunction name="getTempdata" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="no" default="">
		<cfset var sessionData = session_state().data>
		<cfset var vars = ciVarsRead()>
		<cfset var tempdata = array_()>
		<cfset var keys = "">
		<cfset var k = "">
		<cfset var i = 0>

		<cfif NOT is_null(arguments.key)>
			<cfif NOT isset_(vars, arguments.key) OR NOT IsNumeric(vars.get(JavaCast("string", arguments.key)))>
				<cfreturn "">
			</cfif>

			<cfif sessionData.containsKey(JavaCast("string", arguments.key))>
				<cfreturn sessionData.get(JavaCast("string", arguments.key))>
			</cfif>

			<cfreturn "">
		</cfif>

		<cfset keys = array_keys(vars)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset k = keys[i]>

			<cfif IsNumeric(vars.get(k))>
				<cfif sessionData.containsKey(k)>
					<cfset tempdata.put(k, sessionData.get(k))>
				<cfelse>
					<cfset tempdata.put(k, "")>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn tempdata>
	</cffunction>

	<!---
	 * Removes a single piece of temporary data from the session.
	 *
	 * @param key Session data key.
	--->
	<cffunction name="removeTempdata" access="public" returntype="void" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfset unmarkTempdata(arguments.key)>
		<cfset session_state().data.remove(JavaCast("string", arguments.key))>
	</cffunction>

	<!---
	 * Mark one of more pieces of data as being temporary, meaning that
	 * it has a set lifespan within the session.
	 *
	 * Returns `false` if any of the properties were not set.
	 *
	 * @param key Map, list of keys or key. A map gives the time to live
	 *            of each key as its value (see the note at the top)
	 * @param ttl Time to live, in seconds
	--->
	<cffunction name="markAsTempdata" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfargument name="ttl" type="numeric" required="no" default="300">
		<cfset var time_ = time()>
		<cfset var sessionData = session_state().data>
		<cfset var keys = "">
		<cfset var names = ArrayNew(1)>
		<cfset var timeToLive = "">
		<cfset var tempdata = array_()>
		<cfset var vars = "">
		<cfset var sessionKey = "">
		<cfset var i = 0>

		<!--- a list, or a single key, is given the same time to live --->
		<cfif IsStruct(arguments.key)>
			<cfset keys = arguments.key>
		<cfelse>
			<cfset keys = array_()>

			<cfif IsArray(arguments.key)>
				<cfloop from="1" to="#ArrayLen(arguments.key)#" index="i">
					<cfset keys.put(JavaCast("string", arguments.key[i]), arguments.ttl)>
				</cfloop>
			<cfelse>
				<cfset keys.put(JavaCast("string", arguments.key), arguments.ttl)>
			</cfif>
		</cfif>

		<cfset names = array_keys(keys)>

		<cfloop from="1" to="#ArrayLen(names)#" index="i">
			<cfset sessionKey = names[i]>

			<cfif NOT sessionData.containsKey(JavaCast("string", sessionKey))>
				<cfreturn false>
			</cfif>

			<cfset timeToLive = keys.get(sessionKey)>

			<cfif IsNumeric(timeToLive)>
				<cfset timeToLive = timeToLive + time_>
			<cfelse>
				<cfset timeToLive = time_ + arguments.ttl>
			</cfif>

			<!--- a string, so the packet does not write it in scientific notation --->
			<cfset tempdata.put(sessionKey, timeToLive & "")>
		</cfloop>

		<cfset vars = ciVars()>
		<cfset names = array_keys(tempdata)>

		<cfloop from="1" to="#ArrayLen(names)#" index="i">
			<cfset vars.put(names[i], tempdata.get(names[i]))>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<!---
	 * Unmarks temporary data in the session, effectively removing its
	 * lifespan and allowing it to live as long as the session does.
	 *
	 * @param key Property identifier or list of them.
	--->
	<cffunction name="unmarkTempdata" access="public" returntype="void" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfset var data = session_state().data>
		<cfset var vars = "">
		<cfset var keys = arguments.key>
		<cfset var i = 0>

		<cfif NOT data.containsKey("__ci_vars")>
			<cfreturn>
		</cfif>

		<cfif NOT IsArray(keys)>
			<cfset keys = ArrayNew(1)>
			<cfset ArrayAppend(keys, arguments.key)>
		</cfif>

		<cfset vars = data.get("__ci_vars")>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfif isset_(vars, keys[i])>
				<cfif IsNumeric(vars.get(JavaCast("string", keys[i])))>
					<cfset vars.remove(JavaCast("string", keys[i]))>
				</cfif>
			</cfif>
		</cfloop>

		<cfif vars.isEmpty()>
			<cfset data.remove("__ci_vars")>
		</cfif>
	</cffunction>

	<!---
	 * Retrieve the keys of all session data that have been marked as temporary data.
	--->
	<cffunction name="getTempKeys" access="public" returntype="array" output="no">
		<cfset var data = session_state().data>
		<cfset var vars = "">
		<cfset var names = "">
		<cfset var keys = ArrayNew(1)>
		<cfset var i = 0>

		<cfif NOT data.containsKey("__ci_vars")>
			<cfreturn keys>
		</cfif>

		<cfset vars = data.get("__ci_vars")>
		<cfset names = array_keys(vars)>

		<cfloop from="1" to="#ArrayLen(names)#" index="i">
			<cfif IsNumeric(vars.get(names[i]))>
				<cfset ArrayAppend(keys, names[i])>
			</cfif>
		</cfloop>

		<cfreturn keys>
	</cffunction>

	<!---
	 * Sets the driver as the session handler in the engine.
	 * Extracted for easier testing.
	--->
	<cffunction name="setSaveHandler" access="private" returntype="void" output="no">

		<cfset session_set_save_handler(this.driver, true)>
	</cffunction>

	<!---
	 * Starts the session.
	 * Extracted for testing reasons.
	--->
	<cffunction name="startSession" access="private" returntype="void" output="no">

		<!--- Not ported yet: the ENVIRONMENT "testing" check --->

		<cfset session_start()>
	</cffunction>

	<!---
	 * Takes care of setting the cookie on the client side.
	--->
	<cffunction name="setCookie" access="private" returntype="void" output="no">
		<cfset var expiration = 0>
		<cfset var response = service("response")>

		<cfif this.config.expiration NEQ 0>
			<cfset expiration = time() + this.config.expiration>
		</cfif>

		<cfset this.cookie_ = this.cookie_.withValue(session_id()).withExpires(expiration)>

		<cfset response.setCookie(this.cookie_)>
	</cffunction>

	<!---
	 * Difference: the isset() of the original for a key of a map. An empty
	 * string is a null here, so it counts as not set.
	--->
	<cffunction name="isset_" access="private" returntype="boolean" output="no">
		<cfargument name="map" type="any" required="yes">
		<cfargument name="key" type="string" required="yes">

		<cfif NOT arguments.map.containsKey(JavaCast("string", arguments.key))>
			<cfreturn false>
		</cfif>

		<cfreturn NOT is_null(arguments.map.get(JavaCast("string", arguments.key)))>
	</cffunction>

	<!---
	 * Difference: the readers do not create $_SESSION['__ci_vars'] (that would
	 * change the data and rewrite the file); an empty map is returned when it
	 * is missing.
	--->
	<cffunction name="ciVarsRead" access="private" returntype="any" output="no">
		<cfset var data = session_state().data>

		<cfif NOT data.containsKey("__ci_vars")>
			<cfreturn array_()>
		</cfif>

		<cfreturn data.get("__ci_vars")>
	</cffunction>

	<!---
	 * Difference: $_SESSION['__ci_vars'] ??= [] of the original; returns the map.
	--->
	<cffunction name="ciVars" access="private" returntype="any" output="no">
		<cfset var data = session_state().data>

		<cfif NOT data.containsKey("__ci_vars")>
			<cfset data.put("__ci_vars", array_())>
		</cfif>

		<cfreturn data.get("__ci_vars")>
	</cffunction>

</cfcomponent>
