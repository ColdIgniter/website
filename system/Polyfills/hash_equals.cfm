<!---
 * Timing attack safe string comparison. The comparison is case-sensitive.
 *
 * Difference: MessageDigest.isEqual() is not used. On the Java of the
 * server (1.4.2) it stops at the first byte that differs, so the time
 * would tell how much of a token is right. Here the whole length of the
 * strings is always walked and the differences are collected.
 *
 * @param known The string of known length to compare against
 * @param user  The user-supplied string
--->
<cffunction name="hash_equals" returntype="boolean" output="no" hint="Timing attack safe string comparison">
	<cfargument name="known" type="string" required="yes">
	<cfargument name="user" type="string" required="yes">
	<cfset var difference = 0>
	<cfset var i = 0>

	<!--- the length of a token is not a secret --->
	<cfif Len(arguments.known) NEQ Len(arguments.user)>
		<cfreturn false>
	</cfif>

	<cfloop from="1" to="#Len(arguments.known)#" index="i">
		<cfset difference = BitOr(difference, BitXor(Asc(Mid(arguments.known, i, 1)), Asc(Mid(arguments.user, i, 1))))>
	</cfloop>

	<cfreturn difference EQ 0>
</cffunction>
