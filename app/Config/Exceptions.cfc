<!---
 * Setup how the exception handler works.
 *
 * Not ported yet: the type of the handler() argument and of its
 * return value (there are no interfaces), and Throwable: the
 * exception is the cfcatch struct of the caught error.
--->
<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="Setup how the exception handler works">

	<!---
	 * --------------------------------------------------------------------------
	 * LOG EXCEPTIONS?
	 * --------------------------------------------------------------------------
	 * If true, then exceptions will be logged
	 * through Services::Log.
	 *
	 * Default: true
	--->
	<cfset this.log = true>

	<!---
	 * --------------------------------------------------------------------------
	 * DO NOT LOG STATUS CODES
	 * --------------------------------------------------------------------------
	 * Any status codes here will NOT be logged if logging is turned on.
	 * By default, only 404 (Page Not Found) exceptions are ignored.
	 *
	 * @var list<int>
	--->
	<cfset this.ignoreCodes = ArrayNew(1)>
	<cfset ArrayAppend(this.ignoreCodes, 404)>

	<!---
	 * --------------------------------------------------------------------------
	 * Error Views Path
	 * --------------------------------------------------------------------------
	 * This is the path to the directory that contains the 'cli' and 'html'
	 * directories that hold the views used to generate errors.
	 *
	 * Default: APPPATH.'Views/errors'
	--->
	<cfset this.errorViewPath = request.APPPATH & "Views/errors">

	<!---
	 * --------------------------------------------------------------------------
	 * HIDE FROM DEBUG TRACE
	 * --------------------------------------------------------------------------
	 * Any data that you would like to hide from the debug trace.
	 * In order to specify 2 levels, use "/" to separate.
	 * ex. ['server', 'setup/password', 'secret_token']
	 *
	 * @var list<string>
	--->
	<cfset this.sensitiveDataInTrace = ArrayNew(1)>

	<!---
	 * --------------------------------------------------------------------------
	 * WHETHER TO THROW AN EXCEPTION ON DEPRECATED ERRORS
	 * --------------------------------------------------------------------------
	 * If set to `true`, DEPRECATED errors are only logged and no exceptions are
	 * thrown. This option also works for user deprecations.
	--->
	<cfset this.logDeprecations = true>

	<!---
	 * --------------------------------------------------------------------------
	 * LOG LEVEL THRESHOLD FOR DEPRECATIONS
	 * --------------------------------------------------------------------------
	 * If `$logDeprecations` is set to `true`, this sets the log level
	 * to which the deprecation will be logged. This should be one of the log
	 * levels recognized by PSR-3.
	 *
	 * The related `Config\Logger::$threshold` should be adjusted, if needed,
	 * to capture logging the deprecations.
	--->
	<cfset this.deprecationLogLevel = "warning">

	<!---
	 * DEFINE THE HANDLERS USED
	 * --------------------------------------------------------------------------
	 * Given the HTTP status code, returns exception handler that
	 * should be used to deal with this error. By default, it will run ColdIgniter's
	 * default handler and display the error information in the expected format
	 * for CLI, HTTP, or AJAX requests, as determined by is_cli() and the expected
	 * response format.
	 *
	 * Custom handlers can be returned if you want to handle one or more specific
	 * error codes yourself like:
	 *
	 *      <cfif in_array(statusCode, ...)>
	 *          <cfreturn new_("App\Libraries\MyExceptionHandler")>
	 *      </cfif>
	 *      <cfif exception.type EQ "ColdIgniter.Exceptions.PageNotFoundException">
	 *          <cfreturn new_("App\Libraries\MyExceptionHandler")>
	 *      </cfif>
	--->
	<cffunction name="handler" access="public" returntype="any" output="no">
		<cfargument name="statusCode" type="numeric" required="yes">
		<cfargument name="exception" type="any" required="yes">

		<cfreturn new_("ColdIgniter\Debug\ExceptionHandler", this)>
	</cffunction>

</cfcomponent>
