<!---
 * Encryption handler using AES through javax.crypto.Cipher.
 *
 * Difference: there is no OpenSSL here. The ciphers are AES-128, AES-192
 * and AES-256 in the modes CTR, CBC (PKCS7 padding) and ECB (PKCS7
 * padding), which are the ones of the original that the JVM has; any other
 * cipher gives EncryptionException.forEncryptionFailed(). The message
 * layout is the one of the original (hmac + iv + ciphertext, base64 text
 * unless rawData), so data is the same given the same key, cipher and
 * digest.
 *
 * Difference: this JVM (1.4.2) has no unlimited-strength policy, so AES
 * with a key longer than 128 bits cannot be used. The default cipher of
 * Config\Encryption is AES-128-CTR, and asking for a longer key throws
 * EncryptionException.forUnlimitedStrengthNeeded() (not in the original).
 * That is decided by trying Cipher.init() once for the handler, and the
 * answer is kept in the handler, so a JVM that allows the key works
 * unchanged.
 *
 * Difference: a binary string is a Java byte array (see random_bytes()),
 * the key too: a key is text (UTF-8) or a byte array (what the hex2bin:
 * and base64: prefixes of Config\Encryption give). The SHA-224 digest is
 * not in the Java of the server, so the digests are SHA256, SHA384 and
 * SHA512. The hash of the HMAC is made by hash_hmac() and hash_hkdf() of
 * the polyfills. decrypt_() gives the plaintext as text (UTF-8).
 *
 * Difference: the HMAC is compared byte by byte over its whole length (as
 * hash_equals() does), so the time does not tell how much is right. The
 * key is only in the objects of the request, it is never put in the server
 * or the application scope, a cache or a message.
--->
<cfcomponent output="no" extends="BaseHandler" hint="Encryption handler using AES">

	<!---
	 * HMAC digest algorithm
	 *
	 * @var string
	--->
	<cfset this.digest = "SHA512">

	<!---
	 * Digest sizes (bytes)
	 *
	 * Difference: no SHA224, see above.
	 *
	 * @var array<string, int>
	--->
	<cfset this.digestSize = StructNew()>
	<cfset this.digestSize["SHA256"] = 32>
	<cfset this.digestSize["SHA384"] = 48>
	<cfset this.digestSize["SHA512"] = 64>

	<!---
	 * Cipher to use, an AES cipher of the form AES-128-CTR
	 *
	 * @var string
	--->
	<cfset this.cipher = "AES-128-CTR">

	<!---
	 * Starter key
	 *
	 * @var string|byte array
	--->
	<cfset this.key = "">

	<!---
	 * Whether the cipher text is raw binary data (a byte array), or
	 * base64 text.
	 *
	 * @var bool
	--->
	<cfset this.rawData = true>

	<!---
	 * Info to be used for key derivation of the encryption key.
	 *
	 * @var string
	--->
	<cfset this.encryptKeyInfo = "">

	<!---
	 * Info to be used for key derivation of the authentication key.
	 *
	 * @var string
	--->
	<cfset this.authKeyInfo = "">

	<!---
	 * Difference: not in the original. The parsed cipher (transformation,
	 * key bytes, iv size) and the Cipher object, made on first use; the
	 * name of the cipher they were made for is kept, and the answer of the
	 * strength check: 0 not tried, 1 allowed, -1 not allowed.
	--->
	<cfset variables.spec = "">
	<cfset variables.specFor = "">
	<cfset variables.jce = "">
	<cfset variables.strength = 0>

	<!---
	 * {@inheritDoc}
	 *
	 * @param data   Input data, text or a byte array
	 * @param params The key as text or a byte array, or a map with the member "key"; an empty string (null) for none
	--->
	<cffunction name="encrypt_" access="public" returntype="any" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfset var key = overrideKey(arguments.params)>
		<cfset var spec = getSpec()>
		<cfset var encryptKey = "">
		<cfset var iv = "">
		<cfset var encrypted = "">
		<cfset var result = "">
		<cfset var authKey = "">
		<cfset var hmacKey = "">
		<cfset var plain = "">
		<cfset var out = "">

		<cfset checkStrength(spec)>

		<cfif IsBinary(arguments.data)>
			<cfset plain = arguments.data>
		<cfelse>
			<cfset plain = JavaCast("string", arguments.data).getBytes("UTF-8")>
		</cfif>

		<!--- derive a secret key --->
		<cfset encryptKey = hash_hkdf(this.digest, key, 0, this.encryptKeyInfo)>

		<!--- basic encryption --->
		<cfif spec.ivSize GT 0>
			<cfset iv = random_bytes(spec.ivSize)>
		</cfif>

		<cftry>
			<cfset encrypted = runCipher(1, encryptKey, iv, plain, spec)>

			<cfcatch type="any">
				<cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forEncryptionFailed()>
			</cfcatch>
		</cftry>

		<!--- iv + data --->
		<cfset out = CreateObject("java", "java.io.ByteArrayOutputStream").init()>

		<cfif spec.ivSize GT 0>
			<cfset out.write(iv, JavaCast("int", 0), JavaCast("int", spec.ivSize))>
		</cfif>

		<cfset out.write(encrypted, JavaCast("int", 0), JavaCast("int", ArrayLen(encrypted)))>
		<cfset result = out.toByteArray()>

		<cfif NOT this.rawData>
			<cfset result = ToBase64(result)>
		</cfif>

		<!--- derive a secret key --->
		<cfset authKey = hash_hkdf(this.digest, key, 0, this.authKeyInfo)>
		<cfset hmacKey = hash_hmac(this.digest, result, authKey, this.rawData)>

		<cfif this.rawData>
			<cfset out = CreateObject("java", "java.io.ByteArrayOutputStream").init()>
			<cfset out.write(hmacKey, JavaCast("int", 0), JavaCast("int", ArrayLen(hmacKey)))>
			<cfset out.write(result, JavaCast("int", 0), JavaCast("int", ArrayLen(result)))>

			<cfreturn out.toByteArray()>
		</cfif>

		<cfreturn hmacKey & result>
	</cffunction>

	<!---
	 * {@inheritDoc}
	 *
	 * @param data   Encrypted data, a byte array for raw data, text otherwise
	 * @param params The key as text or a byte array, or a map with the member "key"; an empty string (null) for none
	 *
	 * @return The plaintext, as text (UTF-8)
	--->
	<cffunction name="decrypt_" access="public" returntype="any" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfset var key = overrideKey(arguments.params)>
		<cfset var spec = "">
		<cfset var authKey = "">
		<cfset var hmacLength = 0>
		<cfset var hmacKey = "">
		<cfset var hmacCalc = "">
		<cfset var body = "">
		<cfset var iv = "">
		<cfset var encryptKey = "">
		<cfset var plain = "">
		<cfset var raw = "">

		<!--- Difference: an unsupported cipher is a failed authentication here, as the original gives for a failed decryption --->
		<cftry>
			<cfset spec = getSpec()>

			<cfcatch type="ColdIgniter.Encryption.Exceptions.EncryptionException">
				<cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forAuthenticationFailed()>
			</cfcatch>
		</cftry>

		<cfset checkStrength(spec)>

		<!--- derive a secret key --->
		<cfset authKey = hash_hkdf(this.digest, key, 0, this.authKeyInfo)>

		<cfif this.rawData>
			<cfif IsBinary(arguments.data)>
				<cfset raw = arguments.data>
			<cfelse>
				<cfset raw = JavaCast("string", arguments.data).getBytes("ISO-8859-1")>
			</cfif>

			<cfset hmacLength = this.digestSize[this.digest]>
			<cfset hmacKey = substr_(raw, 0, hmacLength)>
			<cfset body = substr_(raw, hmacLength)>
			<cfset hmacCalc = hash_hmac(this.digest, body, authKey, true)>

			<cfif NOT bytesMatch(hmacKey, hmacCalc)>
				<cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forAuthenticationFailed()>
			</cfif>

			<!--- what follows the hmac is the iv and the ciphertext --->
			<cfset raw = body>
		<cfelse>
			<cfif IsBinary(arguments.data)>
				<cfset arguments.data = ToString(arguments.data, "ISO-8859-1")>
			</cfif>

			<cfset hmacLength = this.digestSize[this.digest] * 2>

			<cfif Len(arguments.data) LTE hmacLength>
				<cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forAuthenticationFailed()>
			</cfif>

			<cfset hmacKey = Left(arguments.data, hmacLength)>
			<cfset body = Mid(arguments.data, hmacLength + 1, Len(arguments.data))>
			<cfset hmacCalc = hash_hmac(this.digest, body, authKey, false)>

			<cfif NOT hash_equals(hmacKey, hmacCalc)>
				<cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forAuthenticationFailed()>
			</cfif>

			<!--- Difference: base64_decode() is strict in the original; the text is ours, as the HMAC is right --->
			<cftry>
				<cfset raw = ToBinary(body)>

				<cfcatch type="any">
					<cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forAuthenticationFailed()>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif spec.ivSize GT 0>
			<cfif ArrayLen(raw) LT spec.ivSize>
				<cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forAuthenticationFailed()>
			</cfif>

			<cfset iv = substr_(raw, 0, spec.ivSize)>
			<cfset body = substr_(raw, spec.ivSize)>
		<cfelse>
			<cfset body = raw>
		</cfif>

		<!--- derive a secret key --->
		<cfset encryptKey = hash_hkdf(this.digest, key, 0, this.encryptKeyInfo)>

		<cftry>
			<cfset plain = runCipher(2, encryptKey, iv, body, spec)>

			<cfcatch type="any">
				<cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forAuthenticationFailed()>
			</cfcatch>
		</cftry>

		<cfif ArrayLen(plain) EQ 0>
			<cfreturn "">
		</cfif>

		<cfreturn ToString(plain, "UTF-8")>
	</cffunction>

	<!---
	 * Difference: not in the original. The key: the override of the
	 * params, or the key of the handler; it has to be a text or a byte
	 * array that is not empty and not "0".
	 *
	 * @throws EncryptionException
	--->
	<cffunction name="overrideKey" access="private" returntype="any" output="no">
		<cfargument name="params" type="any" required="yes">
		<cfset var key = this.key>

		<!--- allow key override --->
		<cfif IsStruct(arguments.params)>
			<cfif StructKeyExists(arguments.params, "key")>
				<cfset key = arguments.params.key>
			<cfelse>
				<!--- a map without the key is not a string, in the original --->
				<cfset key = "">
			</cfif>
		<cfelseif IsBinary(arguments.params) OR Compare(arguments.params, "") NEQ 0>
			<cfset key = arguments.params>
		</cfif>

		<cfif IsBinary(key)>
			<cfif ArrayLen(key) EQ 0>
				<cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forNeedsStarterKey()>
			</cfif>
		<cfelseif NOT IsSimpleValue(key) OR Compare(key, "") EQ 0 OR Compare(key, "0") EQ 0>
			<cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forNeedsStarterKey()>
		</cfif>

		<cfreturn key>
	</cffunction>

	<!---
	 * Difference: not in the original. The parts of the cipher name, made
	 * once for the cipher of the handler: the transformation, the bytes of
	 * the key, the size of the iv and the bits.
	 *
	 * @throws EncryptionException With forEncryptionFailed() for a cipher that is not AES-bits-CTR, CBC or ECB
	--->
	<cffunction name="getSpec" access="private" returntype="struct" output="no">
		<cfset var parts = "">
		<cfset var made = "">

		<cfif IsStruct(variables.spec) AND Compare(variables.specFor, this.cipher) EQ 0>
			<cfreturn variables.spec>
		</cfif>

		<cfset parts = ListToArray(UCase(this.cipher), "-")>

		<cfif ArrayLen(parts) NEQ 3 OR Compare(parts[1], "AES") NEQ 0 OR NOT ListFind("128,192,256", parts[2]) OR NOT ListFind("CTR,CBC,ECB", parts[3])>
			<cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forEncryptionFailed()>
		</cfif>

		<cfset made = StructNew()>
		<cfset made.bits = parts[2]>
		<cfset made.keyBytes = parts[2] / 8>
		<cfset made.ivSize = 16>

		<cfif Compare(parts[3], "CTR") EQ 0>
			<cfset made.transformation = "AES/CTR/NoPadding">
		<cfelseif Compare(parts[3], "CBC") EQ 0>
			<cfset made.transformation = "AES/CBC/PKCS5Padding">
		<cfelse>
			<cfset made.transformation = "AES/ECB/PKCS5Padding">
			<cfset made.ivSize = 0>
		</cfif>

		<cfset variables.spec = made>
		<cfset variables.specFor = this.cipher>
		<cfset variables.jce = "">
		<cfset variables.strength = 0>

		<cfreturn made>
	</cffunction>

	<!---
	 * Difference: not in the original. A key longer than 128 bits needs the
	 * unlimited-strength policy: Cipher.init() is tried once with a key of
	 * that size, and the answer is kept.
	 *
	 * @throws EncryptionException
	--->
	<cffunction name="checkStrength" access="private" returntype="void" output="no">
		<cfargument name="spec" type="struct" required="yes">
		<cfset var probe = "">

		<cfif arguments.spec.bits EQ 128 OR variables.strength EQ 1>
			<cfreturn>
		</cfif>

		<cfif variables.strength EQ 0>
			<cfset probe = JavaCast("string", RepeatString("k", arguments.spec.keyBytes)).getBytes()>

			<cftry>
				<cfset getCipher(arguments.spec).init(JavaCast("int", 1), CreateObject("java", "javax.crypto.spec.SecretKeySpec").init(probe, "AES"))>
				<cfset variables.strength = 1>

				<cfcatch type="any">
					<cfset variables.strength = -1>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif variables.strength EQ -1>
			<cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forUnlimitedStrengthNeeded(this.cipher)>
		</cfif>
	</cffunction>

	<!---
	 * Difference: not in the original. The Cipher object, kept in the
	 * handler (never in the server scope).
	--->
	<cffunction name="getCipher" access="private" returntype="any" output="no">
		<cfargument name="spec" type="struct" required="yes">

		<cfif NOT IsObject(variables.jce)>
			<cfset variables.jce = CreateObject("java", "javax.crypto.Cipher").getInstance(JavaCast("string", arguments.spec.transformation))>
		</cfif>

		<cfreturn variables.jce>
	</cffunction>

	<!---
	 * Difference: not in the original. Runs the cipher: openssl_encrypt()
	 * and openssl_decrypt() with OPENSSL_RAW_DATA. As OpenSSL does, only
	 * the first bytes of the derived key are used.
	 *
	 * @param mode 1 to encrypt, 2 to decrypt
	--->
	<cffunction name="runCipher" access="private" returntype="any" output="no">
		<cfargument name="mode" type="numeric" required="yes">
		<cfargument name="derived" type="any" required="yes">
		<cfargument name="iv" type="any" required="yes">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="spec" type="struct" required="yes">
		<cfset var jce = getCipher(arguments.spec)>
		<cfset var secret = CreateObject("java", "javax.crypto.spec.SecretKeySpec").init(arguments.derived, JavaCast("int", 0), JavaCast("int", arguments.spec.keyBytes), "AES")>

		<cfif arguments.spec.ivSize GT 0>
			<cfset jce.init(JavaCast("int", arguments.mode), secret, CreateObject("java", "javax.crypto.spec.IvParameterSpec").init(arguments.iv))>
		<cfelse>
			<cfset jce.init(JavaCast("int", arguments.mode), secret)>
		</cfif>

		<cfreturn jce.doFinal(arguments.data)>
	</cffunction>

	<!---
	 * Difference: not in the original. Compares two byte arrays over the
	 * whole of their length, the way hash_equals() does for text.
	--->
	<cffunction name="bytesMatch" access="private" returntype="boolean" output="no">
		<cfargument name="known" type="any" required="yes">
		<cfargument name="user" type="any" required="yes">
		<cfset var difference = 0>
		<cfset var i = 0>

		<!--- the length of a hash is not a secret --->
		<cfif ArrayLen(arguments.known) NEQ ArrayLen(arguments.user)>
			<cfreturn false>
		</cfif>

		<cfloop from="1" to="#ArrayLen(arguments.known)#" index="i">
			<cfset difference = BitOr(difference, BitXor(arguments.known[i], arguments.user[i]))>
		</cfloop>

		<cfreturn difference EQ 0>
	</cffunction>

</cfcomponent>
