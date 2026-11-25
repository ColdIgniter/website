<!---
 * Class Header
 *
 * Represents a single HTTP header.
 *
 * A value is a string, or an array that holds strings and maps (a map
 * of "key" to "val" is a "key=val" option). The original keeps a list
 * with string keys the same way.
 *
 * Difference: Message creates this class with CreateObject() and calls
 * __construct() itself, as it is made for every header of every request
 * and new_() costs several times as much (it copies the global functions
 * into the object and runs the constructor through Evaluate). So the
 * class uses only the functions of the engine: no global function
 * (is_null(), implode() ...) is there, and the object has no __class.
 * An object made with new_() works the same.
 *
 * Difference: an omitted value (no argument) is null. A value that is
 * not a string, a number, an array or a map throws an
 * InvalidArgumentException (the original: an Error). The list of an array that
 * is given is copied (an array of the original is a value); the maps in
 * it, and a map that is given, are kept as they are.
--->
<cfcomponent output="no" hint="Represents a single HTTP header">

	<!---
	 * The header name.
	 *
	 * @var string
	--->
	<cfset this.name = "">

	<!---
	 * The value(s) of the header: a string, or an array of values.
	 *
	 * @var array|string
	--->
	<cfset this.value = "">

	<!---
	 * Header constructor. name is mandatory, if a value is provided,
	 * it will be set.
	 *
	 * @param value array|string|null
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="value" type="any" required="no">

		<cfset setName(arguments.name)>

		<cfif StructKeyExists(arguments, "value")>
			<cfset setValue(arguments.value)>
		<cfelse>
			<cfset setValue()>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Returns the name of the header, in the same case it was set.
	--->
	<cffunction name="getName" access="public" returntype="string" output="no">
		<cfreturn this.name>
	</cffunction>

	<!---
	 * Gets the raw value of the header. This may return either a string
	 * or an array, depending on whether the header has multiple values or not.
	 *
	 * @return array|string
	--->
	<cffunction name="getValue" access="public" returntype="any" output="no">
		<cfreturn this.value>
	</cffunction>

	<!---
	 * Sets the name of the header, overwriting any previous value.
	 *
	 * @return Header
	--->
	<cffunction name="setName" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfset validateName(arguments.name)>

		<cfset this.name = arguments.name>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the value of the header, overwriting any previous value(s).
	 *
	 * @param value array|string|null
	 *
	 * @return Header
	--->
	<cffunction name="setValue" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="no">
		<cfset var i = 0>

		<cfif NOT StructKeyExists(arguments, "value")>
			<cfset this.value = "">
			<cfreturn this>
		</cfif>

		<cfif IsSimpleValue(arguments.value)>
			<cfset arguments.value = arguments.value & "">

			<!--- the check of validateValue(), for the usual single string --->
			<cfif NOT JavaCast("string", arguments.value).matches("[\x20\x09\x21-\x7E\u0080-\uFFFF]*")>
				<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="The header value is not valid as per RFC 7230.">
			</cfif>

			<cfset this.value = arguments.value>

			<cfreturn this>
		</cfif>

		<cfset validateValue(arguments.value)>

		<cfif IsArray(arguments.value)>
			<!--- a copy of the list, as appendValue() changes the array in place --->
			<cfset this.value = ArrayNew(1)>

			<cfloop from="1" to="#ArrayLen(arguments.value)#" index="i">
				<cfset ArrayAppend(this.value, arguments.value[i])>
			</cfloop>
		<cfelse>
			<cfset this.value = arguments.value>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Appends a value to the existing value(s). A value that the header
	 * has already is not added again.
	 *
	 * @param value array|string|null
	 *
	 * @return Header
	--->
	<cffunction name="appendValue" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="no">
		<cfset var first = this.value>

		<cfif NOT StructKeyExists(arguments, "value")>
			<cfreturn this>
		</cfif>

		<cfset validateValue(arguments.value)>

		<cfif NOT IsArray(this.value)>
			<cfset this.value = ArrayNew(1)>
			<cfset ArrayAppend(this.value, first)>
		</cfif>

		<cfif NOT hasValue(arguments.value)>
			<cfif IsSimpleValue(arguments.value)>
				<cfset ArrayAppend(this.value, arguments.value & "")>
			<cfelse>
				<cfset ArrayAppend(this.value, arguments.value)>
			</cfif>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Prepends a value to the existing value(s).
	 *
	 * @param value array|string|null
	 *
	 * @return Header
	--->
	<cffunction name="prependValue" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="no">
		<cfset var first = this.value>

		<cfif NOT StructKeyExists(arguments, "value")>
			<cfreturn this>
		</cfif>

		<cfset validateValue(arguments.value)>

		<cfif NOT IsArray(this.value)>
			<cfset this.value = ArrayNew(1)>
			<cfset ArrayAppend(this.value, first)>
		</cfif>

		<cfset ArrayPrepend(this.value, arguments.value)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Retrieves a comma-separated string of the values for a single header.
	 *
	 * NOTE: Not all header values may be appropriately represented using
	 * comma concatenation.
	 *
	 * @see https://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.2
	--->
	<cffunction name="getValueLine" access="public" returntype="string" output="no">
		<cfset var options = "">
		<cfset var it = "">
		<cfset var key = "">
		<cfset var item = "">
		<cfset var i = 0>

		<cfif IsSimpleValue(this.value)>
			<cfreturn this.value>
		</cfif>

		<cfset options = ArrayNew(1)>

		<cfif IsStruct(this.value)>
			<cfset it = this.value.keySet().iterator()>

			<cfloop condition="it.hasNext()">
				<cfset key = it.next()>
				<cfset item = this.value.get(key)>

				<cfif IsSimpleValue(item)>
					<cfset ArrayAppend(options, key & "=" & item)>
				<cfelse>
					<cfset ArrayAppend(options, optionLine(item))>
				</cfif>
			</cfloop>
		<cfelse>
			<cfloop from="1" to="#ArrayLen(this.value)#" index="i">
				<cfset item = this.value[i]>

				<cfif IsSimpleValue(item)>
					<cfset ArrayAppend(options, item)>
				<cfelse>
					<cfset ArrayAppend(options, optionLine(item))>
				</cfif>
			</cfloop>
		</cfif>

		<cfreturn ArrayToList(options, ", ")>
	</cffunction>

	<!---
	 * Returns a representation of the entire header string, including
	 * the header name and all values converted to the proper format.
	--->
	<cffunction name="__toString" access="public" returntype="string" output="no">
		<cfreturn this.name & ": " & getValueLine()>
	</cffunction>

	<!---
	 * Not in the original, where the body of getValueLine() holds it.
	 * The "key=value" of a value that is itself an array: the first
	 * key of a map, and 0 for the first value of a list.
	 *
	 * @param item array|struct
	--->
	<cffunction name="optionLine" access="private" returntype="string" output="no">
		<cfargument name="item" type="any" required="yes">
		<cfset var key = "">

		<cfif IsStruct(arguments.item)>
			<cfif arguments.item.size() EQ 0>
				<cfreturn "">
			</cfif>

			<cfset key = arguments.item.keySet().iterator().next()>

			<cfreturn key & "=" & arguments.item.get(key)>
		</cfif>

		<cfif ArrayLen(arguments.item) EQ 0>
			<cfreturn "">
		</cfif>

		<cfreturn "0=" & arguments.item[1]>
	</cffunction>

	<!---
	 * Not in the original, where in_array() with the strict flag does it.
	 * Finds whether the value is one of the values of the header, with
	 * the same text and case (or, for an array or a map, the same entries).
	 *
	 * @param value array|string
	--->
	<cffunction name="hasValue" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(this.value)#" index="i">
			<cfif sameValue(this.value[i], arguments.value)>
				<cfreturn true>
			</cfif>
		</cfloop>

		<cfreturn false>
	</cffunction>

	<!---
	 * Not in the original. Finds whether two values are identical.
	--->
	<cffunction name="sameValue" access="private" returntype="boolean" output="no">
		<cfargument name="a" type="any" required="yes">
		<cfargument name="b" type="any" required="yes">
		<cfset var i = 0>
		<cfset var it = "">
		<cfset var key = "">

		<cfif IsSimpleValue(arguments.a) AND IsSimpleValue(arguments.b)>
			<cfreturn Compare(arguments.a, arguments.b) EQ 0>
		</cfif>

		<cfif IsArray(arguments.a) AND IsArray(arguments.b)>
			<cfif ArrayLen(arguments.a) NEQ ArrayLen(arguments.b)>
				<cfreturn false>
			</cfif>

			<cfloop from="1" to="#ArrayLen(arguments.a)#" index="i">
				<cfif NOT sameValue(arguments.a[i], arguments.b[i])>
					<cfreturn false>
				</cfif>
			</cfloop>

			<cfreturn true>
		</cfif>

		<cfif IsStruct(arguments.a) AND IsStruct(arguments.b)>
			<cfif arguments.a.size() NEQ arguments.b.size()>
				<cfreturn false>
			</cfif>

			<cfset it = arguments.a.keySet().iterator()>

			<cfloop condition="it.hasNext()">
				<cfset key = it.next()>

				<cfif NOT arguments.b.containsKey(key) OR NOT sameValue(arguments.a.get(key), arguments.b.get(key))>
					<cfreturn false>
				</cfif>
			</cfloop>

			<cfreturn true>
		</cfif>

		<cfreturn false>
	</cffunction>

	<!---
	 * Validate header name.
	 *
	 * Regex is based on code from a guzzlehttp/psr7 library.
	 *
	 * @see https://datatracker.ietf.org/doc/html/rfc7230#section-3.2
	 *
	 * @throws InvalidArgumentException
	--->
	<cffunction name="validateName" access="private" returntype="void" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfif NOT JavaCast("string", arguments.name).matches("[a-zA-Z0-9'`##$%&*+.^_|~!-]+")>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="The header name is not valid as per RFC 7230.">
		</cfif>
	</cffunction>

	<!---
	 * Validate header value.
	 *
	 * Checks the value, and for an array each key and value in it.
	 * The original checks the bytes of a value; a CFML string holds
	 * characters, so all characters from U+0080 up stand for the bytes
	 * \x80-\xFF of their UTF-8 form.
	 *
	 * @see https://datatracker.ietf.org/doc/html/rfc7230#section-3.2
	 *
	 * @param value array|string
	 *
	 * @throws InvalidArgumentException
	--->
	<cffunction name="validateValue" access="private" returntype="void" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfset var i = 0>
		<cfset var it = "">
		<cfset var key = "">

		<cfif IsSimpleValue(arguments.value)>
			<!--- The regular expression excludes obs-fold per RFC 7230#3.2.4 --->
			<cfif NOT JavaCast("string", arguments.value).matches("[\x20\x09\x21-\x7E\u0080-\uFFFF]*")>
				<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="The header value is not valid as per RFC 7230.">
			</cfif>

			<cfreturn>
		</cfif>

		<!--- a component passes IsStruct, so an object is turned away first --->
		<cfif IsObject(arguments.value)>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="The header value must be a string or an array.">
		</cfif>

		<cfif IsArray(arguments.value)>
			<cfloop from="1" to="#ArrayLen(arguments.value)#" index="i">
				<cfset validateValue(arguments.value[i])>
			</cfloop>

			<cfreturn>
		</cfif>

		<cfif IsStruct(arguments.value)>
			<cfset it = arguments.value.keySet().iterator()>

			<cfloop condition="it.hasNext()">
				<cfset key = it.next()>

				<cfset validateValue(key)>
				<cfset validateValue(arguments.value.get(key))>
			</cfloop>

			<cfreturn>
		</cfif>

		<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="The header value must be a string or an array.">
	</cffunction>

</cfcomponent>
