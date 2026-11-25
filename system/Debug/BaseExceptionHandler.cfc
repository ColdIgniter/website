<!---
 * Provides common functions for exception handlers,
 * especially around displaying the output.
 *
 * The exception is the cfcatch struct of the caught error (see
 * Debug/Exceptions.cfc). Its tagContext, an array of the templates and
 * lines the error went through, stands in for getFile(), getLine() and
 * getTrace().
--->
<cfcomponent output="no" hint="Provides common functions for exception handlers">

	<!---
	 * Config for debug exceptions.
	--->
	<cfset this.config = "">

	<!---
	 * Nesting level of the output buffering mechanism
	 *
	 * Not ported yet: ob_get_level()
	--->
	<cfset this.obLevel = 0>

	<!---
	 * The path to the directory containing the
	 * cli and html error view directories.
	--->
	<cfset this.viewPath = "">

	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">

		<cfset this.config = arguments.config>

		<!--- Not ported yet: this.obLevel = ob_get_level() --->

		<cfif is_null(this.viewPath)>
			<cfset this.viewPath = REReplace(this.config.errorViewPath, "[\\/ ]+$", "") & request.DIRECTORY_SEPARATOR>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * The main entry point into the handler.
	 *
	 * An abstract method: a child has to define it.
	 *
	 * @param request  The IncomingRequest
	--->
	<cffunction name="handle" access="public" returntype="void" output="no">
		<cfargument name="exception" type="any" required="yes">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">
		<cfargument name="statusCode" type="numeric" required="yes">
		<cfargument name="exitCode" type="numeric" required="yes">

		<cfthrow type="ColdIgniter.Exceptions.NotImplemented" message="handle() has to be defined by the handler.">
	</cffunction>

	<!---
	 * Gathers the variables that will be made available to the view.
	 *
	 * @return An ordered map: title, type, code, message, file, line, trace
	--->
	<cffunction name="collectVars" access="private" returntype="any" output="no">
		<cfargument name="exception" type="any" required="yes">
		<cfargument name="statusCode" type="numeric" required="yes">
		<cfset var trace = ArrayNew(1)>
		<cfset var row = "">
		<cfset var file = "">
		<cfset var line = 0>
		<cfset var i = 0>

		<!--- Get the first exception. --->
		<!--- Not ported yet: the previous exceptions, a caught error has no previous one --->

		<cfloop from="1" to="#ArrayLen(arguments.exception.tagContext)#" index="i">
			<cfset row = StructNew()>
			<cfset row["file"] = arguments.exception.tagContext[i].template>
			<cfset row["line"] = arguments.exception.tagContext[i].line>
			<cfset ArrayAppend(trace, row)>
		</cfloop>

		<cfif ArrayLen(this.config.sensitiveDataInTrace) GT 0>
			<cfset trace = maskSensitiveData(trace, this.config.sensitiveDataInTrace)>
		</cfif>

		<cfif ArrayLen(trace) GT 0>
			<cfset file = trace[1]["file"]>
			<cfset line = trace[1]["line"]>
		</cfif>

		<cfreturn array_(
			"title", arguments.exception.type,
			"type", arguments.exception.type,
			"code", arguments.statusCode,
			"message", arguments.exception.message,
			"file", file,
			"line", line,
			"trace", trace
		)>
	</cffunction>

	<!---
	 * Mask sensitive data in the trace.
	 *
	 * Not ported yet: maskData. The rows of a CFML trace hold no
	 * arguments, so there is nothing to mask.
	 *
	 * @param trace      list of rows
	 * @param keysToMask list<string>
	 *
	 * @return list of rows
	--->
	<cffunction name="maskSensitiveData" access="private" returntype="array" output="no">
		<cfargument name="trace" type="array" required="yes">
		<cfargument name="keysToMask" type="array" required="yes">
		<cfargument name="path" type="string" required="no" default="">

		<cfreturn arguments.trace>
	</cffunction>

	<!---
	 * Describes memory usage in real-world units. Intended for use
	 * with memory_get_usage, etc.
	 *
	 * @used-by app/Views/errors/html/error_exception.cfm
	 *
	 * Public, because the view is not bound to the handler as the
	 * closure is in the original.
	 *
	 * Not ported yet: helper('number') and number_to_size()
	--->
	<cffunction name="describeMemory" access="public" returntype="string" output="no">
		<cfargument name="bytes" type="numeric" required="yes">

		<cfif arguments.bytes GTE 1073741824>
			<cfreturn NumberFormat(arguments.bytes / 1073741824, "0.00") & " GB">
		</cfif>
		<cfif arguments.bytes GTE 1048576>
			<cfreturn NumberFormat(arguments.bytes / 1048576, "0.00") & " MB">
		</cfif>
		<cfif arguments.bytes GTE 1024>
			<cfreturn NumberFormat(arguments.bytes / 1024, "0.00") & " KB">
		</cfif>

		<cfreturn arguments.bytes & " bytes">
	</cffunction>

	<!---
	 * Creates a version of a CFML file with line numbers, around a line.
	 * It has no syntax colours: the lines are escaped as they are.
	 *
	 * @used-by app/Views/errors/html/error_exception.cfm
	 *
	 * Public, because the view is not bound to the handler as the
	 * closure is in the original.
	 *
	 * @return false, or the HTML of the source
	--->
	<cffunction name="highlightFile" access="public" returntype="any" output="no">
		<cfargument name="file" type="string" required="yes">
		<cfargument name="lineNumber" type="numeric" required="yes">
		<cfargument name="lines" type="numeric" required="no" default="15">
		<cfset var source = "">
		<cfset var start = 0>
		<cfset var format = "">
		<cfset var out = "">
		<cfset var pos = 1>
		<cfset var eol = 0>
		<cfset var n = 0>
		<cfset var row = "">

		<cfif arguments.file EQ "" OR NOT is_file(arguments.file)>
			<cfreturn false>
		</cfif>

		<!--- Not ported yet: the highlight colours and highlight_string() --->

		<cftry>
			<cffile action="read" file="#arguments.file#" variable="source">

			<cfcatch type="any">
				<cfreturn false>
			</cfcatch>
		</cftry>

		<cfset source = Replace(Replace(source, Chr(13) & Chr(10), Chr(10), "all"), Chr(13), Chr(10), "all")>

		<!--- Get just the part to show --->
		<cfset start = Max(arguments.lineNumber - Round(arguments.lines / 2), 0)>

		<!--- Used to format the line number in the source --->
		<cfset format = Len(start + arguments.lines)>

		<!---
		 The lines are not split into a list, because a list skips the
		 empty ones. The ones before the part to show are passed over.
		--->
		<cfloop condition="pos LTE Len(source) + 1 AND n LT start + arguments.lines">
			<cfset eol = Find(Chr(10), source, pos)>
			<cfif eol EQ 0>
				<cfset eol = Len(source) + 1>
			</cfif>
			<cfset n = n + 1>

			<cfif n GT start>
				<cfset row = HTMLEditFormat(Mid(source, pos, eol - pos))>

				<!--- Each line closes its own span, unlike the original. --->
				<cfif n EQ arguments.lineNumber>
					<cfset out = out & "<span class=""line highlight""><span class=""number"">" & RJustify(n, format) & "</span> " & row & Chr(10) & "</span>">
				<cfelse>
					<cfset out = out & "<span class=""line""><span class=""number"">" & RJustify(n, format) & "</span> " & row & Chr(10) & "</span>">
				</cfif>
			</cfif>

			<cfset pos = eol + 1>
		</cfloop>

		<cfreturn "<pre><code>" & out & "</code></pre>">
	</cffunction>

	<!---
	 * Given an exception and status code will display the error to the client.
	 *
	 * The view is included in an object of its own, as in View::render().
	 *
	 * @param viewFile string|null
	--->
	<cffunction name="render" access="private" returntype="void" output="no">
		<cfargument name="exception" type="any" required="yes">
		<cfargument name="statusCode" type="numeric" required="yes">
		<cfargument name="viewFile" type="any" required="no" default="">
		<cfset var vars = "">

		<!---
		 The body that the request has left so far is dropped, so that
		 it does not come out in front of the error page.
		--->
		<cfset request.ColdIgniter.output = "">

		<cfif is_null(arguments.viewFile)>
			<cfset request.ColdIgniter.output = request.ColdIgniter.output & "The error view file was not specified. Cannot display error view.">

			<!--- exit(1): a request has no exit code --->
			<cfreturn>
		</cfif>

		<cfif NOT is_file(arguments.viewFile)>
			<cfset request.ColdIgniter.output = request.ColdIgniter.output & "The error view file """ & arguments.viewFile & """ was not found. Cannot display error view.">

			<!--- exit(1): a request has no exit code --->
			<cfreturn>
		</cfif>

		<cfset vars = collectVars(arguments.exception, arguments.statusCode)>

		<!---
		 What the closure of the original sees: the arguments, and the
		 handler, which stands in for static:: in the view as exceptionHandler.
		--->
		<cfset vars["exception"] = arguments.exception>
		<cfset vars["statusCode"] = arguments.statusCode>
		<cfset vars["viewFile"] = arguments.viewFile>
		<cfset vars["exceptionHandler"] = this>

		<!--- Not ported yet: the CLI error views output to STDERR/STDOUT --->
		<cfset request.ColdIgniter.output = request.ColdIgniter.output & new_("ColdIgniter\View\Closure").call(arguments.viewFile, vars)>
	</cffunction>

</cfcomponent>
