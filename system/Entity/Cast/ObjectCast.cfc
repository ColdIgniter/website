<!---
 * Class ObjectCast
 *
 * Handles converting a value to an object.
 *
 * Difference: there is no stdClass, so an object is a map (see array_()).
 * A map stays, a list becomes a map with the keys "0", "1" and so on, and a
 * scalar becomes a map with the one key "scalar", as (object) does. A null
 * (an empty string) gives an empty map.
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting a value to an object">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">
		<cfset var result = array_()>
		<cfset var i = 0>

		<cfif IsObject(arguments.value)>
			<cfreturn arguments.value>
		</cfif>

		<cfif IsStruct(arguments.value)>
			<cfreturn arguments.value>
		</cfif>

		<cfif IsArray(arguments.value)>
			<cfloop from="1" to="#ArrayLen(arguments.value)#" index="i">
				<cfset result[i - 1 & ""] = arguments.value[i]>
			</cfloop>

			<cfreturn result>
		</cfif>

		<cfif NOT is_null(arguments.value)>
			<cfset result["scalar"] = arguments.value>
		</cfif>

		<cfreturn result>
	</cffunction>
</cfcomponent>
