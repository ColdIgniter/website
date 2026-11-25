<!---
 * Finds the end of a bracket expression of a pattern that starts at the
 * place p (the character "["). Returns the place of the closing "]", or 0
 * when there is none, and then the "[" is an ordinary character. Shared
 * with fnmatch().
--->
<cffunction name="fnmatch_class_end" returntype="numeric" output="no" hint="Finds the end of a bracket expression of a pattern">
	<cfargument name="pattern" type="string" required="yes">
	<cfargument name="p" type="numeric" required="yes">
	<cfset var plen = Len(arguments.pattern)>
	<cfset var i = arguments.p + 1>

	<!--- a "!" or "^" negates, and a "]" first in the set is a member --->
	<cfif i LTE plen AND (Compare(Mid(arguments.pattern, i, 1), "!") EQ 0 OR Compare(Mid(arguments.pattern, i, 1), "^") EQ 0)>
		<cfset i = i + 1>
	</cfif>

	<cfif i LTE plen AND Compare(Mid(arguments.pattern, i, 1), "]") EQ 0>
		<cfset i = i + 1>
	</cfif>

	<cfloop condition="i LTE plen">
		<cfif Compare(Mid(arguments.pattern, i, 1), "]") EQ 0>
			<cfreturn i>
		</cfif>

		<cfset i = i + 1>
	</cfloop>

	<cfreturn 0>
</cffunction>

<!---
 * Finds whether a character is in the bracket expression of a pattern
 * between the places p ("[") and e ("]"). Shared with fnmatch().
--->
<cffunction name="fnmatch_class_has" returntype="boolean" output="no" hint="Finds whether a character is in a bracket expression">
	<cfargument name="pattern" type="string" required="yes">
	<cfargument name="p" type="numeric" required="yes">
	<cfargument name="e" type="numeric" required="yes">
	<cfargument name="ch" type="string" required="yes">
	<cfset var i = arguments.p + 1>
	<cfset var negate = false>
	<cfset var found = false>
	<cfset var c = "">

	<cfif Compare(Mid(arguments.pattern, i, 1), "!") EQ 0 OR Compare(Mid(arguments.pattern, i, 1), "^") EQ 0>
		<cfset negate = true>
		<cfset i = i + 1>
	</cfif>

	<cfloop condition="i LT arguments.e">
		<cfset c = Mid(arguments.pattern, i, 1)>

		<cfif i + 2 LT arguments.e AND Compare(Mid(arguments.pattern, i + 1, 1), "-") EQ 0>
			<!--- a range --->
			<cfif Asc(arguments.ch) GTE Asc(c) AND Asc(arguments.ch) LTE Asc(Mid(arguments.pattern, i + 2, 1))>
				<cfset found = true>
			</cfif>

			<cfset i = i + 3>
		<cfelse>
			<cfif Compare(c, arguments.ch) EQ 0>
				<cfset found = true>
			</cfif>

			<cfset i = i + 1>
		</cfif>
	</cfloop>

	<cfif negate>
		<cfreturn NOT found>
	</cfif>

	<cfreturn found>
</cffunction>

<!---
 * Matches a file name against a shell wildcard pattern: "*" for any run of
 * characters (also none), "?" for one character, a bracket expression
 * ("[abc]", "[a-c]", "[!abc]") and a backslash to take the next character
 * as it is. The comparison is case sensitive.
 *
 * Difference: the match is a linear scan with a backtrack to the last "*"
 * (no regular expression is built from the pattern), so the time grows with
 * the length of the pattern times the length of the name at the most.
 * The flag FNM_PERIOD is the argument period: when it is true, a period
 * at the start of the name is only matched by a period written in the
 * pattern. The other flags are not ported yet.
--->
<cffunction name="fnmatch" returntype="boolean" output="no" hint="Matches a file name against a shell wildcard pattern">
	<cfargument name="pattern" type="string" required="yes">
	<cfargument name="string" type="string" required="yes">
	<cfargument name="period" type="boolean" required="no" default="false">
	<cfset var plen = Len(arguments.pattern)>
	<cfset var slen = Len(arguments.string)>
	<cfset var p = 1>
	<cfset var s = 1>
	<cfset var starP = 0>
	<cfset var starS = 0>
	<cfset var pc = "">
	<cfset var ch = "">
	<cfset var ok = false>
	<cfset var star = false>
	<cfset var e = 0>

	<cfif arguments.period AND slen GT 0 AND Compare(Mid(arguments.string, 1, 1), ".") EQ 0>
		<cfif plen EQ 0>
			<cfreturn false>
		</cfif>

		<cfset pc = Mid(arguments.pattern, 1, 1)>

		<cfif Compare(pc, "\") EQ 0 AND plen GT 1>
			<cfset pc = Mid(arguments.pattern, 2, 1)>
		</cfif>

		<cfif Compare(pc, ".") NEQ 0>
			<cfreturn false>
		</cfif>
	</cfif>

	<cfloop condition="s LTE slen">
		<cfset ch = Mid(arguments.string, s, 1)>
		<cfset ok = false>
		<cfset star = false>

		<cfif p LTE plen>
			<cfset pc = Mid(arguments.pattern, p, 1)>

			<cfif Compare(pc, "*") EQ 0>
				<cfset star = true>
			<cfelseif Compare(pc, "?") EQ 0>
				<cfset ok = true>
				<cfset p = p + 1>
			<cfelseif Compare(pc, "[") EQ 0>
				<cfset e = fnmatch_class_end(arguments.pattern, p)>

				<cfif e EQ 0>
					<cfset ok = Compare(ch, "[") EQ 0>
					<cfset p = p + 1>
				<cfelse>
					<cfset ok = fnmatch_class_has(arguments.pattern, p, e, ch)>
					<cfset p = e + 1>
				</cfif>
			<cfelseif Compare(pc, "\") EQ 0 AND p LT plen>
				<cfset ok = Compare(ch, Mid(arguments.pattern, p + 1, 1)) EQ 0>
				<cfset p = p + 2>
			<cfelse>
				<cfset ok = Compare(ch, pc) EQ 0>
				<cfset p = p + 1>
			</cfif>
		</cfif>

		<cfif star>
			<!--- the star first matches nothing; a later mismatch makes it take one more character --->
			<cfset starP = p>
			<cfset starS = s>
			<cfset p = p + 1>
		<cfelseif ok>
			<cfset s = s + 1>
		<cfelseif starP GT 0>
			<cfset starS = starS + 1>
			<cfset s = starS>
			<cfset p = starP + 1>
		<cfelse>
			<cfreturn false>
		</cfif>
	</cfloop>

	<cfloop condition="p LTE plen AND Compare(Mid(arguments.pattern, p, 1), '*') EQ 0">
		<cfset p = p + 1>
	</cfloop>

	<cfreturn p GT plen>
</cffunction>
