<!---
 * Request Trait
 *
 * Additional methods to make a PSR-7 Request class
 * compliant with the framework's own RequestInterface.
 *
 * A trait is a file of properties and functions that the component
 * includes where the original says "use RequestTrait".
 *
 * Not ported yet: the proxy IP addresses (checkIPAgainstProxy)
 * and the check of an IP address (FormatRules::valid_ip).
--->

<!---
 * Configuration settings.
--->
<cfset this.config = "">

<!---
 * IP address of the current user.
 *
 * @deprecated Will become private in a future release
--->
<cfset this.ipAddress = "">

<!---
 * Stores values we've retrieved from the globals.
 *
 * @deprecated 4.7.0 Use the Superglobals service instead
--->
<cfset this.globals = StructNew()>

<!---
 * Gets the user's IP address.
 *
 * @return IP address if it can be detected.
 *         If the IP address is not a valid IP address,
 *         then will return '0.0.0.0'.
--->
<cffunction name="getIPAddress" access="public" returntype="string" output="no">
	<cfset var proxyIPs = this.config.proxyIPs>
	<cfset var proxyIP = "">
	<cfset var spoof = "">

	<cfif this.ipAddress NEQ "">
		<cfreturn this.ipAddress>
	</cfif>

	<!--- Not ported yet: FormatRules::valid_ip, the IP address validator --->

	<cfif NOT is_array(proxyIPs) OR (IsArray(proxyIPs) AND ArrayLen(proxyIPs) GT 0)>
		<cfthrow type="ColdIgniter.Exceptions.ConfigException" message="You must set an array with Proxy IP address key and HTTP header name value in Config\App::$proxyIPs.">
	</cfif>

	<cfset this.ipAddress = getServer("REMOTE_ADDR")>

	<!--- If this is a CLI request, this.ipAddress is null. --->
	<cfif is_null(this.ipAddress)>
		<cfset this.ipAddress = "0.0.0.0">
		<cfreturn this.ipAddress>
	</cfif>

	<!--- @TODO Extract all this IP address logic to another class. --->
	<cfif IsStruct(proxyIPs)>
		<cfloop collection="#proxyIPs#" item="proxyIP">
			<cfif checkIPAgainstProxy(this.ipAddress, proxyIP)>
				<cfset spoof = getClientIP(proxyIPs[proxyIP])>

				<cfif NOT is_null(spoof)>
					<cfset this.ipAddress = spoof>
					<cfbreak>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>

	<!--- Not ported yet: the check of this.ipAddress with the validator, which gives '0.0.0.0' for an invalid one --->

	<cfreturn this.ipAddress>
</cffunction>

<!---
 * Gets the client IP address from the HTTP header.
--->
<cffunction name="getClientIP" access="private" returntype="string" output="no">
	<cfargument name="header" type="string" required="yes">
	<cfset var spoof = "">
	<cfset var headerObj = header(arguments.header)>
	<cfset var chain = "">

	<cfif NOT is_null(headerObj)>
		<cfset spoof = headerObj.getValue()>

		<!---
		 Some proxies typically list the whole chain of IP
		 addresses through which the client has reached us.
		 e.g. client_ip, proxy_ip1, proxy_ip2, etc.
		--->
		<cfset chain = explode(",", spoof)>
		<cfset spoof = Trim(chain[1])>

		<!--- Not ported yet: the check of spoof with the validator, which gives null for an invalid one --->
	</cfif>

	<cfreturn spoof>
</cffunction>

<!---
 * Checks if the request comes from one of the trusted proxies
 * configured in Config\App::$proxyIPs.
--->
<cffunction name="isFromTrustedProxy" access="private" returntype="boolean" output="no">
	<cfset var proxyIPs = this.config.proxyIPs>
	<cfset var remoteAddr = "">
	<cfset var proxyIP = "">

	<cfif NOT IsStruct(proxyIPs) OR StructCount(proxyIPs) EQ 0>
		<cfreturn false>
	</cfif>

	<cfset remoteAddr = getServer("REMOTE_ADDR")>

	<cfif NOT IsSimpleValue(remoteAddr) OR remoteAddr EQ "">
		<cfreturn false>
	</cfif>

	<cfloop collection="#proxyIPs#" item="proxyIP">
		<cfif checkIPAgainstProxy(remoteAddr, proxyIP)>
			<cfreturn true>
		</cfif>
	</cfloop>

	<cfreturn false>
</cffunction>

<!---
 * Checks if the given IP address matches the trusted proxy entry,
 * which may be a single IP address or a subnet in CIDR notation.
 * Supports both IPv4 and IPv6.
--->
<cffunction name="checkIPAgainstProxy" access="private" returntype="boolean" output="no">
	<cfargument name="ip" type="string" required="yes">
	<cfargument name="proxyIP" type="string" required="yes">

	<!--- Not ported yet: the comparison of the binary addresses and the mask. Until then no address matches a proxy. --->

	<cfreturn false>
</cffunction>

<!---
 * Fetch an item from the server array.
 *
 * @param index  Index for item to be fetched from the server array (a name or an array of names)
 * @param filter A filter name to be applied
 * @param flags
 *
 * @return mixed
--->
<cffunction name="getServer" access="public" returntype="any" output="no">
	<cfargument name="index" type="any" required="no" default="">
	<cfargument name="filter" type="any" required="no" default="">
	<cfargument name="flags" type="any" required="no" default="">

	<cfreturn fetchGlobal("server", arguments.index, arguments.filter, arguments.flags)>
</cffunction>

<!---
 * Fetch an item from the env array.
 *
 * @param index  Index for item to be fetched from the env array
 * @param filter A filter name to be applied
 * @param flags
 *
 * @return mixed
 *
 * @deprecated 4.4.4 This method does not work from the beginning. Use `env()`.
--->
<cffunction name="getEnv" access="public" returntype="any" output="no">
	<cfargument name="index" type="any" required="no" default="">
	<cfargument name="filter" type="any" required="no" default="">
	<cfargument name="flags" type="any" required="no" default="">

	<cfreturn fetchGlobal("env", arguments.index, arguments.filter, arguments.flags)>
</cffunction>

<!---
 * Allows manually setting the value of a global, like the get values, the post values, etc.
 *
 * @param name  Superglobal name (lowercase): cookie, get, post, request or server
 * @param value
 *
 * @return this
--->
<cffunction name="setGlobal" access="public" returntype="any" output="no">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="value" type="any" required="yes">

	<!--- Keep BC with this.globals array --->
	<cfset this.globals[arguments.name] = arguments.value>

	<!--- Also update Superglobals via service --->
	<cfset service("superglobals").setGlobalArray(arguments.name, arguments.value)>

	<cfreturn this>
</cffunction>

<!---
 * Fetches one or more items from a global, like cookies, get, post, etc.
 * Can optionally filter the input when you retrieve it by passing in
 * a filter.
 *
 * The filter is a constant (request.FILTER_VALIDATE_INT and the like, see
 * Polyfills/filter_var.cfm) and the flags are a number or a map with the
 * keys "flags" and "options". Without a filter (an empty string, which is
 * null here, or FILTER_UNSAFE_RAW) and without flags the value comes back
 * as it was sent, with no other cost than one check.
 *
 * Difference: a value that is not there is an empty string (null), and it is
 * not filtered. A value that is there and is an empty string is filtered,
 * except for a server value that is read by name outside the saved
 * globals (a request header): the live read gives an empty string for both
 * a missing and an empty value, so it is not filtered.
 *
 * A failed filter gives the text "false" (or an empty string with
 * FILTER_NULL_ON_FAILURE). On MX 6.1 "0 EQ false" is true, so test a failure
 * with IsBoolean(x) AND NOT IsNumeric(x) AND NOT x, never with EQ.
 *
 * @param name   Superglobal name (lowercase): cookie, get, post, request or server
 * @param index  A name, an array of names, or an empty string (null) for all values
 * @param filter Filter constant
 * @param flags  Options
 *
 * @return mixed
--->
<cffunction name="fetchGlobal" access="public" returntype="any" output="no">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="index" type="any" required="no" default="">
	<cfargument name="filter" type="any" required="no" default="">
	<cfargument name="flags" type="any" required="no" default="">
	<cfset var values = "">
	<cfset var output = "">
	<cfset var value = "">
	<cfset var found = false>
	<cfset var present = false>
	<cfset var filtering = true>
	<cfset var matcher = "">
	<cfset var matches = "">
	<cfset var key = "">
	<cfset var i = 0>
	<cfset var first = 0>
	<cfset var last = 0>
	<cfset var limit = 0>

	<cfif NOT StructKeyExists(this.globals, arguments.name)>
		<cfset populateGlobals(arguments.name)>
	</cfif>

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

	<!--- Return all values when index is null --->
	<cfif is_null(arguments.index)>
		<cfset values = CreateObject("java", "java.util.LinkedHashMap").init()>

		<cfloop collection="#this.globals[arguments.name]#" item="key">
			<cfset value = this.globals[arguments.name][key]>

			<cfif is_array(value)>
				<cfset values[key] = fetchGlobal(arguments.name, key, arguments.filter, arguments.flags)>
			<cfelse>
				<cfif filtering>
					<cfset values[key] = filter_value_(value, arguments.filter, arguments.flags)>
				<cfelse>
					<cfset values[key] = value>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn values>
	</cfif>

	<!--- allow fetching multiple keys at once --->
	<cfif IsArray(arguments.index)>
		<cfset output = CreateObject("java", "java.util.LinkedHashMap").init()>

		<cfloop from="1" to="#ArrayLen(arguments.index)#" index="i">
			<cfset key = arguments.index[i]>
			<cfset output[key] = fetchGlobal(arguments.name, key, arguments.filter, arguments.flags)>
		</cfloop>

		<cfreturn output>
	</cfif>

	<!--- Does the index contain array notation? --->
	<!---
	 Difference: the pattern only sees the text up to the last "]" (or up to
	 the first "[" when that comes later), because a "[" after the last "]"
	 can never match and every one of them would scan to the end (quadratic).
	 The matches are the same.
	--->
	<cfset first = Find("[", arguments.index)>
	<cfset last = Find("]", Reverse(arguments.index))>
	<cfif last GT 0>
		<cfset last = Len(arguments.index) - last + 1>
	</cfif>
	<cfset limit = Len(arguments.index)>
	<cfif first GT 0>
		<cfset limit = Max(last, first - 1)>
	</cfif>
	<cfset matcher = CreateObject("java", "java.util.regex.Pattern").compile("(?:^[^\[]+)|\[[^\]]*\]").matcher(JavaCast("string", arguments.index).substring(JavaCast("int", 0), JavaCast("int", limit)))>
	<cfset matches = ArrayNew(1)>

	<cfloop condition="matcher.find()">
		<cfset ArrayAppend(matches, matcher.group())>
	</cfloop>

	<cfif ArrayLen(matches) GT 1>
		<cfset value = this.globals[arguments.name]>
		<cfset found = true>
		<cfset present = true>

		<cfloop from="1" to="#ArrayLen(matches)#" index="i">
			<cfif Left(matches[i], 1) EQ "[">
				<cfset key = Mid(matches[i], 2, Len(matches[i]) - 2)>
			<cfelse>
				<cfset key = matches[i]>
			</cfif>

			<!--- Empty notation will return the value as array --->
			<cfif key EQ "">
				<cfbreak>
			</cfif>

			<cfif is_array(value) AND array_key_exists(key, value)>
				<cfif IsArray(value)>
					<cfset value = value[Val(key) + 1]>
				<cfelse>
					<cfset value = value[key]>
				</cfif>
			<cfelse>
				<cfreturn "">
			</cfif>
		</cfloop>
	</cfif>

	<cfif NOT found AND array_key_exists(arguments.index, this.globals[arguments.name])>
		<cfset value = this.globals[arguments.name][arguments.index]>
		<cfset present = true>
	<cfelseif NOT found AND arguments.name EQ "server">
		<!--- the CGI scope does not list the request headers (HTTP_*), but a read by name finds them --->
		<!--- this reads the live value, not the saved snapshot of the server globals --->
		<cfset value = service("superglobals").server(arguments.index)>
		<cfset present = Len(value) GT 0>
	</cfif>

	<cfif filtering AND present>
		<cfif IsArray(value) OR IsStruct(value)>
			<!--- array_walk_recursive with filter_var, on a copy --->
			<cfreturn filter_walk_(value, arguments.filter, arguments.flags)>
		</cfif>

		<!--- cannot filter these types of data automatically... --->
		<cfif IsSimpleValue(value)>
			<cfreturn filter_value_(value, arguments.filter, arguments.flags)>
		</cfif>
	</cfif>

	<cfreturn value>
</cffunction>

<!---
 * Saves a copy of the current state of one of several globals,
 * so we can retrieve them later.
 *
 * @param name Superglobal name (lowercase): cookie, get, post, request or server
 *
 * @deprecated 4.7.0 No longer needs to be called explicitly. Used internally to maintain BC with this.globals.
--->
<cffunction name="populateGlobals" access="private" returntype="void" output="no">
	<cfargument name="name" type="string" required="yes">

	<cfif NOT StructKeyExists(this.globals, arguments.name)>
		<cfset this.globals[arguments.name] = CreateObject("java", "java.util.LinkedHashMap").init()>
	</cfif>

	<!--- Get data from Superglobals service instead of direct access --->
	<cfset this.globals[arguments.name] = service("superglobals").getGlobalArray(arguments.name)>
</cffunction>
