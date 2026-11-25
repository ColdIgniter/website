<!---
 * Writes the session data and ends the session. It does nothing when no
 * session is active, so a request that never started one writes nothing.
--->
<cffunction name="session_write_close" returntype="boolean" output="no" hint="Writes the session data and ends the session">
	<cfset var state = session_state()>
	<cfset var packet = "">

	<cfif state.status NEQ "active">
		<cfreturn false>
	</cfif>

	<!--- the status goes first, so an error below cannot loop back here --->
	<cfset state.status = "none">
	<cfwddx action="cfml2wddx" input="#state.data#" output="packet">
	<cfset state.handler.write(state.id, packet)>
	<cfset state.handler.close()>

	<cfreturn true>
</cffunction>
