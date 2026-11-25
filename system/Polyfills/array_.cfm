<!---
 * Creates an array with string keys: array_(key, value, key, value, ...).
 *
 * The keys keep their order and their case, which a struct does not.
 * Read and write it with brackets only (map["key"]); a dot would
 * upper-case the key. A list with number keys is a plain ArrayNew(1).
--->
<cffunction name="array_" returntype="any" output="no" hint="Creates an array with string keys that keeps its order">
	<cfset var map = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset var i = 0>

	<cfloop from="1" to="#ArrayLen(arguments)#" index="i" step="2">
		<cfset map[arguments[i]] = arguments[i + 1]>
	</cfloop>

	<cfreturn map>
</cffunction>
