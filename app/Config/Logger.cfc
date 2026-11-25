<!---
 * Logger configuration.
 *
 * Not ported yet: the ChromeLoggerHandler (see the commented-out block
 * below).
--->
<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="Logger configuration">

	<!---
	 * --------------------------------------------------------------------------
	 * Error Logging Threshold
	 * --------------------------------------------------------------------------
	 *
	 * You can enable error logging by setting a threshold over zero. The
	 * threshold determines what gets logged. Any values below or equal to the
	 * threshold will be logged.
	 *
	 * Threshold options are:
	 *
	 * - 0 = Disables logging, Error logging TURNED OFF
	 * - 1 = Emergency Messages - System is unusable
	 * - 2 = Alert Messages - Action Must Be Taken Immediately
	 * - 3 = Critical Messages - Application component unavailable, unexpected exception.
	 * - 4 = Runtime Errors - Don't need immediate action, but should be monitored.
	 * - 5 = Warnings - Exceptional occurrences that are not errors.
	 * - 6 = Notices - Normal but significant events.
	 * - 7 = Info - Interesting events, like user logging in, etc.
	 * - 8 = Debug - Detailed debug information.
	 * - 9 = All Messages
	 *
	 * You can also pass an array with threshold levels to show individual error types
	 *
	 *     array(1, 2, 3, 8) = Emergency, Alert, Critical, and Debug messages
	 *
	 * For a live site you'll usually enable Critical or higher (3) to be logged otherwise
	 * your log files will fill up very fast.
	 *
	 * @var int|list<int>
	--->
	<cfif Compare(request.ENVIRONMENT, "production") EQ 0>
		<cfset this.threshold = 4>
	<cfelse>
		<cfset this.threshold = 9>
	</cfif>

	<!---
	 * --------------------------------------------------------------------------
	 * Date Format for Logs
	 * --------------------------------------------------------------------------
	 *
	 * Each item that is logged has an associated date. You can use the
	 * date() letters of the original to set your own date formatting
	 * (see Polyfills/date.cfm for the letters that are supported)
	--->
	<cfset this.dateFormat = "Y-m-d H:i:s">

	<!---
	 * --------------------------------------------------------------------------
	 * Log Handlers
	 * --------------------------------------------------------------------------
	 *
	 * The logging system supports multiple actions to be taken when something
	 * is logged. This is done by allowing for multiple Handlers, special classes
	 * designed to write the log to their chosen destinations, whether that is
	 * a file on the getServer, a cloud-based service, or even taking actions such
	 * as emailing the dev team.
	 *
	 * Each handler is defined by the class name used for that handler, and it
	 * MUST implement the `ColdIgniter\Log\Handlers\HandlerInterface` interface.
	 *
	 * The value of each key is a map of configuration items that are sent
	 * to the constructor of each handler. The only required configuration item
	 * is the 'handles' element, which must be a list of log level names.
	 *
	 * Handlers are executed in the order defined in this map, starting with
	 * the handler on top and continuing down.
	 *
	 * @var map of the class name to a map of configuration items
	--->
	<cfset this.handlers = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * --------------------------------------------------------------------
	 * File Handler
	 * --------------------------------------------------------------------
	--->
	<cfset this.handlers["ColdIgniter\Log\Handlers\FileHandler"] = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!--- The log levels that this handler will handle. --->
	<cfset this.handlers["ColdIgniter\Log\Handlers\FileHandler"]["handles"] = ArrayNew(1)>
	<cfset ArrayAppend(this.handlers["ColdIgniter\Log\Handlers\FileHandler"]["handles"], "critical")>
	<cfset ArrayAppend(this.handlers["ColdIgniter\Log\Handlers\FileHandler"]["handles"], "alert")>
	<cfset ArrayAppend(this.handlers["ColdIgniter\Log\Handlers\FileHandler"]["handles"], "emergency")>
	<cfset ArrayAppend(this.handlers["ColdIgniter\Log\Handlers\FileHandler"]["handles"], "debug")>
	<cfset ArrayAppend(this.handlers["ColdIgniter\Log\Handlers\FileHandler"]["handles"], "error")>
	<cfset ArrayAppend(this.handlers["ColdIgniter\Log\Handlers\FileHandler"]["handles"], "info")>
	<cfset ArrayAppend(this.handlers["ColdIgniter\Log\Handlers\FileHandler"]["handles"], "notice")>
	<cfset ArrayAppend(this.handlers["ColdIgniter\Log\Handlers\FileHandler"]["handles"], "warning")>

	<!---
	 * The default filename extension for log files.
	 *
	 * NOTE: Leaving it blank will default to 'log'.
	 *
	 * Difference: the original puts a protecting header into a new log file
	 * with the extension of its scripting language. Here "cfm" and "cfml"
	 * get a first line with the cfabort tag, and "cfc" is refused (nothing
	 * is written). The writable folder is not under the web root, so
	 * keep a plain extension.
	--->
	<cfset this.handlers["ColdIgniter\Log\Handlers\FileHandler"]["fileExtension"] = "">

	<!---
	 * The file system permissions to be applied on newly created log files.
	 *
	 * Not ported yet: the permissions are not applied (the file system of
	 * the server has no such modes). The value is kept as it is in the
	 * original, 0644 in octal notation, which is 420.
	--->
	<cfset this.handlers["ColdIgniter\Log\Handlers\FileHandler"]["filePermissions"] = 420>

	<!---
	 * Logging Directory Path
	 *
	 * By default, logs are written to WRITEPATH . 'logs/'
	 * Specify a different destination here, if desired.
	--->
	<cfset this.handlers["ColdIgniter\Log\Handlers\FileHandler"]["path"] = "">

	<!---
	 * The ChromeLoggerHandler requires the use of the Chrome web browser
	 * and the ChromeLogger extension.
	 *
	 * Not ported yet: the ChromeLoggerHandler
	--->

	<!---
	 * The ErrorlogHandler writes the logs with the cflog tag. Uncomment
	 * this block to use it.
	 *
	 *     <cfset this.handlers["ColdIgniter\Log\Handlers\ErrorlogHandler"] = CreateObject("java", "java.util.LinkedHashMap").init()>
	 *
	 *     The log levels this handler can handle.
	 *     <cfset this.handlers["ColdIgniter\Log\Handlers\ErrorlogHandler"]["handles"] = ...>
	 *
	 *     The message type where the error should go. Can be 0 or 4, or use the
	 *     class constants: `ErrorlogHandler::TYPE_OS` (0) or `ErrorlogHandler::TYPE_SAPI` (4)
	 *     <cfset this.handlers["ColdIgniter\Log\Handlers\ErrorlogHandler"]["messageType"] = 0>
	--->

</cfcomponent>
