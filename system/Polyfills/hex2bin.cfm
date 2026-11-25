<!---
 * Decodes a hexadecimally encoded binary string into a byte array (see
 * bin2hex()).
 *
 * Difference: the original gives a warning and returns false for an odd
 * length or a character that is not a hexadecimal digit, and the error
 * handler of the framework turns the warning into an ErrorException. Here
 * the exception is thrown (type "ColdIgniter.ErrorException").
--->
<cffunction name="hex2bin" returntype="any" output="no" hint="Decodes a hexadecimally encoded binary string">
	<cfargument name="string" type="string" required="yes">
	<cfset var result = CreateObject("java", "java.io.ByteArrayOutputStream").init()>
	<cfset var i = 0>

	<cfif Len(arguments.string) MOD 2 NEQ 0>
		<cfthrow type="ColdIgniter.ErrorException" message="hex2bin(): Hexadecimal input string must have an even length">
	</cfif>

	<cfif REFind("[^0-9a-fA-F]", arguments.string) GT 0>
		<cfthrow type="ColdIgniter.ErrorException" message="hex2bin(): Input string must be hexadecimal string">
	</cfif>

	<cfloop from="1" to="#Len(arguments.string)#" index="i" step="2">
		<cfset result.write(JavaCast("int", InputBaseN(Mid(arguments.string, i, 2), 16)))>
	</cfloop>

	<cfreturn result.toByteArray()>
</cffunction>
