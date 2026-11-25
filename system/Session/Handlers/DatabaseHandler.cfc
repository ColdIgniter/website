<!---
 * Base database session handler.
 *
 * Do not use this class. Use database specific handler class.
 *
 * Difference: the platform handlers (Handlers/Database) are in another
 * folder, so they are mixed in with parent (see the reference, "How
 * components are located"). A mixed-in function has no super, so
 * __construct() calls configure_() of BaseHandler in place of
 * super.__construct(), and releaseLock() does the work of the base one
 * itself.
 *
 * Difference: a lock is false, true (the base lock) or a text (the name of
 * the lock of MySQLi and Postgre), and a text cannot be tested by itself,
 * so hasLock_() tells whether a lock is held.
 *
 * Difference: rows are maps (a column is row["data"]), and a row that does
 * not exist is an empty string. A call that fails returns the text "false"
 * (see identical_()) when the DBDebug setting is off, and throws a
 * DatabaseException when it is on.
 *
 * Difference: the timestamp is set by nowSql(), as the function that tells
 * the time depends on the platform. The original always writes now().
--->
<cfcomponent output="no" extends="BaseHandler" hint="Base database session handler">

	<!---
	 * The database group to use for storage.
	 *
	 * @var string
	--->
	<cfset this.DBGroup = "">

	<!---
	 * The name of the table to store session info.
	 *
	 * @var string
	--->
	<cfset this.table = "">

	<!---
	 * The DB Connection instance.
	 *
	 * @var BaseConnection
	--->
	<cfset this.db = "">

	<!---
	 * The database type.
	 *
	 * @var string
	--->
	<cfset this.platform = "">

	<!---
	 * Row exists flag.
	 *
	 * @var bool
	--->
	<cfset this.rowExists = false>

	<!---
	 * ID prefix for multiple session cookies.
	 *
	 * @var string
	--->
	<cfset this.idPrefix = "">

	<!---
	 * @param config    The session configuration (Config\Session)
	 * @param ipAddress The IP address of the client
	 *
	 * @throws SessionException
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfargument name="ipAddress" type="string" required="yes">

		<cfset configure_(arguments.config, arguments.ipAddress)>

		<cfset this.table = this.savePath>

		<cfif Compare(this.table, "") EQ 0>
			<cfset static_("ColdIgniter\Session\Exceptions\SessionException").forMissingDatabaseTable()>
		</cfif>

		<!--- Store Session configurations --->
		<cfset this.DBGroup = arguments.config.DBGroup>

		<cfif is_null(this.DBGroup)>
			<cfset this.DBGroup = variables.config("Config\Database").defaultGroup>
		</cfif>

		<!--- Add session cookie name for multiple session cookies. --->
		<cfset this.idPrefix = arguments.config.cookieName & ":">
		<cfset this.db = db_connect(this.DBGroup)>
		<cfset this.platform = this.db.getPlatform()>

		<cfreturn this>
	</cffunction>

	<!---
	 * Re-initialize existing session, or creates a new one.
	 *
	 * @param path The path where to store/retrieve the session
	 * @param name The session name
	--->
	<cffunction name="open" access="public" returntype="boolean" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfargument name="name" type="string" required="yes">

		<cfif identical_(this.db.connID, "false")>
			<cfset this.db.initialize_()>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!---
	 * Reads the session data from the session storage, and returns the results.
	 *
	 * @param id The session ID
	 *
	 * @return false|string
	--->
	<cffunction name="read" access="public" returntype="any" output="no">
		<cfargument name="id" type="string" required="yes">
		<cfset var builder = "">
		<cfset var result = "">

		<cfif NOT lockSession(arguments.id)>
			<cfset this.fingerprint = md5("")>

			<cfreturn "">
		</cfif>

		<cfif is_null(this.sessionID)>
			<cfset this.sessionID = arguments.id>
		</cfif>

		<cfset builder = this.db.table(this.table).where("id", this.idPrefix & arguments.id)>

		<cfif this.matchIP>
			<cfset builder = builder.where("ip_address", this.ipAddress)>
		</cfif>

		<cfset setSelect(builder)>

		<cfset result = builder.get().getRow()>

		<cfif is_null(result)>
			<!---
			 * The same handler object is reused after ID regeneration,
			 * so we need to explicitly set this to FALSE instead of
			 * relying on the default ...
			--->
			<cfset this.rowExists = false>
			<cfset this.fingerprint = md5("")>

			<cfreturn "">
		</cfif>

		<cfset result = decodeData(result["data"])>

		<cfset this.fingerprint = md5(result)>
		<cfset this.rowExists = true>

		<cfreturn result>
	</cffunction>

	<!---
	 * Sets SELECT clause.
	--->
	<cffunction name="setSelect" access="private" returntype="void" output="no">
		<cfargument name="builder" type="any" required="yes">

		<cfset arguments.builder.select("data")>
	</cffunction>

	<!---
	 * Decodes column data.
	 *
	 * @param data
	 *
	 * @return false|string
	--->
	<cffunction name="decodeData" access="private" returntype="any" output="no">
		<cfargument name="data" type="any" required="yes">

		<cfreturn arguments.data>
	</cffunction>

	<!---
	 * The SQL that gives the time now, for the timestamp column.
	 *
	 * Not in the original (see the header).
	--->
	<cffunction name="nowSql" access="private" returntype="string" output="no">

		<cfreturn "now()">
	</cffunction>

	<!---
	 * Tells whether a lock is held (see the header).
	--->
	<cffunction name="hasLock_" access="private" returntype="boolean" output="no">

		<cfif IsBoolean(this.lock) AND NOT IsNumeric(this.lock)>
			<cfreturn this.lock>
		</cfif>

		<cfreturn Len(this.lock) GT 0>
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
		<cfset var insertData = "">
		<cfset var builder = "">
		<cfset var updateData = "">
		<cfset var changed = false>

		<cfif NOT hasLock_()>
			<cfreturn fail()>
		</cfif>

		<cfif Compare(this.sessionID, arguments.id) NEQ 0>
			<cfset this.rowExists = false>
			<cfset this.sessionID = arguments.id>
		</cfif>

		<cfif NOT this.rowExists>
			<cfset insertData = array_("id", this.idPrefix & arguments.id, "ip_address", this.ipAddress, "data", prepareData(arguments.data))>

			<cfif identical_(this.db.table(this.table).set("timestamp", nowSql(), false).insert_(insertData), "false")>
				<cfreturn fail()>
			</cfif>

			<cfset this.fingerprint = md5(arguments.data)>
			<cfset this.rowExists = true>

			<cfreturn true>
		</cfif>

		<cfset builder = this.db.table(this.table).where("id", this.idPrefix & arguments.id)>

		<cfif this.matchIP>
			<cfset builder = builder.where("ip_address", this.ipAddress)>
		</cfif>

		<cfset updateData = array_()>

		<cfif Compare(this.fingerprint, md5(arguments.data)) NEQ 0>
			<cfset updateData["data"] = prepareData(arguments.data)>
			<cfset changed = true>
		</cfif>

		<cfset builder.set("timestamp", nowSql(), false)>

		<!--- Difference: an empty map is not passed to update(), which is the same as no argument --->
		<cfif changed>
			<cfif NOT builder.update(updateData)>
				<cfreturn fail()>
			</cfif>
		<cfelseif NOT builder.update()>
			<cfreturn fail()>
		</cfif>

		<cfset this.fingerprint = md5(arguments.data)>

		<cfreturn true>
	</cffunction>

	<!---
	 * Prepare data to insert/update.
	--->
	<cffunction name="prepareData" access="private" returntype="string" output="no">
		<cfargument name="data" type="string" required="yes">

		<cfreturn arguments.data>
	</cffunction>

	<!---
	 * Closes the current session.
	--->
	<cffunction name="close" access="public" returntype="boolean" output="no">

		<cfif hasLock_() AND NOT releaseLock()>
			<cfreturn fail()>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!---
	 * Destroys a session.
	 *
	 * @param id The session ID being destroyed.
	--->
	<cffunction name="destroy" access="public" returntype="boolean" output="no">
		<cfargument name="id" type="string" required="yes">
		<cfset var builder = "">

		<cfif hasLock_()>
			<cfset builder = this.db.table(this.table).where("id", this.idPrefix & arguments.id)>

			<cfif this.matchIP>
				<cfset builder = builder.where("ip_address", this.ipAddress)>
			</cfif>

			<cfif identical_(builder.delete(), "false")>
				<cfreturn fail()>
			</cfif>
		</cfif>

		<cfif close()>
			<cfset destroyCookie()>

			<cfreturn true>
		</cfif>

		<cfreturn fail()>
	</cffunction>

	<!---
	 * Cleans up expired sessions.
	 *
	 * @param max_lifetime Sessions that have not updated
	 *                     for the last max_lifetime seconds will be removed.
	 *
	 * @return false|int Returns the number of deleted sessions on success, or false on failure.
	--->
	<cffunction name="gc" access="public" returntype="any" output="no">
		<cfargument name="max_lifetime" type="numeric" required="yes">

		<cfif identical_(this.db.table(this.table).where("timestamp <", "now() - INTERVAL #arguments.max_lifetime# second", false).delete(), "false")>
			<cfreturn fail()>
		</cfif>

		<cfreturn 1>
	</cffunction>

	<!---
	 * Releases the lock, if any.
	--->
	<cffunction name="releaseLock" access="private" returntype="boolean" output="no">

		<cfif NOT hasLock_()>
			<cfreturn true>
		</cfif>

		<!--- Unsupported DB? Let the parent handle the simple version (what the one of BaseHandler does, see the header). --->
		<cfset this.lock = false>

		<cfreturn true>
	</cffunction>

</cfcomponent>
