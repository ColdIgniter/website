<!---
 * Exceptions manager
 *
 * The exception is not a Throwable here. It is the cfcatch struct of
 * the caught error: exception.type is the class name in dotted form,
 * and exception.message, exception.errorcode and exception.tagContext
 * stand in for getMessage(), getCode(), getFile(), getLine() and
 * getTrace().
 *
 * Not ported yet: ResponseTrait (the API responses), and the methods
 * the original keeps only for backward compatibility since 4.4.0
 * (determineView, render, collectVars, maskSensitiveData, maskData,
 * cleanPath, describeMemory and highlightFile). The handler in the
 * config does all of that in BaseExceptionHandler and ExceptionHandler.
--->
<cfcomponent output="no" hint="Exceptions manager">

	<!---
	 * Nesting level of the output buffering mechanism
	 *
	 * @deprecated 4.4.0 No longer used. Moved to BaseExceptionHandler.
	 *
	 * Not ported yet: ob_get_level()
	--->
	<cfset this.ob_level = 0>

	<!---
	 * The path to the directory containing the
	 * cli and html error view directories.
	 *
	 * @deprecated 4.4.0 No longer used. Moved to BaseExceptionHandler.
	--->
	<cfset this.viewPath = "">

	<!---
	 * Config for debug exceptions.
	--->
	<cfset this.config = "">

	<!---
	 * The request.
	 *
	 * Named with an underscore, because request is a scope.
	--->
	<cfset this.request_ = "">

	<!---
	 * The outgoing response.
	--->
	<cfset this.response = "">

	<cfset this.exceptionCaughtByExceptionHandler = "">

	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">

		<!--- For backward compatibility --->
		<!--- Not ported yet: this.ob_level = ob_get_level() --->
		<cfset this.viewPath = REReplace(arguments.config.errorViewPath, "[\\/ ]+$", "") & request.DIRECTORY_SEPARATOR>

		<cfset this.config = arguments.config>

		<cfreturn this>
	</cffunction>

	<!---
	 * Responsible for registering the error, exception and shutdown
	 * handling of our application.
	 *
	 * There is no set_exception_handler, set_error_handler or
	 * register_shutdown_function here, so nothing is registered. The
	 * one place that wraps the request (Boot::runColdIgniter) catches
	 * the error and passes it to exceptionHandler().
	 *
	 * Named with an underscore, because initialize is a function.
	--->
	<cffunction name="initialize_" access="public" returntype="void" output="no">
		<!---
		 Not ported yet: set_exception_handler, set_error_handler and
		 register_shutdown_function
		--->
	</cffunction>

	<!---
	 * Catches any uncaught errors and exceptions, including most Fatal errors
	 *. Will log the error, display it if display_errors is on,
	 * and fire an event that allows custom actions to be taken at this point.
	 *
	 * @param exception The cfcatch struct
	--->
	<cffunction name="exceptionHandler" access="public" returntype="void" output="no">
		<cfargument name="exception" type="any" required="yes">
		<cfset var codes = "">
		<cfset var statusCode = 0>
		<cfset var exitCode = 0>
		<cfset var handler = "">
		<cfset var uri = "">
		<cfset var routeInfo = "">
		<cfset var exFile = "">
		<cfset var exLine = "">

		<cfset this.exceptionCaughtByExceptionHandler = arguments.exception>

		<cfset codes = determineCodes(arguments.exception)>
		<cfset statusCode = codes[1]>
		<cfset exitCode = codes[2]>

		<cfset this.request_ = service("request")>

		<cfif Compare(this.config.log, "true") EQ 0 AND NOT in_array(statusCode, this.config.ignoreCodes)>
			<cfset uri = this.request_.getPath()>
			<cfif Compare(uri, "") EQ 0>
				<cfset uri = "/">
			</cfif>
			<cfset routeInfo = "[Method: " & this.request_.getMethod() & ", Route: " & uri & "]">

			<!---
			 Difference: the class of the exception is its type, the file and
			 line are the first row of its tagContext, and the trace holds
			 the rows of the tagContext (see render_backtrace()).
			--->
			<cfif ArrayLen(arguments.exception.tagContext) GT 0>
				<cfset exFile = clean_path(arguments.exception.tagContext[1].template)>
				<cfset exLine = arguments.exception.tagContext[1].line>
			</cfif>

			<cfset log_message("critical", arguments.exception.type & ": {message}" & Chr(10) & "{routeInfo}" & Chr(10) & "in {exFile} on line {exLine}." & Chr(10) & "{trace}", array_(
				"message", arguments.exception.message,
				"routeInfo", routeInfo,
				"exFile", exFile, <!--- {file} refers to THIS file --->
				"exLine", exLine, <!--- {line} refers to THIS line --->
				"trace", render_backtrace(arguments.exception.tagContext)
			))>

			<!--- Not ported yet: the previous exceptions, a caught error has no previous one --->
		</cfif>

		<cfset this.response = service("response")>

		<cfif method_exists(this.config, "handler")>
			<!--- Use new ExceptionHandler --->
			<cfset handler = this.config.handler(statusCode, arguments.exception)>
			<cfset handler.handle(arguments.exception, this.request_, this.response, statusCode, exitCode)>

			<cfreturn>
		</cfif>

		<!---
		 Not ported yet: the code for backward compatibility, which is
		 used only when the config has no handler() method.
		--->

		<!--- exit(exitCode): a request has no exit code --->
	</cffunction>

	<!---
	 * The callback to be registered to `set_error_handler()`.
	 *
	 * Not ported yet: errorHandler, isSessionSidDeprecationError and
	 * shutdownHandler. CFML has no error levels or deprecation errors,
	 * and an error does not reach a callback before the request ends.
	--->

	<!---
	 * Determines the HTTP status code and the exit status code for this request.
	 *
	 * @return An array: the status code and the exit status code
	--->
	<cffunction name="determineCodes" access="private" returntype="array" output="no">
		<cfargument name="exception" type="any" required="yes">
		<cfset var codes = ArrayNew(1)>
		<cfset var statusCode = 500>
		<cfset var exitStatus = request.EXIT_ERROR>

		<!---
		 instanceof HTTPExceptionInterface: the exceptions of the port
		 that implement it, with the status code in the error code.
		--->
		<cfif ListFindNoCase("ColdIgniter.Exceptions.PageNotFoundException,ColdIgniter.HTTP.Exceptions.BadRequestException,ColdIgniter.Security.Exceptions.SecurityException,ColdIgniter.Honeypot.Exceptions.HoneypotException", arguments.exception.type) GT 0
				AND IsNumeric(arguments.exception.errorcode)>
			<cfset statusCode = arguments.exception.errorcode>
		</cfif>

		<!--- Not ported yet: HasExitCodeInterface --->

		<cfset ArrayAppend(codes, statusCode)>
		<cfset ArrayAppend(codes, exitStatus)>

		<cfreturn codes>
	</cffunction>

	<!---
	 * Not ported yet: isDeprecationError and handleDeprecationError
	 * (no deprecation errors in CFML).
	--->

</cfcomponent>
