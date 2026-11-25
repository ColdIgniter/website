<!---
 * Sets the user-level session storage functions: a handler component that
 * has open, read, write, close, destroy and gc.
--->
<cffunction name="session_set_save_handler" returntype="boolean" output="no" hint="Sets the session storage handler">
	<cfargument name="handler" type="any" required="yes">

	<cfif session_state().status EQ "active">
		<cfreturn false>
	</cfif>

	<cfset session_state().handler = arguments.handler>

	<cfreturn true>
</cffunction>
