<!---
 * Modules Class
 *
 * @see https://codeigniter.com/user_guide/general/modules.html
 *
 * Not ported yet: the composer package list and __set_state.
--->
<cfcomponent output="no" hint="Modules Class">

	<!---
	 * Auto-Discover
	--->
	<cfset this.enabled = true>

	<!---
	 * Auto-Discovery Within Composer Packages
	--->
	<cfset this.discoverInComposer = true>

	<!---
	 * Auto-Discover Rules Handler
	--->
	<cfset this.aliases = ArrayNew(1)>

	<cffunction name="__construct" access="public" returntype="any" output="no">
		<!--- For @codeCoverageIgnore --->
		<cfreturn this>
	</cffunction>

	<!---
	 * Should the application auto-discover the requested resource.
	--->
	<cffunction name="shouldDiscover" access="public" returntype="boolean" output="no">
		<cfargument name="alias" type="string" required="yes">

		<cfif NOT this.enabled>
			<cfreturn false>
		</cfif>

		<cfreturn in_array(LCase(arguments.alias), this.aliases)>
	</cffunction>

</cfcomponent>
