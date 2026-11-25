<!---
 * Rounds a number to a number of decimal digits, half away from zero:
 * round_(num, precision).
 *
 * Named with an underscore, because Round is a built-in function (it
 * takes no precision).
 *
 * Difference: the original first rounds the value to 15 significant
 * digits, so that 1.4999999999999999 and 5.055 round as they print. Here
 * the value is multiplied by the power of ten, so a result of the
 * multiplication that lands one step below .5 rounds down.
--->
<cffunction name="round_" returntype="numeric" output="no" hint="Rounds a number half away from zero">
	<cfargument name="num" type="numeric" required="yes">
	<cfargument name="precision" type="numeric" required="no" default="0">
	<cfset var factor = 10 ^ arguments.precision>
	<cfset var scaled = Abs(arguments.num) * factor>
	<cfset var rounded = Int(scaled + 0.5)>

	<cfif arguments.num LT 0>
		<cfreturn 0 - (rounded / factor)>
	</cfif>

	<cfreturn rounded / factor>
</cffunction>
