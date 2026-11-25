<!---
 * Session handler for MySQLi
 *
 * Difference: the original extends DatabaseHandler. This class is in
 * another folder, so it is mixed in with parent (see the reference, "How
 * components are located").
 *
 * Difference: a row is a map, so the column is row["ci_session_lock"].
--->
<cfcomponent output="no" parent="ColdIgniter\Session\Handlers\DatabaseHandler" hint="Session handler for MySQLi">

	<!---
	 * Lock the session.
	--->
	<cffunction name="lockSession" access="private" returntype="boolean" output="no">
		<cfargument name="sessionID" type="string" required="yes">
		<cfset var arg = md5(arguments.sessionID)>
		<cfset var row = "">

		<cfif this.matchIP>
			<cfset arg = md5(arguments.sessionID & "_" & this.ipAddress)>
		</cfif>

		<cfset row = this.db.query("SELECT GET_LOCK('#arg#', 300) AS ci_session_lock").getRow()>

		<cfif NOT is_null(row) AND Val(row["ci_session_lock"]) NEQ 0>
			<cfset this.lock = arg>

			<cfreturn true>
		</cfif>

		<cfreturn fail()>
	</cffunction>

	<!---
	 * Releases the lock, if any.
	--->
	<cffunction name="releaseLock" access="private" returntype="boolean" output="no">
		<cfset var row = "">

		<cfif NOT hasLock_()>
			<cfreturn true>
		</cfif>

		<cfset row = this.db.query("SELECT RELEASE_LOCK('#this.lock#') AS ci_session_lock").getRow()>

		<cfif NOT is_null(row) AND Val(row["ci_session_lock"]) NEQ 0>
			<cfset this.lock = false>

			<cfreturn true>
		</cfif>

		<cfreturn fail()>
	</cffunction>

</cfcomponent>
