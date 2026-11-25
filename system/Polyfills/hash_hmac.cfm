<!---
 * Generates a keyed hash value using the HMAC method (RFC 2104).
 *
 * Difference: the Java of the server (1.4.2) has no javax.crypto.Mac for
 * SHA-256, SHA-384 or SHA-512, so the HMAC is built on
 * java.security.MessageDigest here: the key is padded to the block size
 * and xor-ed with 0x36 and 0x5c. Binary data is a byte array (see
 * bin2hex()); data and key may be a byte array or text (taken as UTF-8).
 * The algorithms are md5, sha1, sha256, sha384 and sha512 (also with a
 * hyphen), SHA-224 is not in that Java. The result is a byte array when
 * binary is true, and lower case hexadecimal text otherwise.
 *
 * The MessageDigest of an algorithm is kept for the request in
 * request.ColdIgniter.digests (it is not shared by requests).
--->
<cffunction name="hash_hmac" returntype="any" output="no" hint="Generates a keyed hash value using the HMAC method">
	<cfargument name="algo" type="string" required="yes">
	<cfargument name="data" type="any" required="yes">
	<cfargument name="key" type="any" required="yes">
	<cfargument name="binary" type="boolean" required="no" default="false">
	<cfset var digests = "">
	<cfset var name = "">
	<cfset var found = 0>
	<cfset var info = "">
	<cfset var md = "">
	<cfset var block = 0>
	<cfset var keyBytes = "">
	<cfset var dataBytes = "">
	<cfset var ipad = "">
	<cfset var opad = "">
	<cfset var fill = 0>
	<cfset var inner = "">
	<cfset var mac = "">
	<cfset var i = 0>

	<cfif NOT StructKeyExists(request.ColdIgniter, "digests")>
		<cfset request.ColdIgniter.digests = StructNew()>
	</cfif>
	<cfset digests = request.ColdIgniter.digests>

	<cfif NOT StructKeyExists(digests, arguments.algo)>
		<cfset name = Replace(UCase(arguments.algo), "-", "", "all")>
		<cfset found = ListFind("MD5,SHA1,SHA256,SHA384,SHA512", name)>

		<cfif found EQ 0>
			<cfthrow type="ColdIgniter.ValueError" message="hash_hmac(): Argument ##1 ($algo) must be a valid cryptographic hashing algorithm">
		</cfif>

		<cfset info = StructNew()>
		<cfset info.md = CreateObject("java", "java.security.MessageDigest").getInstance(JavaCast("string", ListGetAt("MD5,SHA-1,SHA-256,SHA-384,SHA-512", found)))>
		<cfset info.block = 64>

		<!--- the block size of SHA-384 and SHA-512 is 128 bytes --->
		<cfif found GTE 4>
			<cfset info.block = 128>
		</cfif>

		<cfset digests[arguments.algo] = info>
	</cfif>

	<cfset info = digests[arguments.algo]>
	<cfset md = info.md>
	<cfset block = info.block>

	<cfif IsBinary(arguments.key)>
		<cfset keyBytes = arguments.key>
	<cfelse>
		<cfset keyBytes = JavaCast("string", arguments.key).getBytes("UTF-8")>
	</cfif>

	<cfif IsBinary(arguments.data)>
		<cfset dataBytes = arguments.data>
	<cfelse>
		<cfset dataBytes = JavaCast("string", arguments.data).getBytes("UTF-8")>
	</cfif>

	<cfset md.reset()>

	<!--- a key longer than the block is hashed first --->
	<cfif ArrayLen(keyBytes) GT block>
		<cfset keyBytes = md.digest(keyBytes)>
	</cfif>

	<cfset ipad = CreateObject("java", "java.io.ByteArrayOutputStream").init()>
	<cfset opad = CreateObject("java", "java.io.ByteArrayOutputStream").init()>

	<cfloop from="1" to="#ArrayLen(keyBytes)#" index="i">
		<!--- the signed bytes are xor-ed as they are: only the low 8 bits are written --->
		<cfset ipad.write(JavaCast("int", BitXor(keyBytes[i], 54)))>
		<cfset opad.write(JavaCast("int", BitXor(keyBytes[i], 92)))>
	</cfloop>

	<!--- the rest of the block is the zero padding of the key xor-ed: "6" is 0x36 and "\" is 0x5c --->
	<cfset fill = block - ArrayLen(keyBytes)>

	<cfif fill GT 0>
		<cfset ipad.write(JavaCast("string", RepeatString("6", fill)).getBytes(), JavaCast("int", 0), JavaCast("int", fill))>
		<cfset opad.write(JavaCast("string", RepeatString("\", fill)).getBytes(), JavaCast("int", 0), JavaCast("int", fill))>
	</cfif>

	<cfset md.update(ipad.toByteArray())>
	<cfset md.update(dataBytes)>
	<cfset inner = md.digest()>
	<cfset md.update(opad.toByteArray())>
	<cfset md.update(inner)>
	<cfset mac = md.digest()>

	<cfif arguments.binary>
		<cfreturn mac>
	</cfif>

	<cfreturn bin2hex(mac)>
</cffunction>
