<!---
 * Dummy cache handler
 *
 * Difference: a null is an empty string, so get(), remember(),
 * getCacheInfo() and getMetaData_() return an empty string. initialize()
 * is initialize_() and getMetaData() is getMetaData_() (built-in names).
--->
<cfcomponent output="no" extends="BaseHandler" hint="Dummy cache handler">

	<!---
	 * Takes care of any handler-specific setup that must be done.
	--->
	<cffunction name="initialize_" access="public" returntype="void" output="no">
	</cffunction>

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfreturn "">
	</cffunction>

	<cffunction name="remember" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="ttl" type="numeric" required="yes">
		<cfargument name="callback" type="any" required="yes">

		<cfreturn "">
	</cffunction>

	<cffunction name="save" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="ttl" type="numeric" required="no" default="60">

		<cfreturn true>
	</cffunction>

	<cffunction name="delete" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfreturn true>
	</cffunction>

	<cffunction name="deleteMatching" access="public" returntype="numeric" output="no">
		<cfargument name="pattern" type="string" required="yes">

		<cfreturn 0>
	</cffunction>

	<cffunction name="increment" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="offset" type="numeric" required="no" default="1">

		<cfreturn true>
	</cffunction>

	<cffunction name="decrement" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="offset" type="numeric" required="no" default="1">

		<cfreturn true>
	</cffunction>

	<cffunction name="clean" access="public" returntype="boolean" output="no">
		<cfreturn true>
	</cffunction>

	<cffunction name="getCacheInfo" access="public" returntype="any" output="no">
		<cfreturn "">
	</cffunction>

	<cffunction name="getMetaData_" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfreturn "">
	</cffunction>

	<cffunction name="isSupported" access="public" returntype="boolean" output="no">
		<cfreturn true>
	</cffunction>

</cfcomponent>
