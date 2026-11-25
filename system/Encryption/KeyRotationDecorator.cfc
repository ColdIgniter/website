<!---
 * Key Rotation Decorator
 *
 * Wraps any EncrypterInterface implementation to provide automatic
 * fallback to previous encryption keys during decryption. This enables
 * seamless key rotation without requiring re-encryption of existing data.
 *
 * Difference: __get() and __isset() are public methods that are called by
 * name: handler.__get("cipher"). A null is an empty string, so the
 * params of decrypt_() are null when they are an empty string. A key is
 * text or a byte array.
--->
<cfcomponent output="no" extends="EncrypterInterface" hint="Wraps an encryption handler to fall back to previous keys">

	<!---
	 * The wrapped encryption handler
	 *
	 * @var EncrypterInterface
	--->
	<cfset this.innerHandler = "">

	<!---
	 * Array of previous encryption keys
	 *
	 * @var list<string>
	--->
	<cfset this.previousKeys = ArrayNew(1)>

	<!---
	 * @param innerHandler The wrapped encryption handler
	 * @param previousKeys Array of previous encryption keys
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="innerHandler" type="any" required="yes">
		<cfargument name="previousKeys" type="array" required="yes">

		<cfset this.innerHandler = arguments.innerHandler>
		<cfset this.previousKeys = arguments.previousKeys>

		<cfreturn this>
	</cffunction>

	<!---
	 * {@inheritDoc}
	 *
	 * Encryption always uses the inner handler's current key.
	--->
	<cffunction name="encrypt_" access="public" returntype="any" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">

		<cfreturn this.innerHandler.encrypt_(arguments.data, arguments.params)>
	</cffunction>

	<!---
	 * {@inheritDoc}
	 *
	 * Attempts decryption with current key first. If that fails and no
	 * explicit key was provided in params, tries each previous key.
	 *
	 * @throws EncryptionException
	--->
	<cffunction name="decrypt_" access="public" returntype="any" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfset var explicit = false>
		<cfset var previousParams = "">
		<cfset var i = 0>

		<cftry>
			<cfreturn this.innerHandler.decrypt_(arguments.data, arguments.params)>

			<cfcatch type="ColdIgniter.Encryption.Exceptions.EncryptionException">
				<!--- Don't try previous keys if an explicit key was provided --->
				<cfif IsBinary(arguments.params)>
					<cfset explicit = true>
				<cfelseif IsStruct(arguments.params)>
					<cfset explicit = StructKeyExists(arguments.params, "key")>
				<cfelse>
					<cfset explicit = Compare(arguments.params, "") NEQ 0>
				</cfif>

				<cfif explicit OR ArrayLen(this.previousKeys) EQ 0>
					<cfrethrow>
				</cfif>

				<cfloop from="1" to="#ArrayLen(this.previousKeys)#" index="i">
					<cfif IsStruct(arguments.params)>
						<cfset previousParams = StructCopy(arguments.params)>
						<cfset previousParams.key = this.previousKeys[i]>
					<cfelse>
						<cfset previousParams = this.previousKeys[i]>
					</cfif>

					<cftry>
						<cfreturn this.innerHandler.decrypt_(arguments.data, previousParams)>

						<cfcatch type="ColdIgniter.Encryption.Exceptions.EncryptionException">
							<!--- try the next key --->
						</cfcatch>
					</cftry>
				</cfloop>

				<cfrethrow>
			</cfcatch>
		</cftry>
	</cffunction>

	<!---
	 * Delegate property access to the inner handler.
	 *
	 * @return The value, or an empty string (null)
	--->
	<cffunction name="__get" access="public" returntype="any" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfif method_exists(this.innerHandler, "__get")>
			<cfreturn this.innerHandler.__get(arguments.key)>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * Delegate property existence check to inner handler.
	--->
	<cffunction name="__isset" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfif method_exists(this.innerHandler, "__isset")>
			<cfreturn this.innerHandler.__isset(arguments.key)>
		</cfif>

		<cfreturn false>
	</cffunction>

</cfcomponent>
