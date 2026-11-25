<!---
 * Class ArrayCast
 *
 * Handles converting a serialized text to and from a list or a map.
 *
 * Difference: serialize() and unserialize() are the polyfills, with their
 * own differences (an integer, a float and a string are text). Objects are
 * not ported yet in unserialize(), so the option allowed_classes does not
 * exist. The cast to array, (array) $value, gives a list: a list stays, a
 * map stays, and a scalar becomes a list with one item. The type check is
 * isSimple_() (see BaseCast).
--->
<cfcomponent output="no" extends="BaseCast" hint="Handles converting a serialized text to and from an array">

	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">
		<cfset var result = arguments.value>
		<cfset var list = "">

		<cfif NOT isSimple_(result)>
			<cfset invalidTypeValueError(result)>
		</cfif>

		<cfif str_starts_with(result, "a:") OR str_starts_with(result, "s:")>
			<cfset result = unserialize(result)>
		</cfif>

		<cfif IsArray(result) OR IsStruct(result)>
			<cfreturn result>
		</cfif>

		<cfset list = ArrayNew(1)>
		<cfset ArrayAppend(list, result)>

		<cfreturn list>
	</cffunction>

	<cffunction name="set" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfreturn serialize(arguments.value)>
	</cffunction>
</cfcomponent>
