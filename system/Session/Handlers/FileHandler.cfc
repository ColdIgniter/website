<!---
 * Session handler using file system for storage.
 *
 * Difference: the original opens the file once, takes an exclusive lock on
 * it in read() and holds it until close(), so a second request for the same
 * session waits. The server has no flock, and a named lock held for the
 * whole request would also queue every request of a visitor, so here the
 * file is read under a short exclusive named lock (cflock, named after the
 * session ID) and written under another one. There is no file handle: the
 * property fileHandle is left out. Two requests that write at the same
 * time never corrupt the file (the writes are taken in turn), but the last
 * write wins and may drop what the other one wrote: a lost update, as with
 * any session store without a lock held for the request.
 *
 * Difference: an ID is used in a file name only when the whole text matches
 * the session ID regex (checked with a Java String.matches), in read(),
 * write() and destroy(). The file name is the session name, the optional
 * md5 of the IP address and the ID, and nothing else.
 *
 * Difference: read() does not create the file for an unknown ID (write()
 * does), and a file that has not been touched for longer than
 * session.gc_maxlifetime is deleted and read as new data, so an expired
 * ID is not used again even before the garbage collector reaches it. The
 * file times come from java.io.File.
 *
 * Difference: the data is a WDDX packet (see session_write_close), read and
 * written in UTF-8.
 *
 * Not ported yet: the permissions (chmod) of a new file.
--->
<cfcomponent output="no" extends="BaseHandler" hint="Session handler using file system for storage">

	<!---
	 * Where to save the session files to.
	 *
	 * @var string
	--->
	<cfset this.savePath = "">

	<!---
	 * File Name.
	 *
	 * @var string
	--->
	<cfset this.filePath = "">

	<!---
	 * Whether this is a new file.
	 *
	 * @var bool
	--->
	<cfset this.fileNew = false>

	<!---
	 * Whether IP addresses should be matched.
	 *
	 * @var bool
	--->
	<cfset this.matchIP = false>

	<!---
	 * Regex of session ID.
	 *
	 * @var string
	--->
	<cfset this.sessionIDRegex = "">

	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfargument name="ipAddress" type="string" required="yes">
		<cfset var sessionPath = "">

		<cfset super.__construct(arguments.config, arguments.ipAddress)>

		<cfif IsSimpleValue(this.savePath) AND Compare(this.savePath, "") NEQ 0>
			<cfset this.savePath = rtrim_(this.savePath, "/\")>
			<cfset ini_set("session.save_path", this.savePath)>
		<cfelse>
			<cfset sessionPath = rtrim_(ini_get("session.save_path"), "/\")>

			<cfif Compare(sessionPath, "") EQ 0>
				<cfset sessionPath = request.WRITEPATH & "session">
			</cfif>

			<cfset this.savePath = sessionPath>
		</cfif>

		<cfset configureSessionIDRegex()>

		<cfreturn this>
	</cffunction>

	<!---
	 * Re-initialize existing session, or creates a new one.
	 *
	 * @param path The path where to store/retrieve the session.
	 * @param name The session name.
	 *
	 * @throws SessionException
	--->
	<cffunction name="open" access="public" returntype="boolean" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfargument name="name" type="string" required="yes">
		<cfset var dir = CreateObject("java", "java.io.File").init(arguments.path)>

		<cfif NOT dir.isDirectory() AND NOT dir.mkdirs()>
			<cfset static_("ColdIgniter\Session\Exceptions\SessionException").forInvalidSavePath(this.savePath)>
		</cfif>

		<cfif NOT dir.canWrite()>
			<cfset static_("ColdIgniter\Session\Exceptions\SessionException").forWriteProtectedSavePath(this.savePath)>
		</cfif>

		<cfset this.savePath = arguments.path>

		<!--- we'll use the session name as prefix to avoid collisions --->
		<cfif this.matchIP>
			<cfset this.filePath = this.savePath & "/" & arguments.name & LCase(Hash(this.ipAddress))>
		<cfelse>
			<cfset this.filePath = this.savePath & "/" & arguments.name>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!---
	 * Reads the session data from the session storage, and returns the results.
	 *
	 * @param id The session ID.
	--->
	<cffunction name="read" access="public" returntype="any" output="no">
		<cfargument name="id" type="string" required="yes">
		<cfset var data = "">
		<cfset var file_ = "">
		<cfset var maxlifetime = ini_get("session.gc_maxlifetime")>

		<cfif NOT validId(arguments.id)>
			<cfreturn "">
		</cfif>

		<cfif NOT Len(maxlifetime)>
			<cfset maxlifetime = 1440>
		</cfif>

		<cfset file_ = CreateObject("java", "java.io.File").init(this.filePath & arguments.id)>

		<cflock name="ColdIgniterSession#arguments.id#" type="exclusive" timeout="10">
			<cfset this.fileNew = NOT file_.isFile()>

			<!--- an expired file is not data any more --->
			<cfif NOT this.fileNew AND file_.lastModified() LT (time() - maxlifetime) * 1000>
				<cfset file_.delete()>
				<cfset this.fileNew = true>
			</cfif>

			<cfif NOT this.fileNew>
				<cffile action="read" file="#this.filePath##arguments.id#" variable="data" charset="utf-8">
			</cfif>
		</cflock>

		<cfif Compare(this.sessionID, "") EQ 0>
			<cfset this.sessionID = arguments.id>
		</cfif>

		<cfset this.fingerprint = LCase(Hash(data))>

		<cfreturn data>
	</cffunction>

	<!---
	 * Writes the session data to the session storage.
	 *
	 * @param id   The session ID.
	 * @param data The encoded session data.
	--->
	<cffunction name="write" access="public" returntype="boolean" output="no">
		<cfargument name="id" type="string" required="yes">
		<cfargument name="data" type="string" required="yes">
		<cfset var file_ = "">
		<cfset var stamp = "">

		<!--- If the two IDs don't match, we have a session_regenerate_id() call --->
		<cfif Compare(arguments.id, this.sessionID) NEQ 0>
			<cfset this.sessionID = arguments.id>
			<cfset this.fileNew = true>
			<cfset this.fingerprint = "">
		</cfif>

		<cfif NOT validId(arguments.id)>
			<cfreturn false>
		</cfif>

		<cfset file_ = CreateObject("java", "java.io.File").init(this.filePath & arguments.id)>

		<cfif Compare(this.fingerprint, LCase(Hash(arguments.data))) EQ 0>
			<cfif this.fileNew>
				<cfreturn true>
			</cfif>

			<cfset stamp = CreateObject("java", "java.lang.Long").parseLong(JavaCast("string", Int(time()) & "000"))>

			<cflock name="ColdIgniterSession#arguments.id#" type="exclusive" timeout="10">
				<cfset file_.setLastModified(stamp)>
			</cflock>

			<cfreturn true>
		</cfif>

		<cftry>
			<cflock name="ColdIgniterSession#arguments.id#" type="exclusive" timeout="10">
				<cffile action="write" file="#this.filePath##arguments.id#" output="#arguments.data#" addnewline="no" charset="utf-8">
			</cflock>

			<cfcatch type="any">
				<cfset this.logger.error("Session: Unable to write data.")>

				<cfreturn false>
			</cfcatch>
		</cftry>

		<cfset this.fingerprint = LCase(Hash(arguments.data))>
		<cfset this.fileNew = false>

		<cfreturn true>
	</cffunction>

	<!---
	 * Closes the current session.
	--->
	<cffunction name="close" access="public" returntype="boolean" output="no">

		<cfset this.fileNew = false>

		<cfreturn true>
	</cffunction>

	<!---
	 * Destroys a session.
	 *
	 * @param id The session ID being destroyed.
	--->
	<cffunction name="destroy" access="public" returntype="boolean" output="no">
		<cfargument name="id" type="string" required="yes">
		<cfset var file_ = "">

		<cfif NOT validId(arguments.id)>
			<cfreturn false>
		</cfif>

		<cfset close()>

		<cfset file_ = CreateObject("java", "java.io.File").init(this.filePath & arguments.id)>

		<cflock name="ColdIgniterSession#arguments.id#" type="exclusive" timeout="10">
			<cfif file_.isFile()>
				<cfif NOT file_.delete()>
					<cfreturn false>
				</cfif>
			</cfif>
		</cflock>

		<cfreturn destroyCookie()>
	</cffunction>

	<!---
	 * Cleans up expired sessions.
	 *
	 * @param max_lifetime Sessions that have not updated
	 *                     for the last max_lifetime seconds will be removed.
	--->
	<cffunction name="gc" access="public" returntype="any" output="no">
		<cfargument name="max_lifetime" type="numeric" required="yes">
		<cfset var directory = CreateObject("java", "java.io.File").init(this.savePath)>
		<cfset var files = "">
		<cfset var ts = (time() - arguments.max_lifetime) * 1000>
		<cfset var pattern = "">
		<cfset var collected = 0>
		<cfset var i = 0>
		<cfset var name = "">
		<cfset var entry = "">
		<cfset var quoted = "">
		<cfset var ch = "">

		<cfif NOT directory.isDirectory()>
			<cfset this.logger.debug("Session: Garbage collector couldn't list files under directory '" & this.savePath & "'.")>

			<cfreturn false>
		</cfif>

		<cfset files = directory.list()>

		<cfif NOT IsDefined("files")>
			<cfset this.logger.debug("Session: Garbage collector couldn't list files under directory '" & this.savePath & "'.")>

			<cfreturn false>
		</cfif>

		<cfif this.matchIP EQ true>
			<cfset pattern = "[0-9a-f]{32}">
		</cfif>

		<!--- Difference: preg_quote(); Pattern.quote() is not in the Java of the server, so every character that is not a letter, a digit or an underscore gets a backslash --->
		<cfloop from="1" to="#Len(this.cookieName)#" index="i">
			<cfset ch = Mid(this.cookieName, i, 1)>

			<cfif REFind("[A-Za-z0-9_]", ch)>
				<cfset quoted = quoted & ch>
			<cfelse>
				<cfset quoted = quoted & "\" & ch>
			</cfif>
		</cfloop>

		<cfset pattern = quoted & pattern & this.sessionIDRegex>

		<cfloop index="i" from="1" to="#ArrayLen(files)#">
			<cfset name = files[i]>

			<!--- If the filename doesn't match this pattern, it's either not a session file or is not ours --->
			<cfif CreateObject("java", "java.lang.String").init(name).matches(pattern)>
				<cfset entry = CreateObject("java", "java.io.File").init(this.savePath & "/" & name)>

				<cfif entry.isFile() AND entry.lastModified() LTE ts>
					<cfif entry.delete()>
						<cfset collected = collected + 1>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn collected>
	</cffunction>

	<!---
	 * Configure Session ID regular expression. To make life easier, we force the defaults.
	--->
	<cffunction name="configureSessionIDRegex" access="private" returntype="void" output="no">

		<cfif Compare(ini_get("session.sid_bits_per_character"), "4") NEQ 0>
			<cfset ini_set("session.sid_bits_per_character", "4")>
		</cfif>

		<cfif Compare(ini_get("session.sid_length"), "32") NEQ 0>
			<cfset ini_set("session.sid_length", "32")>
		</cfif>

		<cfset this.sessionIDRegex = "[0-9a-f]{32}">
	</cffunction>

	<!---
	 * Whether the whole text is a session ID (a Java match of the whole
	 * text, so a newline or a path cannot get through).
	 *
	 * Difference: the original has no such method; the engine checked the ID.
	--->
	<cffunction name="validId" access="private" returntype="boolean" output="no">
		<cfargument name="id" type="string" required="yes">

		<cfreturn CreateObject("java", "java.lang.String").init(arguments.id).matches(this.sessionIDRegex)>
	</cffunction>

</cfcomponent>
