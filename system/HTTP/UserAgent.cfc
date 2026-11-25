<!---
 * Abstraction for an HTTP user agent
 *
 * Difference: the user agent is compiled on first use, not in the
 * constructor, so a request that never asks about the browser, the platform,
 * the robot or the mobile pays nothing. The result is the same.
 *
 * Difference: the properties isBrowser, isRobot and isMobile are named with a
 * trailing underscore, as a function of the same name exists. The properties
 * with no value are empty strings, and a user agent header that is empty is
 * the same as a missing one: nothing is compiled, so the platform stays empty
 * where the original reports "Unknown Platform" for an empty header.
 *
 * Difference: a platform and a robot key is a plain text, so it is found
 * with FindNoCase(), where the original runs a quoted pattern with the i
 * flag; the result is the same. A browser key is a pattern, so it is
 * compiled once (always with the i flag) to a java.util.regex.Pattern, kept
 * in shared_().userAgent[SYSTEMPATH] (the application scope), one synchronized
 * java.util.Hashtable per install, keyed by the text of the pattern, so the
 * key is case-sensitive. A Pattern is immutable and the entries hold no
 * value of the request, so they are shared by every request.
 *
 * Difference: the referrer is "" until it is known, then a boolean.
--->
<cfcomponent output="no" hint="Abstraction for an HTTP user agent">

	<!---
	 * Current user-agent
	 *
	 * @var string
	--->
	<cfset this.agent = "">

	<!---
	 * Flag for if the user-agent belongs to a browser
	 *
	 * @var bool
	--->
	<cfset this.isBrowser_ = false>

	<!---
	 * Flag for if the user-agent is a robot
	 *
	 * @var bool
	--->
	<cfset this.isRobot_ = false>

	<!---
	 * Flag for if the user-agent is a mobile browser
	 *
	 * @var bool
	--->
	<cfset this.isMobile_ = false>

	<!---
	 * Holds the config file contents.
	 *
	 * @var UserAgents
	--->
	<cfset this.config = "">

	<!---
	 * Current user-agent platform
	 *
	 * @var string
	--->
	<cfset this.platform = "">

	<!---
	 * Current user-agent browser
	 *
	 * @var string
	--->
	<cfset this.browser = "">

	<!---
	 * Current user-agent version
	 *
	 * @var string
	--->
	<cfset this.version = "">

	<!---
	 * Current user-agent mobile name
	 *
	 * @var string
	--->
	<cfset this.mobile = "">

	<!---
	 * Current user-agent robot name
	 *
	 * @var string
	--->
	<cfset this.robot = "">

	<!---
	 * HTTP Referer
	 *
	 * @var bool|string|null
	--->
	<cfset this.referrer = "">

	<!---
	 * True while the agent string waits to be compiled.
	--->
	<cfset this.pending_ = false>

	<!---
	 * Constructor
	 *
	 * Sets the User Agent. It is compiled when it is first asked for.
	 *
	 * @param config The Config\UserAgents, or an empty string (null)
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfset var userAgent = "">

		<cfif is_null(arguments.config)>
			<!--- the factory is called directly: config() would resolve to the argument of this name --->
			<cfset this.config = static_("ColdIgniter\Config\Factories").get("config", "Config\UserAgents")>
		<cfelse>
			<cfset this.config = arguments.config>
		</cfif>

		<cfset userAgent = service("superglobals").server("HTTP_USER_AGENT")>

		<cfif NOT is_null(userAgent)>
			<cfset this.agent = Trim(userAgent)>
			<cfset this.pending_ = true>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Is Browser
	--->
	<cffunction name="isBrowser" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="any" required="no" default="">

		<cfset compile_()>

		<cfif NOT this.isBrowser_>
			<cfreturn false>
		</cfif>

		<!--- No need to be specific, it's a browser --->
		<cfif arguments.key EQ "">
			<cfreturn true>
		</cfif>

		<!--- Check for a specific browser --->
		<cfreturn this.config.browsers.containsKey(JavaCast("string", arguments.key)) AND Compare(this.browser, this.config.browsers.get(JavaCast("string", arguments.key))) EQ 0>
	</cffunction>

	<!---
	 * Is Robot
	--->
	<cffunction name="isRobot" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="any" required="no" default="">

		<cfset compile_()>

		<cfif NOT this.isRobot_>
			<cfreturn false>
		</cfif>

		<!--- No need to be specific, it's a robot --->
		<cfif arguments.key EQ "">
			<cfreturn true>
		</cfif>

		<!--- Check for a specific robot --->
		<cfreturn this.config.robots.containsKey(JavaCast("string", arguments.key)) AND Compare(this.robot, this.config.robots.get(JavaCast("string", arguments.key))) EQ 0>
	</cffunction>

	<!---
	 * Is Mobile
	--->
	<cffunction name="isMobile" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="any" required="no" default="">

		<cfset compile_()>

		<cfif NOT this.isMobile_>
			<cfreturn false>
		</cfif>

		<!--- No need to be specific, it's a mobile --->
		<cfif arguments.key EQ "">
			<cfreturn true>
		</cfif>

		<!--- Check for a specific robot --->
		<cfreturn this.config.mobiles.containsKey(JavaCast("string", arguments.key)) AND Compare(this.mobile, this.config.mobiles.get(JavaCast("string", arguments.key))) EQ 0>
	</cffunction>

	<!---
	 * Is this a referral from another site?
	--->
	<cffunction name="isReferral" access="public" returntype="boolean" output="no">
		<cfset var referer = "">
		<cfset var refererHost = "">
		<cfset var ownHost = "">
		<cfset var parts = "">

		<cfif NOT IsBoolean(this.referrer)>
			<cfset referer = service("superglobals").server("HTTP_REFERER")>

			<cfif is_null(referer)>
				<cfset this.referrer = false>
			<cfelse>
				<cfset parts = parse_url(referer)>

				<cfif parts.containsKey("host")>
					<cfset refererHost = parts.get("host")>
				</cfif>

				<cfset parts = parse_url(base_url())>

				<cfif parts.containsKey("host")>
					<cfset ownHost = parts.get("host")>
				</cfif>

				<cfset this.referrer = (refererHost NEQ "" AND refererHost NEQ "0" AND Compare(refererHost, ownHost) NEQ 0)>
			</cfif>
		</cfif>

		<cfreturn this.referrer>
	</cffunction>

	<!---
	 * Agent String
	--->
	<cffunction name="getAgentString" access="public" returntype="string" output="no">
		<cfreturn this.agent>
	</cffunction>

	<!---
	 * Get Platform
	--->
	<cffunction name="getPlatform" access="public" returntype="string" output="no">
		<cfset compile_()>

		<cfreturn this.platform>
	</cffunction>

	<!---
	 * Get Browser Name
	--->
	<cffunction name="getBrowser" access="public" returntype="string" output="no">
		<cfset compile_()>

		<cfreturn this.browser>
	</cffunction>

	<!---
	 * Get the Browser Version
	--->
	<cffunction name="getVersion" access="public" returntype="string" output="no">
		<cfset compile_()>

		<cfreturn this.version>
	</cffunction>

	<!---
	 * Get The Robot Name
	--->
	<cffunction name="getRobot" access="public" returntype="string" output="no">
		<cfset compile_()>

		<cfreturn this.robot>
	</cffunction>

	<!---
	 * Get the Mobile Device
	--->
	<cffunction name="getMobile" access="public" returntype="string" output="no">
		<cfset compile_()>

		<cfreturn this.mobile>
	</cffunction>

	<!---
	 * Get the referrer
	--->
	<cffunction name="getReferrer" access="public" returntype="string" output="no">
		<cfreturn Trim(service("superglobals").server("HTTP_REFERER"))>
	</cffunction>

	<!---
	 * Parse a custom user-agent string
	 *
	 * The string is compiled when it is first asked for.
	--->
	<cffunction name="parse" access="public" returntype="void" output="no">
		<cfargument name="string" type="string" required="yes">

		<!--- an agent that waits to be compiled sets the platform first, as the original did in its constructor --->
		<cfif arguments.string EQ "">
			<cfset compile_()>
		</cfif>

		<!--- Reset values --->
		<cfset this.isBrowser_ = false>
		<cfset this.isRobot_ = false>
		<cfset this.isMobile_ = false>
		<cfset this.browser = "">
		<cfset this.version = "">
		<cfset this.mobile = "">
		<cfset this.robot = "">

		<!--- Set the new user-agent string and parse it, unless empty --->
		<cfset this.agent = arguments.string>
		<cfset this.pending_ = (arguments.string NEQ "")>
	</cffunction>

	<!---
	 * Compiles the agent string when it waits to be compiled.
	--->
	<cffunction name="compile_" access="private" returntype="void" output="no">
		<cfif this.pending_>
			<cfset this.pending_ = false>
			<cfset compileData()>
		</cfif>
	</cffunction>

	<!---
	 * Compile the User Agent Data
	--->
	<cffunction name="compileData" access="private" returntype="void" output="no">
		<cfset setPlatform()>

		<cfif setRobot()>
			<cfreturn>
		</cfif>

		<cfif setBrowser()>
			<cfreturn>
		</cfif>

		<cfset setMobile()>
	</cffunction>

	<!---
	 * Finds the first key of a map that is in the agent string, ignoring
	 * case. Gives the key, or an empty string.
	--->
	<cffunction name="firstKey" access="private" returntype="string" output="no">
		<cfargument name="list" type="any" required="yes">
		<cfset var it = arguments.list.keySet().iterator()>
		<cfset var key = "">

		<cfloop condition="it.hasNext()">
			<cfset key = it.next()>

			<cfif FindNoCase(key, this.agent) GT 0>
				<cfreturn key>
			</cfif>
		</cfloop>

		<cfreturn "">
	</cffunction>

	<!---
	 * Set the Platform
	--->
	<cffunction name="setPlatform" access="private" returntype="boolean" output="no">
		<cfset var key = "">

		<cfif this.config.platforms.size() GT 0>
			<cfset key = firstKey(this.config.platforms)>

			<cfif key NEQ "">
				<cfset this.platform = this.config.platforms.get(JavaCast("string", key))>

				<cfreturn true>
			</cfif>
		</cfif>

		<cfset this.platform = "Unknown Platform">

		<cfreturn false>
	</cffunction>

	<!---
	 * Set the Browser
	--->
	<cffunction name="setBrowser" access="private" returntype="boolean" output="no">
		<cfset var it = "">
		<cfset var key = "">
		<cfset var val = "">
		<cfset var patterns = "">
		<cfset var matcher = "">
		<cfset var version = "">
		<cfset var safari = "">

		<cfif this.config.browsers.size() GT 0>
			<cfset patterns = userAgentPatterns()>
			<cfset it = this.config.browsers.keySet().iterator()>

			<cfloop condition="it.hasNext()">
				<cfset key = it.next()>
				<cfset matcher = userAgentPattern(patterns, key & ".*?([0-9\.]+)").matcher(JavaCast("string", this.agent))>

				<cfif matcher.find()>
					<cfset val = this.config.browsers.get(JavaCast("string", key))>
					<cfset version = matcher.group(1)>

					<!--- Safari's browser version is reported in the Version token. --->
					<cfif Compare(val, "Safari") EQ 0>
						<cfset safari = userAgentPattern(patterns, "Version/([0-9\.]+).*?Safari").matcher(JavaCast("string", this.agent))>

						<cfif safari.find()>
							<cfset version = safari.group(1)>
						</cfif>
					</cfif>

					<cfset this.isBrowser_ = true>
					<cfset this.version = version>
					<cfset this.browser = val>
					<cfset setMobile()>

					<cfreturn true>
				</cfif>
			</cfloop>
		</cfif>

		<cfreturn false>
	</cffunction>

	<!---
	 * Set the Robot
	--->
	<cffunction name="setRobot" access="private" returntype="boolean" output="no">
		<cfset var key = "">

		<cfif this.config.robots.size() GT 0>
			<cfset key = firstKey(this.config.robots)>

			<cfif key NEQ "">
				<cfset this.isRobot_ = true>
				<cfset this.robot = this.config.robots.get(JavaCast("string", key))>
				<cfset setMobile()>

				<cfreturn true>
			</cfif>
		</cfif>

		<cfreturn false>
	</cffunction>

	<!---
	 * Set the Mobile Device
	--->
	<cffunction name="setMobile" access="private" returntype="boolean" output="no">
		<cfset var key = "">

		<cfif this.config.mobiles.size() GT 0>
			<cfset key = firstKey(this.config.mobiles)>

			<cfif key NEQ "">
				<cfset this.isMobile_ = true>
				<cfset this.mobile = this.config.mobiles.get(JavaCast("string", key))>

				<cfreturn true>
			</cfif>
		</cfif>

		<cfreturn false>
	</cffunction>

	<!---
	 * Gives the table of the compiled patterns, made on first use.
	--->
	<cffunction name="userAgentPatterns" access="private" returntype="any" output="no">
		<cfset var path = "">
		<cfset var all = shared_().userAgent>
		<cfset var table = "">

		<cfif StructKeyExists(request, "SYSTEMPATH")>
			<cfset path = request.SYSTEMPATH>
		</cfif>

		<cfif NOT StructKeyExists(all, path)>
			<!--- no lock: two first requests that build it at the same time waste one empty table. It is a synchronized Hashtable that every request writes to after it is stored. --->
			<cfset table = CreateObject("java", "java.util.Hashtable").init()>
			<cfset all[path] = table>
		</cfif>

		<cfreturn all[path]>
	</cffunction>

	<!---
	 * Gives the compiled pattern for a text, ignoring case. A pattern that
	 * is not in the table is compiled and stored.
	--->
	<cffunction name="userAgentPattern" access="private" returntype="any" output="no">
		<cfargument name="patterns" type="any" required="yes">
		<cfargument name="text" type="string" required="yes">
		<cfset var compiled = "">

		<cfif arguments.patterns.containsKey(JavaCast("string", arguments.text))>
			<cfreturn arguments.patterns.get(JavaCast("string", arguments.text))>
		</cfif>

		<cfset compiled = CreateObject("java", "java.util.regex.Pattern").compile(JavaCast("string", arguments.text), JavaCast("int", 2))>
		<cfset arguments.patterns.put(JavaCast("string", arguments.text), compiled)>

		<cfreturn compiled>
	</cffunction>

	<!---
	 * Outputs the original Agent String when cast as a string.
	--->
	<cffunction name="__toString" access="public" returntype="string" output="no">
		<cfreturn getAgentString()>
	</cffunction>

</cfcomponent>
