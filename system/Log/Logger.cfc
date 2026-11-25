<!---
 * The ColdIgniter Logger
 *
 * The message MUST be a string.
 *
 * The message MAY contain placeholders in the form: {foo} where foo
 * will be replaced by the context data in key "foo".
 *
 * The context map can contain arbitrary data, the only assumption that
 * can be made by implementors is that if an exception is given
 * to produce a stack trace, it MUST be in a key named "exception".
 *
 * Make the context with array_(), so that its keys keep their case.
 *
 * Difference: log() is named log_(), a built-in function has the name.
 *
 * Difference: an exception is the cfcatch struct, and is told from
 * another struct by its key tagContext. Not ported yet: Stringable and
 * Entity values (there are no such objects), and the message that is an
 * object (it is shown with print_r()).
 *
 * Difference: there is no debug_backtrace(), so {file} and {line} are
 * found from the template trace of an error that is thrown and caught on
 * the spot (see determineFile()).
 *
 * Not ported yet: {session_vars}, the session is not ported yet.
 *
 * logCache is read by the Logs collector of the debug toolbar.
--->
<cfcomponent output="no" hint="The ColdIgniter Logger">

	<!---
	 * Used by the logThreshold Config setting to define
	 * which errors to show.
	 *
	 * @var map of the level name to its number
	--->
	<cfset this.logLevels = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.logLevels["emergency"] = 1>
	<cfset this.logLevels["alert"] = 2>
	<cfset this.logLevels["critical"] = 3>
	<cfset this.logLevels["error"] = 4>
	<cfset this.logLevels["warning"] = 5>
	<cfset this.logLevels["notice"] = 6>
	<cfset this.logLevels["info"] = 7>
	<cfset this.logLevels["debug"] = 8>

	<!---
	 * Array of levels to be logged. The rest will be ignored.
	 *
	 * Set in app/Config/Logger.cfc
	 *
	 * @var list<string>
	--->
	<cfset this.loggableLevels = ArrayNew(1)>

	<!---
	 * File permissions
	 *
	 * Not ported yet: used by the file handler only, see there.
	 *
	 * @var int
	--->
	<cfset this.filePermissions = 420>

	<!---
	 * Format of the timestamp for log files.
	 *
	 * @var string
	--->
	<cfset this.dateFormat = "Y-m-d H:i:s">

	<!---
	 * Filename Extension
	 *
	 * @var string
	--->
	<cfset this.fileExt = "">

	<!---
	 * Caches instances of the handlers.
	 *
	 * @var map of the class name to the handler
	--->
	<cfset this.handlers = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Holds the configuration for each handler.
	 * The key is the handler's class name. The
	 * value is a map of configuration
	 * items.
	 *
	 * @var map of the class name to a map
	--->
	<cfset this.handlerConfig = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Caches logging calls for debugbar.
	 *
	 * @var list<map: level, msg>
	--->
	<cfset this.logCache = "">

	<!---
	 * Should we cache our logged items?
	 *
	 * @var bool
	--->
	<cfset this.cacheLogs = false>

	<!---
	 * Constructor.
	 *
	 * @param config Config\Logger
	 *
	 * @throws RuntimeException
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfargument name="debug" type="boolean" required="no" default="#request.CI_DEBUG#">
		<cfset var loggableLevels = ArrayNew(1)>
		<cfset var stringLevel = "">
		<cfset var level = "">
		<cfset var i = 0>

		<cfif IsArray(arguments.config.threshold)>
			<cfset loggableLevels = arguments.config.threshold>
		<cfelse>
			<!---
			 range(1, threshold)
			 Difference: range() counts down when the threshold is below 1, so
			 a threshold of 0 or less gives 1 first and then 0 and the numbers
			 below it. Only the 1 (emergency) is a level, so it is logged
			 whatever the threshold is.
			--->
			<cfif Fix(Val(arguments.config.threshold)) LT 1>
				<cfset ArrayAppend(loggableLevels, 1)>
			<cfelse>
				<cfloop from="1" to="#Fix(Val(arguments.config.threshold))#" index="i">
					<cfset ArrayAppend(loggableLevels, i)>
				</cfloop>
			</cfif>
		</cfif>

		<!--- Now convert loggable levels to strings. --->
		<!--- We only use numbers to make the threshold setting convenient for users. --->
		<cfloop from="1" to="#ArrayLen(loggableLevels)#" index="i">
			<cfset stringLevel = ""> <!--- array_search() --->

			<cfloop collection="#this.logLevels#" item="level">
				<!--- Difference: Compare() is used, the original compares strictly, and CFML equality treats "yes" and "true" as 1 --->
				<cfif Compare(this.logLevels[level], loggableLevels[i]) EQ 0>
					<cfset stringLevel = level>
				</cfif>
			</cfloop>

			<cfif stringLevel NEQ "">
				<cfset ArrayAppend(this.loggableLevels, stringLevel)>
			</cfif>
		</cfloop>

		<cfset this.dateFormat = arguments.config.dateFormat>

		<cfif StructIsEmpty(arguments.config.handlers)>
			<cfset static_("ColdIgniter\Log\Exceptions\LogException").forNoHandlers("LoggerConfig")>
		</cfif>

		<!--- Save the handler configuration for later. --->
		<!--- Instances will be created on demand. --->
		<cfset this.handlerConfig = arguments.config.handlers>
		<cfset this.cacheLogs = arguments.debug>

		<cfif this.cacheLogs>
			<cfset this.logCache = ArrayNew(1)>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * System is unusable.
	--->
	<cffunction name="emergency" access="public" returntype="void" output="no">
		<cfargument name="message" type="any" required="yes">
		<cfargument name="context" type="any" required="no" default="">

		<cfset log_("emergency", arguments.message, arguments.context)>
	</cffunction>

	<!---
	 * Action must be taken immediately.
	 *
	 * Example: Entire website down, database unavailable, etc. This should
	 * trigger the SMS alerts and wake you up.
	--->
	<cffunction name="alert" access="public" returntype="void" output="no">
		<cfargument name="message" type="any" required="yes">
		<cfargument name="context" type="any" required="no" default="">

		<cfset log_("alert", arguments.message, arguments.context)>
	</cffunction>

	<!---
	 * Critical conditions.
	 *
	 * Example: Application component unavailable, unexpected exception.
	--->
	<cffunction name="critical" access="public" returntype="void" output="no">
		<cfargument name="message" type="any" required="yes">
		<cfargument name="context" type="any" required="no" default="">

		<cfset log_("critical", arguments.message, arguments.context)>
	</cffunction>

	<!---
	 * Runtime errors that do not require immediate action but should typically
	 * be logged and monitored.
	--->
	<cffunction name="error" access="public" returntype="void" output="no">
		<cfargument name="message" type="any" required="yes">
		<cfargument name="context" type="any" required="no" default="">

		<cfset log_("error", arguments.message, arguments.context)>
	</cffunction>

	<!---
	 * Exceptional occurrences that are not errors.
	 *
	 * Example: Use of deprecated APIs, poor use of an API, undesirable things
	 * that are not necessarily wrong.
	--->
	<cffunction name="warning" access="public" returntype="void" output="no">
		<cfargument name="message" type="any" required="yes">
		<cfargument name="context" type="any" required="no" default="">

		<cfset log_("warning", arguments.message, arguments.context)>
	</cffunction>

	<!---
	 * Normal but significant events.
	--->
	<cffunction name="notice" access="public" returntype="void" output="no">
		<cfargument name="message" type="any" required="yes">
		<cfargument name="context" type="any" required="no" default="">

		<cfset log_("notice", arguments.message, arguments.context)>
	</cffunction>

	<!---
	 * Interesting events.
	 *
	 * Example: User logs in, SQL logs.
	--->
	<cffunction name="info" access="public" returntype="void" output="no">
		<cfargument name="message" type="any" required="yes">
		<cfargument name="context" type="any" required="no" default="">

		<cfset log_("info", arguments.message, arguments.context)>
	</cffunction>

	<!---
	 * Detailed debug information.
	--->
	<cffunction name="debug" access="public" returntype="void" output="no">
		<cfargument name="message" type="any" required="yes">
		<cfargument name="context" type="any" required="no" default="">

		<cfset log_("debug", arguments.message, arguments.context)>
	</cffunction>

	<!---
	 * Logs with an arbitrary level.
	 *
	 * @param level   A level name, or its number
	 * @param message string
	 * @param context map
	--->
	<cffunction name="log_" access="public" returntype="void" output="no">
		<cfargument name="level" type="any" required="yes">
		<cfargument name="message" type="any" required="yes">
		<cfargument name="context" type="any" required="no" default="">
		<cfset var name = "">
		<cfset var className = "">
		<cfset var config = "">
		<cfset var handler = "">

		<cfif is_null(arguments.context)>
			<cfset arguments.context = array_()>
		</cfif>

		<cfif IsNumeric(arguments.level)>
			<!--- array_search() --->
			<cfset name = "">

			<cfloop collection="#this.logLevels#" item="className">
				<cfif this.logLevels[className] EQ Int(arguments.level)>
					<cfset name = className>
				</cfif>
			</cfloop>

			<cfset arguments.level = name>
		</cfif>

		<cfif NOT array_key_exists(arguments.level, this.logLevels)>
			<cfset static_("ColdIgniter\Log\Exceptions\LogException").forInvalidLogLevel(arguments.level)>
		</cfif>

		<cfif NOT in_array(arguments.level, this.loggableLevels)>
			<cfreturn>
		</cfif>

		<cfset arguments.message = interpolate(arguments.message, arguments.context)>

		<cfif this.cacheLogs>
			<cfset ArrayAppend(this.logCache, array_("level", arguments.level, "msg", arguments.message))>
		</cfif>

		<cfloop collection="#this.handlerConfig#" item="className">
			<cfset config = this.handlerConfig[className]>

			<cfif NOT array_key_exists(className, this.handlers)>
				<cfset this.handlers[className] = new_(className, config)>
			</cfif>

			<cfset handler = this.handlers[className]>

			<cfif handler.canHandle(arguments.level)>
				<!--- If the handler returns false, then we don't execute any other handlers. --->
				<cfif NOT handler.setDateFormat(this.dateFormat).handle(arguments.level, arguments.message)>
					<cfbreak>
				</cfif>
			</cfif>
		</cfloop>
	</cffunction>

	<!---
	 * Replaces any placeholders in the message with variables
	 * from the context, as well as a few special items like:
	 *
	 * {session_vars}
	 * {post_vars}
	 * {get_vars}
	 * {env}
	 * {env:foo}
	 * {file}
	 * {line}
	 *
	 * Difference: {post_vars} and {get_vars} are only looked up when the
	 * message has them, the result is the same.
	 *
	 * @param message string
	 * @param context map
	 *
	 * @return string
	--->
	<cffunction name="interpolate" access="private" returntype="string" output="no">
		<cfargument name="message" type="any" required="yes">
		<cfargument name="context" type="any" required="no" default="">
		<cfset var replace = array_()>
		<cfset var key = "">
		<cfset var placeholder = "">
		<cfset var location = "">
		<cfset var found = "">
		<cfset var str = "">

		<cfif NOT IsSimpleValue(arguments.message)>
			<cfreturn print_r(arguments.message)>
		</cfif>

		<cfif is_null(arguments.context)>
			<cfset arguments.context = array_()>
		</cfif>

		<cfloop collection="#arguments.context#" item="key">
			<cfset placeholder = "{" & key & "}">

			<cfif Find(placeholder, arguments.message) GT 0>
				<!--- todo - sanitize input before writing to file? --->
				<cfset replace[placeholder] = stringifyContextValue(key, arguments.context[key])>
			</cfif>
		</cfloop>

		<cfif Find("{post_vars}", arguments.message) GT 0>
			<cfset replace["{post_vars}"] = "$_POST: " & print_r(service("superglobals").getPostArray())>
		</cfif>

		<cfif Find("{get_vars}", arguments.message) GT 0>
			<cfset replace["{get_vars}"] = "$_GET: " & print_r(service("superglobals").getGetArray())>
		</cfif>

		<cfset replace["{env}"] = request.ENVIRONMENT>

		<!--- Allow us to log the file/line that we are logging from --->
		<cfif Find("{file}", arguments.message) GT 0 OR Find("{line}", arguments.message) GT 0>
			<cfset location = determineFile()>

			<cfset replace["{file}"] = location[1]>
			<cfset replace["{line}"] = location[2]>
		</cfif>

		<!--- Match up environment variables in {env:foo} tags. --->
		<cfif Find("env:", arguments.message) GT 0>
			<!--- preg_match() gives the first match only --->
			<cfset found = REFind("env:[^}]+", arguments.message, 1, true)>

			<cfif found.pos[1] GT 0>
				<cfset str = Mid(arguments.message, found.pos[1], found.len[1])>
				<cfset key = Replace(str, "env:", "", "all")>

				<cfif StructKeyExists(request.ColdIgniter.env, key)>
					<cfset replace["{" & str & "}"] = request.ColdIgniter.env[key]>
				<cfelse>
					<cfset replace["{" & str & "}"] = "n/a">
				</cfif>
			</cfif>
		</cfif>

		<!--- Not ported yet: {session_vars}, the session is not ported yet --->

		<cfreturn strtr(arguments.message, replace)>
	</cffunction>

	<!---
	 * Converts context values to strings without raising errors.
	--->
	<cffunction name="stringifyContextValue" access="private" returntype="string" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="value" type="any" required="yes">
		<cfset var file = "">
		<cfset var line = "">
		<cfset var exMessage = "">
		<cfset var exContext = "">
		<cfset var isException = false>

		<!---
		 Verify that the 'exception' key is actually an exception.
		 Difference: there is no Throwable. The caught error (cfcatch) is a
		 Java object that fails IsStruct, with the message and the tagContext
		 that Debug/Exceptions reads; the same is looked for in a struct. A
		 value that has no message or no tagContext is not an exception.
		--->
		<cfif Compare(arguments.key, "exception") EQ 0 AND NOT IsSimpleValue(arguments.value) AND NOT IsArray(arguments.value)>
			<cftry>
				<cfset exMessage = arguments.value.message>
				<cfset exContext = arguments.value.tagContext>
				<cfset isException = IsSimpleValue(exMessage) AND IsArray(exContext)>

				<cfcatch type="any">
					<cfset isException = false>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif isException>
			<cfif ArrayLen(exContext) GT 0>
				<cfset file = clean_path(exContext[1].template)>
				<cfset line = exContext[1].line>
			</cfif>

			<cfreturn exMessage & " " & file & ":" & line>
		</cfif>

		<cfif IsSimpleValue(arguments.value)>
			<cfreturn arguments.value>
		</cfif>

		<cfif IsArray(arguments.value) OR IsStruct(arguments.value)>
			<cfreturn print_r(arguments.value)>
		</cfif>

		<cfif IsObject(arguments.value)>
			<cfreturn "[object " & Replace(GetMetaData(arguments.value).name, ".", "\", "all") & "]">
		</cfif>

		<cfreturn "[unknown]">
	</cffunction>

	<!---
	 * Determines the file and line that the logging call
	 * was made from by analyzing the backtrace.
	 * Find the earliest stack frame that is part of our logging system.
	 *
	 * Difference: the trace of an error that is thrown here and caught at
	 * once is used (its tagContext), the innermost row first. The first row
	 * that is not in this file or in Common.cfm is the caller of the logging
	 * call. When there is none, the result is "unknown". The line is the
	 * line of the tag that made the call.
	 *
	 * @return A list of two: the file and the line
	--->
	<cffunction name="determineFile" access="public" returntype="array" output="no">
		<cfset var result = ArrayNew(1)>
		<cfset var trace = ArrayNew(1)>
		<cfset var template = "">
		<cfset var i = 0>

		<cfset ArrayAppend(result, "unknown")>
		<cfset ArrayAppend(result, "unknown")>

		<cftry>
			<cfthrow type="Application" message="trace">

			<cfcatch type="any">
				<cfset trace = cfcatch.tagContext>
			</cfcatch>
		</cftry>

		<cfloop from="1" to="#ArrayLen(trace)#" index="i">
			<cfset template = Replace(trace[i].template, "\", "/", "all")>

			<cfif NOT REFindNoCase("/(Log/Logger\.cfc|Common\.cfm)$", template)>
				<cfset result[1] = clean_path(trace[i].template)>
				<cfset result[2] = trace[i].line>

				<cfbreak>
			</cfif>
		</cfloop>

		<cfreturn result>
	</cffunction>

</cfcomponent>
