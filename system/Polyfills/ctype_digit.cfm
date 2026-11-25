<!---
 * Checks for numeric characters: true when the string is not empty and
 * has only the digits 0 to 9.
 *
 * Difference: a number is not accepted as it is in the original (an
 * integer between -128 and 255 is read as a character code); every value
 * is text here, so it is always checked as text.
--->
<cffunction name="ctype_digit" returntype="boolean" output="no" hint="Checks for numeric characters">
	<cfargument name="text" type="string" required="yes">

	<!---
	 * the test is for one character that is not a digit, so a long string
	 * is read once. An anchored "^[0-9]+$" is not used: it also accepts a
	 * line feed after the digits, and digits of other scripts.
	--->
	<cfreturn Len(arguments.text) GT 0 AND REFind("[^0-9]", arguments.text) EQ 0>
</cffunction>
