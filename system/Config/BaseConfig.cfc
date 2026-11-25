<!---
 * Class BaseConfig
 *
 * Not completely abstract, but should be used as the base class for
 * any config code.
 *
 * Not intended to be used on its own, this class will attempt to
 * automatically populate the child class' properties with values
 * from the environment.
 *
 * These can be set within the .env file. The values live in
 * request.ColdIgniter.env (see Config/DotEnv.cfc), where $_ENV and
 * $_SERVER of the original are one struct.
 *
 * Difference: the properties of the object are found by looping over
 * "this", which gives every name in upper case. A name from the .env file
 * is matched without regard to case, so this does not matter. A function
 * is not a property and is skipped, so are the names that start with "__".
 *
 * Difference: there is no null, so getEnvValue() returns a list that is
 * empty when there is no value, and has the value as its only element.
 *
 * Difference: the prefix is the name of the class as the server knows it,
 * for a class of the application "Config\Logger".
 *
 * Difference: the keys of an Encryption class (the properties key and
 * previousKeys) are parsed for the prefixes hex2bin: and base64:, and
 * are byte arrays then (see random_bytes()), as a binary string is. A
 * previousKeys of text is cut at the commas, and an empty element is
 * dropped (a list function skips it). The class is found by its name
 * (the short prefix is "encryption"), as there is no instanceof of a
 * class that may not be loaded. A base64: key that is not valid base64
 * is an error, where the original has a TypeError. The message never has
 * the key.
 *
 * Not ported yet: the registrars (registrars, override, didDiscovery,
 * registerProperties, setModules and reset), and the config cache
 * (__set_state).
--->
<cfcomponent output="no" hint="The base class for any config code">

	<!---
	 * An optional array of classes that will act as Registrars
	 * for rapidly setting config class properties.
	 *
	 * Not ported yet: the registrars
	--->

	<!---
	 * Will attempt to get environment variables with names
	 * that match the properties of the child class.
	 *
	 * The "shortPrefix" is the lowercase-only config class name.
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfset var properties = ArrayNew(1)>
		<cfset var property = "">
		<cfset var prefix = this.__class>
		<cfset var shortPrefix = LCase(ListLast(prefix, "\"))>
		<cfset var i = 0>
		<cfset var key = "">
		<cfset var wanted = false>
		<cfset var shortLength = Len(shortPrefix) + 1>
		<cfset var prefixLength = Len(prefix) + 1>
		<cfset var keysArray = "">
		<cfset var parsedKeys = "">
		<cfset var j = 0>

		<!--- Not ported yet: static::$moduleConfig and registerProperties() --->

		<!---
		 * Difference: every name getEnvValue() looks for starts with the
		 * prefix or the short prefix and then "." or "_". When the
		 * environment has no name that starts so, no property can get a
		 * value from it, and the walk over the properties is left out.
		 * Names are compared without regard to case, as the keys of the
		 * environment are.
		--->
		<cfloop collection="#request.ColdIgniter.env#" item="key">
			<cfif CompareNoCase(Left(key, shortLength), shortPrefix & ".") EQ 0 OR CompareNoCase(Left(key, shortLength), shortPrefix & "_") EQ 0 OR CompareNoCase(Left(key, prefixLength), prefix & ".") EQ 0 OR CompareNoCase(Left(key, prefixLength), prefix & "_") EQ 0>
				<cfset wanted = true>
				<cfbreak>
			</cfif>
		</cfloop>

		<!--- Difference: the keys of the Encryption config are parsed whatever the environment holds --->
		<cfif NOT wanted AND Compare(shortPrefix, "encryption") NEQ 0>
			<cfreturn this>
		</cfif>

		<cfloop collection="#this#" item="property">
			<cfif Compare(Left(property, 2), "__") NEQ 0 AND NOT IsCustomFunction(this[property])>
				<cfset ArrayAppend(properties, property)>
			</cfif>
		</cfloop>

		<cfloop from="1" to="#ArrayLen(properties)#" index="i">
			<cfset this[properties[i]] = initEnvValue(this[properties[i]], properties[i], prefix, shortPrefix)>

			<cfif Compare(shortPrefix, "encryption") EQ 0>
				<cfif CompareNoCase(properties[i], "key") EQ 0>
					<cfset this[properties[i]] = parseEncryptionKey(this[properties[i]])>
				<cfelseif CompareNoCase(properties[i], "previousKeys") EQ 0>
					<cfif IsBinary(this[properties[i]])>
						<cfset keysArray = ArrayNew(1)>
						<cfset ArrayAppend(keysArray, this[properties[i]])>
					<cfelseif IsSimpleValue(this[properties[i]])>
						<cfset keysArray = ListToArray(this[properties[i]], ",")>

						<cfloop from="1" to="#ArrayLen(keysArray)#" index="j">
							<cfset keysArray[j] = Trim(keysArray[j])>
						</cfloop>
					<cfelse>
						<cfset keysArray = this[properties[i]]>
					</cfif>

					<cfset parsedKeys = ArrayNew(1)>

					<cfloop from="1" to="#ArrayLen(keysArray)#" index="j">
						<cfset ArrayAppend(parsedKeys, parseEncryptionKey(keysArray[j]))>
					</cfloop>

					<cfset this[properties[i]] = parsedKeys>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn this>
	</cffunction>

	<!---
	 * Parse encryption key with hex2bin: or base64: prefix
	 *
	 * @param key The key, as text or a byte array
	 *
	 * @return A byte array for a prefixed key, the key as it is otherwise
	--->
	<cffunction name="parseEncryptionKey" access="private" returntype="any" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfset var encoded = "">

		<cfif IsBinary(arguments.key)>
			<cfreturn arguments.key>
		</cfif>

		<cfif Compare(Left(arguments.key, 8), "hex2bin:") EQ 0>
			<cfreturn hex2bin(Mid(arguments.key, 9, Len(arguments.key)))>
		</cfif>

		<cfif Compare(Left(arguments.key, 7), "base64:") EQ 0>
			<cfset encoded = Mid(arguments.key, 8, Len(arguments.key))>

			<cfif Len(encoded) EQ 0>
				<cfreturn "">
			</cfif>

			<!--- the strict mode of the original: only the base64 characters, padded or not --->
			<cfif REFind("^[A-Za-z0-9+/]+={0,2}$", encoded) EQ 0 OR (Len(encoded) MOD 4 EQ 1)>
				<cfthrow type="ColdIgniter.ErrorException" message="base64_decode(): The encryption key is not valid base64">
			</cfif>

			<cfif Len(encoded) MOD 4 NEQ 0>
				<cfset encoded = encoded & Left("===", 4 - (Len(encoded) MOD 4))>
			</cfif>

			<cfreturn ToBinary(encoded)>
		</cfif>

		<cfreturn arguments.key>
	</cffunction>

	<!---
	 * Initialization an environment-specific configuration setting
	 *
	 * Difference: there are no references, so the new value of the
	 * property is returned, and the caller assigns it.
	 *
	 * @param property A string, a number, a boolean, or a list or map of them
	 *
	 * @return The property, with the value of the environment when there is one
	--->
	<cffunction name="initEnvValue" access="private" returntype="any" output="no">
		<cfargument name="property" type="any" required="yes">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="prefix" type="string" required="yes">
		<cfargument name="shortPrefix" type="string" required="yes">
		<cfset var key = "">
		<cfset var keys = ArrayNew(1)>
		<cfset var found = "">
		<cfset var value = "">
		<cfset var list = ArrayNew(1)>
		<cfset var i = 0>

		<cfif IsArray(arguments.property)>
			<!--- an array is not copied on the way in, so a new one is built --->
			<cfloop from="1" to="#ArrayLen(arguments.property)#" index="i">
				<cfset ArrayAppend(list, initEnvValue(arguments.property[i], arguments.name & "." & (i - 1), arguments.prefix, arguments.shortPrefix))>
			</cfloop>

			<cfreturn list>
		</cfif>

		<cfif IsStruct(arguments.property)>
			<cfloop collection="#arguments.property#" item="key">
				<cfset ArrayAppend(keys, key)>
			</cfloop>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset arguments.property[keys[i]] = initEnvValue(arguments.property[keys[i]], arguments.name & "." & keys[i], arguments.prefix, arguments.shortPrefix)>
			</cfloop>

			<cfreturn arguments.property>
		</cfif>

		<cfset found = getEnvValue(arguments.name, arguments.prefix, arguments.shortPrefix)>

		<cfif ArrayLen(found) EQ 0>
			<cfreturn arguments.property>
		</cfif>

		<cfset value = found[1]>

		<!--- Difference: Compare() is used, since CFML equality treats "yes" as true and "no" as false --->
		<cfif Compare(value, "false") EQ 0>
			<cfreturn false>
		<cfelseif Compare(value, "true") EQ 0>
			<cfreturn true>
		</cfif>

		<cfset value = trim_(value, "'""")>

		<!--- is_int() and is_float() --->
		<cfif IsNumeric(arguments.property) AND arguments.property.getClass().getName() NEQ "java.lang.Boolean">
			<cfif Int(arguments.property) EQ arguments.property>
				<cfset value = Int(Val(value))>
			<cfelse>
				<cfset value = Val(value)>
			</cfif>
		</cfif>

		<cfreturn value>
	</cffunction>

	<!---
	 * Retrieve an environment-specific configuration setting
	 *
	 * @return A list with the value, or an empty list
	--->
	<cffunction name="getEnvValue" access="private" returntype="array" output="no">
		<cfargument name="property" type="string" required="yes">
		<cfargument name="prefix" type="string" required="yes">
		<cfargument name="shortPrefix" type="string" required="yes">
		<cfset var result = ArrayNew(1)>
		<cfset var underscoreProperty = Replace(arguments.property, ".", "_", "all")>
		<cfset var candidates = ArrayNew(1)>
		<cfset var i = 0>

		<cfif Left(arguments.shortPrefix, 1) EQ "\">
			<cfset arguments.shortPrefix = ltrim_(arguments.shortPrefix, "\")>
		</cfif>

		<!--- $_ENV and $_SERVER are the same struct, so each name is looked up once --->
		<cfset ArrayAppend(candidates, arguments.shortPrefix & "." & arguments.property)>
		<cfset ArrayAppend(candidates, arguments.shortPrefix & "_" & underscoreProperty)>
		<cfset ArrayAppend(candidates, arguments.prefix & "." & arguments.property)>
		<cfset ArrayAppend(candidates, arguments.prefix & "_" & underscoreProperty)>

		<cfloop from="1" to="#ArrayLen(candidates)#" index="i">
			<cfif StructKeyExists(request.ColdIgniter.env, candidates[i])>
				<cfset ArrayAppend(result, request.ColdIgniter.env[candidates[i]])>

				<cfreturn result>
			</cfif>
		</cfloop>

		<cfreturn result>
	</cffunction>

</cfcomponent>
