<!---
 * Generate a HKDF key derivation of a supplied key input (RFC 5869).
 *
 * Difference: the result is a byte array (see bin2hex()), and key, info
 * and salt may be a byte array or text (taken as UTF-8). It is made on
 * hash_hmac() of this folder. An empty salt is an empty HMAC key, which is
 * the hash-length string of zeros of the RFC, as a key is padded with zeros
 * to the block size. SHA-224 is not in the Java of the server.
 *
 * @param algo   The hash algorithm, such as sha256 or sha512
 * @param key    The input keying material
 * @param length The length of the output in bytes, 0 for the hash length
 * @param info   The context and application specific information
 * @param salt   The salt
--->
<cffunction name="hash_hkdf" returntype="any" output="no" hint="Generate a HKDF key derivation of a supplied key input">
	<cfargument name="algo" type="string" required="yes">
	<cfargument name="key" type="any" required="yes">
	<cfargument name="length" type="numeric" required="no" default="0">
	<cfargument name="info" type="any" required="no" default="">
	<cfargument name="salt" type="any" required="no" default="">
	<cfset var prk = "">
	<cfset var hashLength = 0>
	<cfset var infoBytes = "">
	<cfset var blocks = 0>
	<cfset var previous = "">
	<cfset var input = "">
	<cfset var okm = CreateObject("java", "java.io.ByteArrayOutputStream").init()>
	<cfset var result = "">
	<cfset var i = 0>

	<cfif (IsBinary(arguments.key) AND ArrayLen(arguments.key) EQ 0) OR (NOT IsBinary(arguments.key) AND Len(arguments.key) EQ 0)>
		<cfthrow type="ColdIgniter.ValueError" message="hash_hkdf(): Argument ##2 ($key) cannot be empty">
	</cfif>

	<cfif arguments.length LT 0>
		<cfthrow type="ColdIgniter.ValueError" message="hash_hkdf(): Argument ##3 ($length) must be greater than or equal to 0">
	</cfif>

	<!--- extract: the salt is the key of the HMAC, the input keying material is its data --->
	<cfset prk = hash_hmac(arguments.algo, arguments.key, arguments.salt, true)>
	<cfset hashLength = request.ColdIgniter.digests[arguments.algo].md.getDigestLength()>

	<cfif arguments.length EQ 0>
		<cfset arguments.length = hashLength>
	<cfelseif arguments.length GT 255 * hashLength>
		<cfthrow type="ColdIgniter.ValueError" message="hash_hkdf(): Argument ##3 ($length) must be less than or equal to #255 * hashLength#">
	</cfif>

	<cfif IsBinary(arguments.info)>
		<cfset infoBytes = arguments.info>
	<cfelse>
		<cfset infoBytes = JavaCast("string", arguments.info).getBytes("UTF-8")>
	</cfif>

	<!--- expand --->
	<cfset blocks = Ceiling(arguments.length / hashLength)>

	<cfloop from="1" to="#blocks#" index="i">
		<cfset input = CreateObject("java", "java.io.ByteArrayOutputStream").init()>

		<cfif i GT 1>
			<cfset input.write(previous, JavaCast("int", 0), JavaCast("int", hashLength))>
		</cfif>

		<cfif ArrayLen(infoBytes) GT 0>
			<cfset input.write(infoBytes, JavaCast("int", 0), JavaCast("int", ArrayLen(infoBytes)))>
		</cfif>

		<cfset input.write(JavaCast("int", i))>
		<cfset previous = hash_hmac(arguments.algo, input.toByteArray(), prk, true)>
		<cfset okm.write(previous, JavaCast("int", 0), JavaCast("int", hashLength))>
	</cfloop>

	<cfset result = okm.toByteArray()>

	<cfif ArrayLen(result) GT arguments.length>
		<!--- the last block is cut: a new array of the length is filled from the result --->
		<cfset infoBytes = JavaCast("string", RepeatString("x", arguments.length)).getBytes()>
		<cfset CreateObject("java", "java.lang.System").arraycopy(result, JavaCast("int", 0), infoBytes, JavaCast("int", 0), JavaCast("int", arguments.length))>
		<cfset result = infoBytes>
	</cfif>

	<cfreturn result>
</cffunction>
