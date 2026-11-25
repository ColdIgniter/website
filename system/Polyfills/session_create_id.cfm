<!---
 * Creates a new session id: 32 lower case hexadecimal characters (128
 * bits) from java.security.SecureRandom, which is the same format as
 * sid_length 32 with sid_bits_per_character 4.
--->
<cffunction name="session_create_id" returntype="string" output="no" hint="Creates a new session id">
	<cfset var random = CreateObject("java", "java.security.SecureRandom").init()>
	<cfset var integer = CreateObject("java", "java.lang.Integer")>
	<cfset var id = "">
	<cfset var part = "">
	<cfset var i = 0>

	<cfloop from="1" to="4" index="i">
		<cfset part = integer.toHexString(JavaCast("int", random.nextInt()))>
		<cfset id = id & RepeatString("0", 8 - Len(part)) & part>
	</cfloop>

	<cfreturn LCase(id)>
</cffunction>
