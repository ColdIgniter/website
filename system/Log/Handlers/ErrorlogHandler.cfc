<!---
 * Log handler that writes with the cflog tag
 *
 * Difference: the original writes to error_log(). Here the message goes to
 * the cflog tag. The type TYPE_OS writes the file ColdIgniter.log in the
 * log folder of the server (one line per message, a new line in the message
 * becomes a space, and the file has the columns of the tag: severity,
 * thread, date, time, application and message). The type TYPE_SAPI writes to the
 * application log of the server. The level sets the severity: emergency,
 * alert and critical are fatal, error is error, warning and notice are
 * warning, info and debug are information.
--->
<cfcomponent output="no" extends="BaseHandler" hint="Log handler that writes with the cflog tag">

	<!---
	 * Message is sent to the log file ColdIgniter.log of the server.
	--->
	<cfset this.TYPE_OS = 0>

	<!---
	 * Message is sent to the application log of the server.
	--->
	<cfset this.TYPE_SAPI = 4>

	<!---
	 * Says where the error should go. Currently supported are
	 * 0 (`TYPE_OS`) and 4 (`TYPE_SAPI`).
	 *
	 * @var 0|4
	--->
	<cfset this.messageType = 0>

	<!---
	 * Constructor.
	 *
	 * @param config A map: handles, messageType
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfset var messageType = this.TYPE_OS>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = array_()>
		</cfif>

		<cfset super.__construct(arguments.config)>

		<cfif array_key_exists("messageType", arguments.config)>
			<cfset messageType = arguments.config["messageType"]>
		</cfif>

		<cfif NOT IsSimpleValue(messageType) OR NOT IsNumeric(messageType) OR (Compare(messageType, this.TYPE_OS) NEQ 0 AND Compare(messageType, this.TYPE_SAPI) NEQ 0)>
			<cfset static_("ColdIgniter\Log\Exceptions\LogException").forInvalidMessageType(print_r(messageType))>
		</cfif>

		<cfset this.messageType = messageType>

		<cfreturn this>
	</cffunction>

	<!---
	 * Handles logging the message.
	 * If the handler returns false, then execution of handlers
	 * will stop. Any handlers that have not run, yet, will not
	 * be run.
	 *
	 * @param level   string
	 * @param message string
	--->
	<cffunction name="handle" access="public" returntype="boolean" output="no">
		<cfargument name="level" type="string" required="yes">
		<cfargument name="message" type="string" required="yes">

		<cfset arguments.message = UCase(arguments.level) & " --> " & arguments.message & Chr(10)>

		<cfreturn errorLog(arguments.message, this.messageType, arguments.level)>
	</cffunction>

	<!---
	 * Extracted call to the log tag in order to be tested.
	 *
	 * The level is not an argument of the original, it sets the severity.
	 *
	 * @param messageType 0|4
	--->
	<cffunction name="errorLog" access="private" returntype="boolean" output="no">
		<cfargument name="message" type="string" required="yes">
		<cfargument name="messageType" type="numeric" required="yes">
		<cfargument name="level" type="string" required="yes">
		<cfset var severity = "information">
		<cfset var written = true>

		<cfif ListFind("emergency,alert,critical", arguments.level) GT 0>
			<cfset severity = "fatal">
		<cfelseif Compare(arguments.level, "error") EQ 0>
			<cfset severity = "error">
		<cfelseif ListFind("warning,notice", arguments.level) GT 0>
			<cfset severity = "warning">
		</cfif>

		<cftry>
			<cfif Compare(arguments.messageType, this.TYPE_SAPI) EQ 0>
				<cflog log="Application" type="#severity#" text="#arguments.message#">
			<cfelse>
				<cflog file="ColdIgniter" application="no" type="#severity#" text="#arguments.message#">
			</cfif>

			<cfcatch type="any">
				<cfset written = false>
			</cfcatch>
		</cftry>

		<cfreturn written>
	</cffunction>

</cfcomponent>
