<!---
 * Returns the state of the session engine for this request.
 *
 * Difference: there is no engine under CFML that keeps a session (the built
 * in session scope stays off), so the session_* functions of this folder
 * play it. This is its state: status ("none" or "active", as the constants
 * of the original cannot be named), id, handler (the save handler), and
 * data, a map with the case of the keys kept that stands in for the
 * superglobal that holds the session data. It is created when first asked
 * for, so a request that never touches the session has no session at all.
--->
<cffunction name="session_state" returntype="any" output="no" hint="Returns the state of the session engine for this request">
	<cfif NOT StructKeyExists(request.ColdIgniter, "session")>
		<cfset request.ColdIgniter.session = StructNew()>
		<cfset request.ColdIgniter.session.status = "none">
		<cfset request.ColdIgniter.session.id = "">
		<cfset request.ColdIgniter.session.handler = "">
		<cfset request.ColdIgniter.session.data = CreateObject("java", "java.util.LinkedHashMap").init()>
	</cfif>

	<cfreturn request.ColdIgniter.session>
</cffunction>
