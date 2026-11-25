<!---
 * Starts the session: reads the cookie, checks the id, opens and reads
 * through the save handler and fills the session data.
 *
 * It follows the strict mode of the original: an id from the cookie is
 * used only when the whole text is a 32 character lower case hexadecimal
 * string (checked with String.matches) and the handler has data for it,
 * otherwise a new id is made. So an id that was invented, has expired or
 * is not an id never reaches a file name and is never adopted.
 *
 * Difference: the engine of the original sends the session cookie. Here
 * it does not, Session.setCookie puts it on the response. The data is kept
 * as a WDDX packet, which turns a number into a string.
--->
<cffunction name="session_start" returntype="boolean" output="no" hint="Starts a session">
	<cfset var state = session_state()>
	<cfset var name = ini_get("session.name")>
	<cfset var cookie_ = service("superglobals").cookie(name)>
	<cfset var id = "">
	<cfset var raw = "">
	<cfset var data = "">
	<cfset var maxlifetime = ini_get("session.gc_maxlifetime")>
	<cfset var probability = ini_get("session.gc_probability")>
	<cfset var divisor = ini_get("session.gc_divisor")>

	<cfif state.status EQ "active" OR NOT IsObject(state.handler)>
		<cfreturn false>
	</cfif>

	<cfif NOT Len(maxlifetime)>
		<cfset maxlifetime = 1440>
	</cfif>
	<cfif NOT Len(probability)>
		<cfset probability = 1>
	</cfif>
	<cfif NOT Len(divisor)>
		<cfset divisor = 100>
	</cfif>

	<cfset state.handler.open(ini_get("session.save_path"), name)>

	<!--- the whole text has to match, so it can never be a path --->
	<cfif IsSimpleValue(cookie_) AND CreateObject("java", "java.lang.String").init(cookie_).matches("[0-9a-f]{32}")>
		<cfset id = cookie_>
		<cfset raw = state.handler.read(id)>

		<cfif NOT Len(raw)>
			<cfset id = "">
		</cfif>
	</cfif>

	<cfset state.data = CreateObject("java", "java.util.LinkedHashMap").init()>

	<cfif Len(id)>
		<cfwddx action="wddx2cfml" input="#raw#" output="data">
		<cfif IsStruct(data)>
			<cfset state.data = data>
		</cfif>
	<cfelse>
		<cfset id = session_create_id()>

		<!--- as the original does, the handler reads the new id, which takes the lock of a database handler --->
		<cfset state.handler.read(id)>
	</cfif>

	<cfset state.id = id>
	<cfset state.status = "active">

	<cfif RandRange(1, divisor) LTE probability>
		<cfset state.handler.gc(maxlifetime)>
	</cfif>

	<cfreturn true>
</cffunction>
