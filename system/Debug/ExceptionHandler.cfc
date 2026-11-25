<!---
 * Not ported yet: ExceptionHandlerInterface (there are no interfaces,
 * the handle() method is the one the interface asks for), ResponseTrait
 * (the API responses), CLIRequest and the CLI views, so the request is
 * always an IncomingRequest.
--->
<cfcomponent output="no" extends="BaseExceptionHandler" hint="The default exception handler">

	<!---
	 * ResponseTrait needs this.
	 *
	 * Named with an underscore, because request is a scope.
	--->
	<cfset this.request_ = "">

	<!---
	 * ResponseTrait needs this.
	--->
	<cfset this.response = "">

	<!---
	 * Determines the correct way to display the error.
	 *
	 * @param request The IncomingRequest
	--->
	<cffunction name="handle" access="public" returntype="void" output="no">
		<cfargument name="exception" type="any" required="yes">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">
		<cfargument name="statusCode" type="numeric" required="yes">
		<cfargument name="exitCode" type="numeric" required="yes">
		<cfset var addPath = "">
		<cfset var path = "">
		<cfset var altPath = "">
		<cfset var view = "">
		<cfset var altView = "">
		<cfset var viewFile = "">

		<!--- ResponseTrait needs these properties. --->
		<cfset this.request_ = arguments.request_>
		<cfset this.response = arguments.response>

		<!--- Not ported yet: if (request instanceof IncomingRequest), a request is always one --->
		<cftry>
			<cfset arguments.response.setStatusCode(arguments.statusCode)>

			<cfcatch type="ColdIgniter.HTTP.Exceptions.HTTPException">
				<!--- Workaround for invalid HTTP status code. --->
				<cfset arguments.statusCode = 500>
				<cfset arguments.response.setStatusCode(arguments.statusCode)>
			</cfcatch>
		</cftry>

		<!--- Not ported yet: headers_sent() --->
		<cfheader statuscode="#arguments.response.getStatusCode()#" statustext="#arguments.response.getReasonPhrase()#">
		<cfcontent type="text/html; charset=UTF-8">

		<!---
		 Not ported yet: the non-HTML requests, which are answered
		 with the error data in the format of the request (JSON, XML)
		 through ResponseTrait::respond(). A request is always
		 answered with the HTML view for now.
		--->

		<!--- Determine possible directories of error views --->
		<cfset addPath = "html" & request.DIRECTORY_SEPARATOR>
		<cfset path = this.viewPath & addPath>
		<cfset altPath = REReplace(new_("Config\Paths").viewDirectory, "[\\/ ]+$", "")
			& request.DIRECTORY_SEPARATOR & "errors" & request.DIRECTORY_SEPARATOR & addPath>

		<!--- Determine the views --->
		<cfset view = determineView(arguments.exception, path, arguments.statusCode)>
		<cfset altView = determineView(arguments.exception, altPath, arguments.statusCode)>

		<!--- Check if the view exists --->
		<cfset viewFile = "">
		<cfif is_file(path & view)>
			<cfset viewFile = path & view>
		<cfelseif is_file(altPath & altView)>
			<cfset viewFile = altPath & altView>
		</cfif>

		<!--- Displays the HTML or CLI error code. --->
		<cfset render(arguments.exception, arguments.statusCode, viewFile)>

		<!--- exit(exitCode): a request has no exit code --->
	</cffunction>

	<!---
	 * Determines the view to display based on the exception thrown, HTTP status
	 * code, whether an HTTP or CLI request, etc.
	 *
	 * @return The filename of the view file to use
	--->
	<cffunction name="determineView" access="private" returntype="string" output="no">
		<cfargument name="exception" type="any" required="yes">
		<cfargument name="templatePath" type="string" required="yes">
		<cfargument name="statusCode" type="numeric" required="no" default="500">
		<cfset var view = "">

		<!--- Production environments should have a custom exception file. --->
		<cfset view = "production.cfm">

		<cfif isDisplayErrorsEnabled()>
			<!--- If display_errors is enabled, shows the error details. --->
			<cfset view = "error_exception.cfm">
		</cfif>

		<!--- 404 Errors --->
		<cfif arguments.exception.type EQ "ColdIgniter.Exceptions.PageNotFoundException">
			<cfreturn "error_404.cfm">
		</cfif>

		<cfset arguments.templatePath = REReplace(arguments.templatePath, "[\\/ ]+$", "") & request.DIRECTORY_SEPARATOR>

		<!--- Allow for custom views based upon the status code --->
		<cfif is_file(arguments.templatePath & "error_" & arguments.statusCode & ".cfm")>
			<cfreturn "error_" & arguments.statusCode & ".cfm">
		</cfif>

		<cfreturn view>
	</cffunction>

	<cffunction name="isDisplayErrorsEnabled" access="private" returntype="boolean" output="no">
		<cfreturn in_array(LCase(ini_get("display_errors")), ListToArray("1,true,on,yes"))>
	</cffunction>

	<!---
	 * Not ported yet: sanitizeData, which makes the error data fit for
	 * the API responses.
	--->

</cfcomponent>
