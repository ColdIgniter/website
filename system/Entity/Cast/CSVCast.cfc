<!---
 * Class CSVCast
 *
 * Handles converting a comma separated text to and from a list.
 *
 * Difference: a null (an empty string) gives a list with one empty item, as
 * explode() does in the original.
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting a comma separated text to and from an array">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfreturn explode(",", arguments.value)>
	</cffunction>

	<cffunction name="set" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfreturn implode(",", arguments.value)>
	</cffunction>
</cfcomponent>
