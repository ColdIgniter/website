<!---
 * CodeIgniter Encryption Manager
 *
 * Provides two-way keyed encryption via the OpenSSL handler (AES through
 * javax.crypto.Cipher). This class determines the driver, cipher, and mode
 * to use, and then initializes the appropriate encryption handler.
 *
 * Difference: the Sodium driver is not available (there is no libsodium on
 * the server), so its handler is not installed: asking for it throws the
 * "no handler available" exception.
 *
 * Difference: the HMAC key (hmacKey) of the original is derived with
 * hash_hkdf() and kept, but nothing reads it, so it is not derived here.
 *
 * Difference: a key is text or a byte array (see random_bytes()); the keys
 * of the Config\Encryption with the hex2bin: and base64: prefixes are byte
 * arrays. A key is held by the objects of the request only, never in the
 * server or the application scope, a cache or an exception message.
 *
 * Difference: the properties are in "this", and __get() and __isset() are
 * public methods that are called by name: encryption.__get("key").
 * A null is an empty string. The key of createKey() is a byte array.
 *
 * Not ported yet: the SodiumHandler (no libsodium).
--->
<cfcomponent output="no" hint="CodeIgniter Encryption Manager">

	<!---
	 * The encrypter we create
	 *
	 * @var EncrypterInterface
	--->
	<cfset this.encrypter = "">

	<!---
	 * The driver being used
	 *
	 * @var string
	--->
	<cfset this.driver = "">

	<!---
	 * The key/seed being used
	 *
	 * @var string|byte array
	--->
	<cfset this.key = "">

	<!---
	 * HMAC digest to use
	 *
	 * @var string
	--->
	<cfset this.digest = "SHA512">

	<!---
	 * Map of drivers to handler classes, in preference order
	 *
	 * @var list<string>
	--->
	<cfset this.drivers = ArrayNew(1)>
	<cfset ArrayAppend(this.drivers, "OpenSSL")>
	<cfset ArrayAppend(this.drivers, "Sodium")>

	<!---
	 * Handlers that are to be installed
	 *
	 * @var array<string, bool>
	--->
	<cfset this.handlers = StructNew()>

	<!---
	 * @param config The Config\Encryption, or an empty string (null) for the one of config()
	 *
	 * @throws EncryptionException
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\Encryption")>
		</cfif>

		<cfset this.key = arguments.config.key>
		<cfset this.driver = arguments.config.driver>
		<cfset this.digest = arguments.config.digest>

		<!--- Difference: the Sodium handler is not ported --->
		<cfset this.handlers["OpenSSL"] = true>
		<cfset this.handlers["Sodium"] = false>

		<cfif NOT ListFind(ArrayToList(this.drivers), this.driver) OR (StructKeyExists(this.handlers, this.driver) AND NOT this.handlers[this.driver])>
			<cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forNoHandlerAvailable(this.driver)>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Initialize or re-initialize an encrypter
	 *
	 * @param config The Config\Encryption, or an empty string (null)
	 *
	 * @return EncrypterInterface
	 *
	 * @throws EncryptionException
	--->
	<cffunction name="initialize_" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfset var previousKeys = ArrayNew(1)>
		<cfset var configured = ArrayNew(1)>
		<cfset var i = 0>

		<cfif IsObject(arguments.config)>
			<cfset this.key = arguments.config.key>
			<cfset this.driver = arguments.config.driver>
			<cfset this.digest = arguments.config.digest>
		</cfif>

		<cfif Compare(this.driver, "") EQ 0>
			<cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forNoDriverRequested()>
		</cfif>

		<cfif NOT ListFind(ArrayToList(this.drivers), this.driver)>
			<cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forUnKnownHandler(this.driver)>
		</cfif>

		<!--- the key is not empty, and not "0" --->
		<cfif IsBinary(this.key)>
			<cfif ArrayLen(this.key) EQ 0>
				<cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forNeedsStarterKey()>
			</cfif>
		<cfelseif Compare(this.key, "") EQ 0 OR Compare(this.key, "0") EQ 0>
			<cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forNeedsStarterKey()>
		</cfif>

		<!--- Difference: the driver may have been switched by the config after the constructor --->
		<cfif StructKeyExists(this.handlers, this.driver) AND NOT this.handlers[this.driver]>
			<cfset static_("ColdIgniter\Encryption\Exceptions\EncryptionException").forNoHandlerAvailable(this.driver)>
		</cfif>

		<cfset this.encrypter = new_("ColdIgniter\Encryption\Handlers\" & this.driver & "Handler", arguments.config)>

		<!--- (array) '' is [''], not [], so the unset default must be filtered out here. --->
		<cfif IsObject(arguments.config) AND StructKeyExists(arguments.config, "previousKeys")>
			<cfif IsBinary(arguments.config.previousKeys) OR IsSimpleValue(arguments.config.previousKeys)>
				<cfset ArrayAppend(configured, arguments.config.previousKeys)>
			<cfelse>
				<cfset configured = arguments.config.previousKeys>
			</cfif>

			<cfloop from="1" to="#ArrayLen(configured)#" index="i">
				<cfif IsBinary(configured[i]) OR Compare(configured[i], "") NEQ 0>
					<cfset ArrayAppend(previousKeys, configured[i])>
				</cfif>
			</cfloop>
		</cfif>

		<cfif ArrayLen(previousKeys) GT 0>
			<cfset this.encrypter = new_("ColdIgniter\Encryption\KeyRotationDecorator", this.encrypter, previousKeys)>
		</cfif>

		<cfreturn this.encrypter>
	</cffunction>

	<!---
	 * Create a random key
	 *
	 * @param length Output length
	 *
	 * @return A byte array
	--->
	<cffunction name="createKey" access="public" returntype="any" output="no">
		<cfargument name="length" type="numeric" required="no" default="32">

		<cfreturn random_bytes(arguments.length)>
	</cffunction>

	<!---
	 * __get() magic, providing readonly access to some of our protected properties
	 *
	 * @param key Property name
	 *
	 * @return The value, or an empty string (null)
	--->
	<cffunction name="__get" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfif __isset(arguments.key)>
			<cfreturn this[arguments.key]>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * __isset() magic, providing checking for some of our protected properties
	 *
	 * @param key Property name
	--->
	<cffunction name="__isset" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfreturn ListFind("key,digest,driver,drivers", arguments.key) GT 0>
	</cffunction>

</cfcomponent>
