<!---
 * Replaces the id of the active session with a new one and keeps the
 * data. With the flag set the old session is destroyed, otherwise it is
 * written under the old id first and left to garbage collection.
--->
<cffunction name="session_regenerate_id" returntype="boolean" output="no" hint="Replaces the session id with a newly generated one">
	<cfargument name="delete_old_session" type="boolean" required="no" default="false">
	<cfset var state = session_state()>
	<cfset var packet = "">
	<cfset var old = state.id>

	<cfif state.status NEQ "active">
		<cfreturn false>
	</cfif>

	<cfif arguments.delete_old_session>
		<cfset state.handler.destroy(old)>
	<cfelse>
		<cfwddx action="cfml2wddx" input="#state.data#" output="packet">
		<cfset state.handler.write(old, packet)>
	</cfif>

	<!--- as the original does: close the old session, open and read the new one, which takes the lock again --->
	<cfset state.handler.close()>
	<cfset state.id = session_create_id()>
	<cfset state.handler.open(ini_get("session.save_path"), ini_get("session.name"))>
	<cfset state.handler.read(state.id)>

	<cfreturn true>
</cffunction>
