<!---
 * Finds whether a variable is a number or a numeric string.
 *
 * Whitespace before and after, a sign, a fraction and an exponent are
 * allowed, as they are in the original (also "1e5", ".5" and "1.").
 * A hexadecimal string ("0x1A") and an empty string are not numeric.
 * IsNumeric() accepts more (also currency and thousands separators),
 * so it is not used.
 *
 * Difference: an array or a map is not numeric.
--->
<cffunction name="is_numeric" returntype="boolean" output="no" hint="Finds whether a variable is a number or a numeric string">
	<cfargument name="value" type="any" required="yes">

	<cfif NOT IsSimpleValue(arguments.value)>
		<cfreturn false>
	</cfif>

	<cfreturn JavaCast("string", arguments.value).matches("[ \t\n\r\x0B\f]*[+-]?([0-9]+(\.[0-9]*)?|\.[0-9]+)([eE][+-]?[0-9]+)?[ \t\n\r\x0B\f]*")>
</cffunction>
