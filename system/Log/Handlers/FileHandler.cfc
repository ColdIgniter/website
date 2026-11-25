<!---
 * Log error messages to file system
 *
 * Difference: the file is written with cffile action="append", under a
 * lock with a name, in UTF-8, without the newline that the tag adds. A
 * file or folder that cannot be written is not an error: handle() returns
 * false, as the original does when fopen() fails.
 *
 * Difference: the original puts a line that stops the script at the top of
 * a new log file with the extension of its own scripting language, which
 * is enough there because the file is never compiled again as a whole
 * once the line has run. That cannot be done here: the server compiles
 * the whole template before it runs the first tag, so a later line of the
 * log with tag-like text makes the file fail to compile, and the error
 * page shows that line (verified on the server; a first line with the
 * cfabort tag did not prevent it). A log file that the server would run
 * (the extensions cfm, cfml and cfc, in any case) cannot be protected by
 * a header, so handle() returns false for them and writes nothing.
 *
 * Difference: the extension is used as it is in the original. Here only an
 * extension of letters and digits (the whole text) is accepted, and the
 * names the server runs or treats as special (cfm, cfml, cfc, jsp, asp, exe,
 * bat, and so on, in any case) are refused. A longer extension that starts
 * with one of those names in three characters (cfmx, aspx, exe1) is refused
 * too, because the file system gives the file a second, short name that
 * ends in those three characters. Anything else makes handle()
 * return false and write nothing, so the file cannot leave the log folder
 * or change name on the way to the file system. An empty extension is the
 * default "log", as in the original.
 *
 * Not ported yet: the file permissions (chmod) of a new file.
--->
<cfcomponent output="no" extends="BaseHandler" hint="Log error messages to file system">

	<!---
	 * Folder to hold logs
	 *
	 * @var string
	--->
	<cfset this.path = "">

	<!---
	 * Extension to use for log files
	 *
	 * @var string
	--->
	<cfset this.fileExtension = "">

	<!---
	 * Permissions for new log files
	 *
	 * @var int
	--->
	<cfset this.filePermissions = 0>

	<!---
	 * @param config A map: handles, path, fileExtension, filePermissions
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfset var defaults = array_("path", request.WRITEPATH & "logs/", "fileExtension", "log", "filePermissions", 420)>

		<cfif is_null(arguments.config)>
			<cfset arguments.config = array_()>
		</cfif>

		<cfset super.__construct(arguments.config)>

		<cfset arguments.config = array_merge(defaults, arguments.config)>

		<cfif Compare(arguments.config["path"], "") EQ 0>
			<cfset this.path = defaults["path"]>
		<cfelse>
			<cfset this.path = arguments.config["path"]>
		</cfif>

		<cfif Compare(arguments.config["fileExtension"], "") EQ 0>
			<cfset this.fileExtension = defaults["fileExtension"]>
		<cfelse>
			<cfset this.fileExtension = ltrim_(arguments.config["fileExtension"], ".")>
		</cfif>

		<cfset this.filePermissions = arguments.config["filePermissions"]>

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
		<cfset var filepath = this.path & "log-" & date("Y-m-d") & "." & this.fileExtension>
		<cfset var msg = "">
		<cfset var written = true>
		<cfset var extension = LCase(this.fileExtension)>

		<!--- An extension is letters and digits only; it must not leave the log folder or change on the way to the file system --->
		<!--- Difference: a Java match of the whole text (a newline cannot fool it); the original has no such check --->
		<cfif NOT CreateObject("java", "java.lang.String").init(this.fileExtension).matches("[A-Za-z0-9]+")>
			<cfreturn false>
		</cfif>

		<!--- Files that the server runs cannot be protected with a header (see above), and some names are special to the server or the system --->
		<cfif ListFindNoCase("cfm,cfml,cfc,jsp,jws,asp,asa,cer,cdx,shtml,shtm,stm,idc,htr,htw,ida,idq,printer,exe,dll,bat,cmd,com,pl", extension) GT 0>
			<cfreturn false>
		</cfif>

		<!--- The file system also gives a long extension a short name with its first three characters (cfmx is also .CFM) --->
		<cfif Len(extension) GT 3 AND ListFindNoCase("cfm,cfc,jsp,jws,asp,asa,cer,cdx,sht,stm,idc,htr,htw,ida,idq,pri,exe,dll,bat,cmd,com", Left(extension, 3)) GT 0>
			<cfreturn false>
		</cfif>

		<cfset msg = msg & UCase(arguments.level) & " - " & date(this.dateFormat) & " --> " & arguments.message & Chr(10)>

		<cftry>
			<cflock name="ColdIgniterFileHandler" type="exclusive" timeout="10">
				<cffile action="append" file="#filepath#" output="#msg#" addnewline="no" charset="utf-8">
			</cflock>

			<cfcatch type="any">
				<cfset written = false>
			</cfcatch>
		</cftry>

		<!--- Not ported yet: chmod() of a new file with filePermissions --->

		<cfreturn written>
	</cffunction>

</cfcomponent>
