<!---
 * Encryption configuration.
 *
 * These are the settings used for encryption, if you don't pass a parameter
 * array to the encrypter for creation/initialization.
 *
 * Difference: a boolean is the string "true" or "false".
 *
 * Difference: the default cipher is AES-128-CTR, as the JVM of the server
 * has no unlimited-strength policy and so cannot use a 256 bit key. A
 * cipher of AES-256 gives an EncryptionException that says so, unless the
 * JVM allows it. The digest and the layout of the data are the original's,
 * so data is the same as that of the original given the same key and cipher.
 *
 * The key is only read from here (and the .env file) for the request. It
 * is never stored in the server or the application scope or in a cache.
 *
 * To use AES-256, install the Java unlimited-strength policy files on every
 * server, then set the cipher to AES-256-CTR (here, or in the .env file as
 * encryption.cipher) and a key of 32 bytes. A stock server keeps AES-128 and
 * needs nothing installed. Behind a load balancer, every server needs the
 * same key, cipher and policy, or data written on one server cannot be read
 * on another.
--->
<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="Encryption configuration">

	<!---
	 * --------------------------------------------------------------------------
	 * Encryption Key Starter
	 * --------------------------------------------------------------------------
	 *
	 * If you use the Encryption class you must set an encryption key (seed).
	 * You need to ensure it is long enough for the cipher and mode you plan to use.
	 * See the user guide for more info.
	 *
	 * In the .env file the prefixes hex2bin: and base64: are decoded to a
	 * byte array (see BaseConfig).
	--->
	<cfset this.key = "">

	<!---
	 * --------------------------------------------------------------------------
	 * Previous Encryption Keys
	 * --------------------------------------------------------------------------
	 *
	 * When rotating encryption keys, add old keys here to maintain ability
	 * to decrypt data encrypted with previous keys. Encryption always uses
	 * the current key. Decryption tries current key first, then falls back
	 * to previous keys if decryption fails.
	 *
	 * In .env file, use comma-separated string:
	 *   encryption.previousKeys = hex2bin:9be8c64fcea509867...,hex2bin:3f5a1d8e9c2b7a4f6...
	 *
	 * @var list<string>|string
	--->
	<cfset this.previousKeys = "">

	<!---
	 * --------------------------------------------------------------------------
	 * Encryption Driver to Use
	 * --------------------------------------------------------------------------
	 *
	 * One of the supported encryption drivers.
	 *
	 * Available drivers:
	 * - OpenSSL
	 * - Sodium
	 *
	 * Not ported yet: the Sodium driver (no libsodium).
	--->
	<cfset this.driver = "OpenSSL">

	<!---
	 * --------------------------------------------------------------------------
	 * SodiumHandler's Padding Length in Bytes
	 * --------------------------------------------------------------------------
	 *
	 * This is the number of bytes that will be padded to the plaintext message
	 * before it is encrypted. This value should be greater than zero.
	 *
	 * See the user guide for more information on padding.
	--->
	<cfset this.blockSize = 16>

	<!---
	 * --------------------------------------------------------------------------
	 * Encryption digest
	 * --------------------------------------------------------------------------
	 *
	 * HMAC digest to use, e.g. 'SHA512' or 'SHA256'. Default value is 'SHA512'.
	 *
	 * Difference: SHA224 is not in the Java of the server.
	--->
	<cfset this.digest = "SHA512">

	<!---
	 * Whether the cipher-text should be raw. If set to false, then it will be base64 encoded.
	 * This setting is only used by OpenSSLHandler.
	 *
	 * Set to false for CI3 Encryption compatibility.
	--->
	<cfset this.rawData = "true">

	<!---
	 * Encryption key info.
	 * This setting is only used by OpenSSLHandler.
	 *
	 * Set to 'encryption' for CI3 Encryption compatibility.
	--->
	<cfset this.encryptKeyInfo = "">

	<!---
	 * Authentication key info.
	 * This setting is only used by OpenSSLHandler.
	 *
	 * Set to 'authentication' for CI3 Encryption compatibility.
	--->
	<cfset this.authKeyInfo = "">

	<!---
	 * Cipher to use.
	 * This setting is only used by OpenSSLHandler.
	 *
	 * Set to 'AES-128-CBC' to decrypt encrypted data that encrypted
	 * by CI3 Encryption default configuration.
	 *
	 * Difference: the original has 'AES-256-CTR'; see the note at the top.
	--->
	<cfset this.cipher = "AES-128-CTR">

</cfcomponent>
