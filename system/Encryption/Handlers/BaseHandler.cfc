<!---
 * Base class for encryption handlers.
 *
 * Difference: the properties are in "this", protected ones too.
 * __get() and __isset() are public methods that are called by name:
 * handler.__get("cipher").
 *
 * Difference: substr_() works on byte arrays (the 8bit mb_substr() of the
 * original), as a binary string is a Java byte array here. It is a copy
 * of the slice.
--->
<cfcomponent output="no" parent="ColdIgniter\Encryption\EncrypterInterface" hint="Base class for encryption handlers">

	<!---
	 * Constructor
	 *
	 * Makes the parameters of the config conveniently accessible: every
	 * property of the config that the handler has too is set.
	 *
	 * @param config The Config\Encryption, or an empty string (null) for the one of config()
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="no" default="">
		<cfset var name = "">

		<cfif is_null(arguments.config)>
			<cfset arguments.config = variables.config("Config\Encryption")>
		</cfif>

		<cfloop collection="#arguments.config#" item="name">
			<cfif Compare(Left(name, 2), "__") NEQ 0 AND NOT IsCustomFunction(arguments.config[name])>
				<cfif StructKeyExists(this, name) AND NOT IsCustomFunction(this[name])>
					<cfset this[name] = arguments.config[name]>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn this>
	</cffunction>

	<!---
	 * Byte-wise substr()
	 *
	 * @param str    A byte array
	 * @param start  The 0-based start
	 * @param length The number of bytes, or -1 (null) for the rest
	 *
	 * @return A new byte array
	--->
	<cffunction name="substr_" access="private" returntype="any" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="start" type="numeric" required="yes">
		<cfargument name="length" type="numeric" required="no" default="-1">
		<cfset var size = ArrayLen(arguments.str)>
		<cfset var result = "">

		<cfif arguments.start GT size>
			<cfset arguments.start = size>
		</cfif>

		<cfif arguments.length LT 0 OR arguments.start + arguments.length GT size>
			<cfset arguments.length = size - arguments.start>
		</cfif>

		<!--- an array of the right size to fill; the string holds ASCII only --->
		<cfset result = JavaCast("string", RepeatString("x", arguments.length)).getBytes()>
		<cfset CreateObject("java", "java.lang.System").arraycopy(arguments.str, JavaCast("int", arguments.start), result, JavaCast("int", 0), JavaCast("int", arguments.length))>

		<cfreturn result>
	</cffunction>

	<!---
	 * Property access, read-only: the properties of the handler.
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
	 * Property check: a property of the handler (a function is not one).
	--->
	<cffunction name="__isset" access="public" returntype="boolean" output="no">
		<cfargument name="key" type="string" required="yes">

		<cfreturn StructKeyExists(this, arguments.key) AND NOT IsCustomFunction(this[arguments.key])>
	</cffunction>

</cfcomponent>
