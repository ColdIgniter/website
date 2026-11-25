<!---
 * Session handler using static array for storage.
 * Intended only for use during testing.
 *
 * Difference: the original keeps nothing at all, and neither does this:
 * read() returns an empty string, so every request starts without data.
--->
<cfcomponent output="no" extends="BaseHandler" hint="Session handler using static array for storage">

	<cffunction name="open" access="public" returntype="boolean" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfargument name="name" type="string" required="yes">

		<cfreturn true>
	</cffunction>

	<cffunction name="read" access="public" returntype="any" output="no">
		<cfargument name="id" type="string" required="yes">

		<cfreturn "">
	</cffunction>

	<cffunction name="write" access="public" returntype="boolean" output="no">
		<cfargument name="id" type="string" required="yes">
		<cfargument name="data" type="string" required="yes">

		<cfreturn true>
	</cffunction>

	<cffunction name="close" access="public" returntype="boolean" output="no">

		<cfreturn true>
	</cffunction>

	<cffunction name="destroy" access="public" returntype="boolean" output="no">
		<cfargument name="id" type="string" required="yes">

		<cfreturn true>
	</cffunction>

	<cffunction name="gc" access="public" returntype="any" output="no">
		<cfargument name="max_lifetime" type="numeric" required="yes">

		<cfreturn 1>
	</cffunction>

</cfcomponent>
