<!---
 * Stands in for the operator "===": identical_(a, b).
 *
 * There is no difference between an int and a string here, so two simple
 * values are identical when their text is the same, exactly (case-sensitive).
 * Two lists are identical when each pair of items is. Two maps are identical
 * when they have the same keys with identical values.
 *
 * Difference: the order of the keys of a map is not compared.
--->
<cffunction name="identical_" returntype="boolean" output="no" hint="Stands in for the operator ===">
	<cfargument name="a" type="any" required="yes">
	<cfargument name="b" type="any" required="yes">
	<cfset var key = "">
	<cfset var i = 0>

	<cfif IsSimpleValue(arguments.a) AND IsSimpleValue(arguments.b)>
		<cfreturn Compare(arguments.a, arguments.b) EQ 0>
	</cfif>

	<cfif IsArray(arguments.a) AND IsArray(arguments.b)>
		<cfif ArrayLen(arguments.a) NEQ ArrayLen(arguments.b)>
			<cfreturn false>
		</cfif>

		<cfloop from="1" to="#ArrayLen(arguments.a)#" index="i">
			<cfif NOT identical_(arguments.a[i], arguments.b[i])>
				<cfreturn false>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cfif>

	<cfif IsStruct(arguments.a) AND IsStruct(arguments.b)>
		<cfif StructCount(arguments.a) NEQ StructCount(arguments.b)>
			<cfreturn false>
		</cfif>

		<cfloop collection="#arguments.a#" item="key">
			<cfif NOT StructKeyExists(arguments.b, key)>
				<cfreturn false>
			</cfif>

			<cfif NOT identical_(arguments.a[key], arguments.b[key])>
				<cfreturn false>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cfif>

	<cfreturn false>
</cffunction>
