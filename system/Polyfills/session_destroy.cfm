<!---
 * Destroys the data of the active session through the save handler. The
 * data in memory stays, as upstream, and nothing is written at the end.
--->
<cffunction name="session_destroy" returntype="boolean" output="no" hint="Destroys all data registered to a session">
	<cfset var state = session_state()>

	<cfif state.status NEQ "active">
		<cfreturn false>
	</cfif>

	<cfset state.handler.destroy(state.id)>
	<cfset state.handler.close()>
	<cfset state.status = "none">

	<cfreturn true>
</cffunction>
