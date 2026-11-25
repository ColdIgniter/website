<!---
 * Formats a number with grouped thousands and a given number of decimals.
 *
 * Difference: the number is rounded half up from its exact binary value
 * (java.math.BigDecimal), where the original rounds the decimal form, so a
 * value like 0.285 can end one digit lower.
--->
<cffunction name="number_format" returntype="string" output="no" hint="Formats a number with grouped thousands">
	<cfargument name="num" type="numeric" required="yes">
	<cfargument name="decimals" type="numeric" required="no" default="0">
	<cfargument name="decimalSeparator" type="string" required="no" default=".">
	<cfargument name="thousandsSeparator" type="string" required="no" default=",">
	<cfset var plain = "">
	<cfset var sign = "">
	<cfset var whole = "">
	<cfset var fraction = "">
	<cfset var grouped = "">
	<cfset var dot = 0>

	<cfset plain = CreateObject("java", "java.math.BigDecimal").init(JavaCast("double", arguments.num)).setScale(JavaCast("int", arguments.decimals), 4).toString()>

	<cfif Left(plain, 1) EQ "-">
		<cfset sign = "-">
		<cfset plain = Mid(plain, 2, Len(plain))>
	</cfif>

	<cfset dot = Find(".", plain)>
	<cfif dot GT 0>
		<cfset whole = Left(plain, dot - 1)>
		<cfset fraction = Mid(plain, dot + 1, Len(plain))>
	<cfelse>
		<cfset whole = plain>
	</cfif>

	<cfloop condition="Len(whole) GT 3">
		<cfset grouped = arguments.thousandsSeparator & Right(whole, 3) & grouped>
		<cfset whole = Left(whole, Len(whole) - 3)>
	</cfloop>
	<cfset grouped = whole & grouped>

	<!--- the original prints no sign for a value that rounds to zero --->
	<cfif sign EQ "-" AND REFind("[1-9]", plain) EQ 0>
		<cfset sign = "">
	</cfif>

	<cfif fraction EQ "">
		<cfreturn sign & grouped>
	</cfif>

	<cfreturn sign & grouped & arguments.decimalSeparator & fraction>
</cffunction>
