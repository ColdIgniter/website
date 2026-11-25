<!---
 * Compares two version strings. Without an operator it returns -1, 0 or 1
 * (first is lower, equal, higher). With an operator (lt, le, gt, ge, eq, ne
 * or the matching symbols) it returns true or false.
 *
 * "-", "_" and "+" count as ".", a "." is put between digits and
 * letters ("1rc2" is "1.rc.2"), and words rank
 * anything else < dev < alpha, a < beta, b < RC, rc < a number < pl, p.
 * Any other character that is not a letter or digit also separates parts,
 * so a ColdFusion version such as "6,1,0,63958" can be passed as it is.
 *
 * Difference: empty parts ("1..2") are skipped.
--->
<cffunction name="version_compare" returntype="any" output="no" hint="Compares two version strings">
	<cfargument name="version1" type="string" required="yes">
	<cfargument name="version2" type="string" required="yes">
	<cfargument name="operator" type="string" required="no" default="">
	<cfset var parts1 = _version_compare_parts(arguments.version1)>
	<cfset var parts2 = _version_compare_parts(arguments.version2)>
	<cfset var count1 = ArrayLen(parts1)>
	<cfset var count2 = ArrayLen(parts2)>
	<cfset var result = 0>
	<cfset var i = 0>
	<cfset var number = 4>
	<cfset var isNumber1 = false>
	<cfset var isNumber2 = false>
	<cfset var lessThan = Chr(60)>
	<cfset var greaterThan = Chr(62)>

	<cfloop index="i" from="1" to="#Min(count1, count2)#">
		<cfset isNumber1 = REFind("^[0-9]", parts1[i]) EQ 1>
		<cfset isNumber2 = REFind("^[0-9]", parts2[i]) EQ 1>

		<cfif isNumber1 AND isNumber2>
			<cfset result = Sgn(Val(parts1[i]) - Val(parts2[i]))>
		<cfelseif isNumber1>
			<cfset result = Sgn(number - _version_compare_rank(parts2[i]))>
		<cfelseif isNumber2>
			<cfset result = Sgn(_version_compare_rank(parts1[i]) - number)>
		<cfelse>
			<cfset result = Sgn(_version_compare_rank(parts1[i]) - _version_compare_rank(parts2[i]))>
		</cfif>

		<cfif result NEQ 0>
			<cfbreak>
		</cfif>
	</cfloop>

	<!--- All shared parts are equal: the first extra part decides. --->
	<cfif result EQ 0 AND count1 GT count2>
		<cfif REFind("^[0-9]", parts1[count2 + 1]) EQ 1>
			<cfset result = 1>
		<cfelse>
			<cfset result = Sgn(_version_compare_rank(parts1[count2 + 1]) - number)>
		</cfif>
	<cfelseif result EQ 0 AND count2 GT count1>
		<cfif REFind("^[0-9]", parts2[count1 + 1]) EQ 1>
			<cfset result = -1>
		<cfelse>
			<cfset result = Sgn(number - _version_compare_rank(parts2[count1 + 1]))>
		</cfif>
	</cfif>

	<cfif Len(arguments.operator) EQ 0>
		<cfreturn result>
	</cfif>

	<cfif arguments.operator EQ "lt" OR arguments.operator EQ lessThan>
		<cfreturn result EQ -1>
	<cfelseif arguments.operator EQ "le" OR arguments.operator EQ lessThan & "=">
		<cfreturn result NEQ 1>
	<cfelseif arguments.operator EQ "gt" OR arguments.operator EQ greaterThan>
		<cfreturn result EQ 1>
	<cfelseif arguments.operator EQ "ge" OR arguments.operator EQ greaterThan & "=">
		<cfreturn result NEQ -1>
	<cfelseif arguments.operator EQ "eq" OR arguments.operator EQ "==">
		<cfreturn result EQ 0>
	<cfelseif arguments.operator EQ "ne" OR arguments.operator EQ "!=" OR arguments.operator EQ lessThan & greaterThan>
		<cfreturn result NEQ 0>
	</cfif>

	<cfthrow type="ValueError" message="version_compare(): Argument ##3 ($operator) must be a valid comparison operator">
</cffunction>

<cffunction name="_version_compare_parts" returntype="array" output="no" hint="Splits a version string into its parts">
	<cfargument name="version" type="string" required="yes">
	<cfset var canonical = REReplace(arguments.version, "[^A-Za-z0-9]", ".", "all")>

	<cfset canonical = REReplace(canonical, "([0-9])([A-Za-z])", "\1.\2", "all")>
	<cfset canonical = REReplace(canonical, "([A-Za-z])([0-9])", "\1.\2", "all")>

	<cfreturn ListToArray(canonical, ".")>
</cffunction>

<cffunction name="_version_compare_rank" returntype="numeric" output="no" hint="Rank of a word part: dev 0, alpha 1, beta 2, RC 3, pl 5, anything else -1. A number ranks 4.">
	<cfargument name="part" type="string" required="yes">
	<cfset var names = "dev,alpha,a,beta,b,RC,rc,pl,p">
	<cfset var ranks = "0,1,1,2,2,3,3,5,5">
	<cfset var name = "">
	<cfset var i = 0>

	<!--- A name matches when the part starts with it, in the same case. --->
	<cfloop index="i" from="1" to="#ListLen(names)#">
		<cfset name = ListGetAt(names, i)>
		<cfif Compare(Left(arguments.part, Len(name)), name) EQ 0>
			<cfreturn ListGetAt(ranks, i)>
		</cfif>
	</cfloop>

	<cfreturn -1>
</cffunction>
