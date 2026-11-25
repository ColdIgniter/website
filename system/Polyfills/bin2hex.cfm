<!---
 * Converts binary data to its hexadecimal representation, two lower case
 * digits for each byte.
 *
 * Difference: a string cannot hold a NUL character on 6.1 (it is dropped), so
 * the binary data of the original is a byte array (what random_bytes()
 * and hex2bin() return and IsBinary() is true for).
--->
<cffunction name="bin2hex" returntype="string" output="no" hint="Converts binary data to its hexadecimal representation">
	<cfargument name="bytes" type="any" required="yes">
	<cfset var result = CreateObject("java", "java.lang.StringBuffer").init()>
	<cfset var value = 0>
	<cfset var i = 0>

	<cfloop from="1" to="#ArrayLen(arguments.bytes)#" index="i">
		<cfset value = arguments.bytes[i]>

		<!--- a Java byte is signed --->
		<cfif value LT 0>
			<cfset value = value + 256>
		</cfif>

		<cfset result.append(JavaCast("string", Right("0" & LCase(FormatBaseN(value, 16)), 2)))>
	</cfloop>

	<cfreturn result.toString()>
</cffunction>
