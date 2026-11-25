<!---
 * Generates cryptographically secure random bytes, as a byte array (see
 * bin2hex()). The bytes come from java.security.SecureRandom.
 *
 * One SecureRandom is kept for the request in request.ColdIgniter.random, as
 * the other shared objects are: it is made on the first call and every later
 * call in the request uses it (it is thread safe).
--->
<cffunction name="random_bytes" returntype="any" output="no" hint="Generates cryptographically secure random bytes">
	<cfargument name="length" type="numeric" required="yes">
	<cfset var random = "">
	<cfset var bytes = "">

	<cfif NOT StructKeyExists(request.ColdIgniter, "random")>
		<cfset request.ColdIgniter.random = CreateObject("java", "java.security.SecureRandom").init()>
	</cfif>
	<cfset random = request.ColdIgniter.random>

	<cfif arguments.length LT 1>
		<cfthrow type="ColdIgniter.ValueError" message="random_bytes(): Argument ##1 ($length) must be greater than 0">
	</cfif>

	<!--- an array of the right size to fill; the string holds ASCII only --->
	<cfset bytes = JavaCast("string", RepeatString("x", arguments.length)).getBytes()>
	<cfset random.nextBytes(bytes)>

	<cfreturn bytes>
</cffunction>
