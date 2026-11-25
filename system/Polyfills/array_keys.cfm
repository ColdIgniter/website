<!---
 * Returns the keys of a map (see array_()) as a list, in their order.
 *
 * Difference: only a map (a java.util.Map) is handled, the key type
 * is always a string, and the search arguments are not supported.
--->
<cffunction name="array_keys" returntype="array" output="no" hint="Returns all the keys of a map">
	<cfargument name="array" type="any" required="yes">
	<cfset var result = ArrayNew(1)>
	<cfset var keys = CreateObject("java", "java.util.ArrayList").init(arguments.array.keySet())>
	<cfset var i = 0>

	<cfloop from="0" to="#keys.size() - 1#" index="i">
		<cfset ArrayAppend(result, keys.get(JavaCast("int", i)))>
	</cfloop>

	<cfreturn result>
</cffunction>
