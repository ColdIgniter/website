<!---
 * Stands in for the operator "<=>" on two strings: spaceship_(a, b).
 *
 * Returns -1, 0 or 1. Two numeric strings are compared as numbers; any
 * other pair is compared as text, byte by byte (case-sensitive). This is
 * how the original compares two strings with "<", ">", "<=" and ">=".
 *
 * Two whole numbers of up to 18 digits are compared exactly (a double has
 * only 15 or 16 digits). Every other number is compared as a double.
 *
 * Difference: a whole number of 19 digits is compared as a double here,
 * and exactly in the original when it fits in 64 bits.
--->
<cffunction name="spaceship_" returntype="numeric" output="no" hint="Stands in for the operator <=> on two strings">
	<cfargument name="a" type="string" required="yes">
	<cfargument name="b" type="string" required="yes">
	<cfset var first = "">
	<cfset var second = "">
	<cfset var x = 0>
	<cfset var y = 0>
	<cfset var result = 0>

	<cfif is_numeric(arguments.a) AND is_numeric(arguments.b)>
		<cfset first = JavaCast("string", arguments.a).trim()>
		<cfset second = JavaCast("string", arguments.b).trim()>

		<cfif first.matches("[+-]?[0-9]{1,18}") AND second.matches("[+-]?[0-9]{1,18}")>
			<cfif first.startsWith("+")>
				<cfset first = first.substring(JavaCast("int", 1))>
			</cfif>
			<cfif second.startsWith("+")>
				<cfset second = second.substring(JavaCast("int", 1))>
			</cfif>
			<cfset x = CreateObject("java", "java.math.BigInteger").init(JavaCast("string", first))>
			<cfset y = CreateObject("java", "java.math.BigInteger").init(JavaCast("string", second))>
			<cfset result = x.compareTo(y)>
		<cfelse>
			<cfset x = floatval(first)>
			<cfset y = floatval(second)>
			<cfif x LT y>
				<cfset result = -1>
			<cfelseif x GT y>
				<cfset result = 1>
			</cfif>
		</cfif>
	<cfelse>
		<cfset result = Compare(arguments.a, arguments.b)>
	</cfif>

	<cfif result LT 0>
		<cfreturn -1>
	<cfelseif result GT 0>
		<cfreturn 1>
	</cfif>

	<cfreturn 0>
</cffunction>
