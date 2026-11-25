<!---
 * Gets or sets the id of the current session. An id can be set only while
 * the session is not active.
 *
 * Difference: session_start() ignores an id set here and always takes the id
 * from the cookie or creates a new one, so a caller cannot make the session
 * adopt an id of its own.
--->
<cffunction name="session_id" returntype="string" output="no" hint="Gets or sets the session id">
	<cfargument name="id" type="string" required="no" default="">

	<cfif Len(arguments.id) AND session_state().status NEQ "active">
		<cfset session_state().id = arguments.id>
	</cfif>

	<cfreturn session_state().id>
</cffunction>
