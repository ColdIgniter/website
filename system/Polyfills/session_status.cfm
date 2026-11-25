<!---
 * Returns the state of the session: "active" or "none". Difference: the
 * constants of the original cannot be written here, so these are strings.
--->
<cffunction name="session_status" returntype="string" output="no" hint="Returns the state of the session">
	<cfreturn session_state().status>
</cffunction>
