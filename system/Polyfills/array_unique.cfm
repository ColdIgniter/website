<!---
 * Removes duplicate values from a list. The first of each value is kept
 * and the order stays. The comparison is exact (case-sensitive). The
 * argument is not changed. Unlike the original, the result is renumbered.
 *
 * The values that were seen are kept in a hash set, so that a value is
 * not compared with every value before it.
--->
<cffunction name="array_unique" returntype="array" output="no" hint="Removes duplicate values from a list">
	<cfargument name="array" type="array" required="yes">
	<cfset var result = ArrayNew(1)>
	<cfset var seen = CreateObject("java", "java.util.HashSet").init()>
	<cfset var i = 0>

	<cfloop from="1" to="#ArrayLen(arguments.array)#" index="i">
		<!--- add() is true when the value was not in the set yet --->
		<cfif seen.add(JavaCast("string", arguments.array[i] & ""))>
			<cfset ArrayAppend(result, arguments.array[i])>
		</cfif>
	</cfloop>

	<cfreturn result>
</cffunction>
