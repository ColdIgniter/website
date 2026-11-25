<!---
 * Base class for logging
--->
<cfcomponent output="no" extends="HandlerInterface" hint="Base class for logging">

	<!---
	 * Handles
	 *
	 * @var list<string>
	--->
	<cfset this.handles = "">

	<!---
	 * Date format for logging
	 *
	 * @var string
	--->
	<cfset this.dateFormat = "Y-m-d H:i:s">

	<!---
	 * @param config A map: handles (a list of level names)
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">

		<cfif array_key_exists("handles", arguments.config)>
			<cfset this.handles = arguments.config["handles"]>
		<cfelse>
			<cfset this.handles = ArrayNew(1)>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Checks whether the Handler will handle logging items of this
	 * log Level.
	--->
	<cffunction name="canHandle" access="public" returntype="boolean" output="no">
		<cfargument name="level" type="string" required="yes">

		<cfreturn in_array(arguments.level, this.handles)>
	</cffunction>

	<!---
	 * Stores the date format to use while logging messages.
	--->
	<cffunction name="setDateFormat" access="public" returntype="any" output="no">
		<cfargument name="format" type="string" required="yes">

		<cfset this.dateFormat = arguments.format>

		<cfreturn this>
	</cffunction>

</cfcomponent>
