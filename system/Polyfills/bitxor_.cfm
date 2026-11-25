<!---
 * Stands in for the operator "^" on two binary strings (byte arrays, see
 * bin2hex()): bitxor_(a, b). As in the original, the result is as long as
 * the shorter of the two.
--->
<cffunction name="bitxor_" returntype="any" output="no" hint="Exclusive or of two binary strings">
	<cfargument name="a" type="any" required="yes">
	<cfargument name="b" type="any" required="yes">
	<cfset var result = CreateObject("java", "java.io.ByteArrayOutputStream").init()>
	<cfset var length = ArrayLen(arguments.a)>
	<cfset var i = 0>

	<cfif ArrayLen(arguments.b) LT length>
		<cfset length = ArrayLen(arguments.b)>
	</cfif>

	<cfloop from="1" to="#length#" index="i">
		<!--- the signed bytes are xor-ed as they are: only the low 8 bits are written --->
		<cfset result.write(JavaCast("int", BitXor(arguments.a[i], arguments.b[i])))>
	</cfloop>

	<cfreturn result.toByteArray()>
</cffunction>
