<!---
 * Class CSVCast
 *
 * Handles converting a comma separated text to and from a list.
 *
 * Difference: the type check of get() is isSimple_(), and set() takes a
 * list or a map (see BaseCast).
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting a comma separated text to and from an array">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfif NOT isSimple_(arguments.value)>
			<cfset invalidTypeValueError(arguments.value)>
		</cfif>

		<cfreturn explode(",", arguments.value)>
	</cffunction>

	<cffunction name="set" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfif NOT IsArray(arguments.value)>
			<cfset invalidTypeValueError(arguments.value)>
		</cfif>

		<cfreturn implode(",", arguments.value)>
	</cffunction>
</cfcomponent>
