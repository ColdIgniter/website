<!---
 * Gives the number of bytes that a string has in UTF-8. Not in the
 * original: serialize() writes the length of a string in bytes.
--->
<cffunction name="serialize_bytes_" returntype="numeric" output="no" hint="Gives the number of bytes of a string in UTF-8">
	<cfargument name="text" type="string" required="yes">
	<cfset var jstr = JavaCast("string", arguments.text)>
	<cfset var two = Len(jstr.replaceAll("[^\u0080-\u07FF]", ""))>
	<cfset var three = Len(jstr.replaceAll("[^\u0800-\uD7FF\uE000-\uFFFF]", ""))>
	<cfset var pairs = Len(jstr.replaceAll("[^\uD800-\uDFFF]", "")) / 2>

	<!--- one byte for each character, one more for two byte ones, two more for three byte ones, and two more for each pair of surrogates (four bytes in all) --->
	<cfreturn Len(arguments.text) + two + three * 2 + Fix(pairs) * 2>
</cffunction>

<!---
 * Writes a string as "s:bytes:"text";". Not in the original.
--->
<cffunction name="serialize_string_" returntype="string" output="no" hint="Serializes a string">
	<cfargument name="text" type="string" required="yes">

	<cfreturn "s:" & serialize_bytes_(arguments.text) & ":""" & arguments.text & """;">
</cffunction>

<!---
 * Generates a storable representation of a value, in the format of the
 * original ("a:1:{s:1:"a";s:1:"b";}"), so a column written by the original
 * can be read by unserialize() and the other way round.
 *
 * Difference: the platform has no types, so the type of a value is taken
 * from its Java class, as json_encode() does: a Boolean gives b:, an
 * Integer, Long, Short or BigInteger gives i:, a Double, Float or
 * BigDecimal gives d:, and everything else (also a number written as a
 * literal) gives s:. A list gives an array with the keys 0, 1, 2 and a map
 * gives an array with its keys; a key that is a whole number gives an
 * integer key. A null is an empty string, so it is s:0:"";.
 *
 * Not ported yet: objects (a component throws).
--->
<cffunction name="serialize" returntype="string" output="no" hint="Generates a storable representation of a value">
	<cfargument name="value" type="any" required="yes">
	<cfset var buf = CreateObject("java", "java.lang.StringBuffer").init()>
	<cfset var cls = "">
	<cfset var keys = "">
	<cfset var key = "">
	<cfset var i = 0>

	<cfif IsArray(arguments.value)>
		<cfset buf.append("a:" & ArrayLen(arguments.value) & ":{")>

		<cfloop from="1" to="#ArrayLen(arguments.value)#" index="i">
			<cfset buf.append("i:" & (i - 1) & ";")>
			<cfset buf.append(serialize(arguments.value[i]))>
		</cfloop>

		<cfset buf.append("}")>

		<cfreturn buf.toString()>
	</cfif>

	<cfif IsObject(arguments.value)>
		<cfthrow type="ColdIgniter.LogicException" message="Not ported yet: serialize() of an object.">
	</cfif>

	<cfif IsStruct(arguments.value)>
		<cfset keys = StructKeyArray(arguments.value)>

		<cfif Compare(arguments.value.getClass().getName(), "java.util.LinkedHashMap") EQ 0>
			<cfset keys = array_keys(arguments.value)>
		</cfif>

		<cfset buf.append("a:" & ArrayLen(keys) & ":{")>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset key = keys[i]>

			<cfif REFind("^(0|-?[1-9][0-9]*)$", key) GT 0>
				<cfset buf.append("i:" & key & ";")>
			<cfelse>
				<cfset buf.append(serialize_string_(key))>
			</cfif>

			<cfset buf.append(serialize(arguments.value[key]))>
		</cfloop>

		<cfset buf.append("}")>

		<cfreturn buf.toString()>
	</cfif>

	<cfset cls = arguments.value.getClass().getName()>

	<cfif Compare(cls, "java.lang.Boolean") EQ 0>
		<cfif arguments.value>
			<cfreturn "b:1;">
		</cfif>

		<cfreturn "b:0;">
	</cfif>

	<cfif ListFind("java.lang.Integer,java.lang.Long,java.lang.Short,java.math.BigInteger", cls) GT 0>
		<cfreturn "i:" & arguments.value & ";">
	</cfif>

	<cfif ListFind("java.lang.Double,java.lang.Float,java.math.BigDecimal", cls) GT 0>
		<cfreturn "d:" & arguments.value & ";">
	</cfif>

	<cfreturn serialize_string_(arguments.value & "")>
</cffunction>
