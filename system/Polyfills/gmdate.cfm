<!---
 * Formats a Unix timestamp as a date and time in UTC.
 *
 * Supported letters: D d j M F Y y H i s T, and a backslash to escape the
 * next character. T gives GMT. Any other character is kept as it is. The
 * names of days and months are in English. The timestamp is the seconds
 * since 1970-01-01 UTC, the default is now.
--->
<cffunction name="gmdate" returntype="string" output="no" hint="Formats a Unix timestamp in UTC">
	<cfargument name="format" type="string" required="yes">
	<cfargument name="timestamp" type="any" required="no" default="">
	<cfset var ts = arguments.timestamp>
	<cfset var result = "">
	<cfset var letter = "">
	<cfset var pattern = "">
	<cfset var i = 1>
	<cfset var df = "">
	<cfset var date = "">

	<cfif NOT Len(ts)>
		<cfset ts = time()>
	</cfif>

	<!--- the milliseconds do not fit in an integer, so they are built from text --->
	<cfset date = CreateObject("java", "java.util.Date").init(CreateObject("java", "java.lang.Long").parseLong(JavaCast("string", Int(ts) & "000")))>

	<cfloop condition="i LTE Len(arguments.format)">
		<cfset letter = Mid(arguments.format, i, 1)>
		<cfset pattern = "">

		<cfif Compare(letter, "\") EQ 0>
			<cfset i = i + 1>
			<cfset result = result & Mid(arguments.format, i, 1)>
		<cfelse>
			<cfif Compare(letter, "D") EQ 0>
				<cfset pattern = "EEE">
			<cfelseif Compare(letter, "d") EQ 0>
				<cfset pattern = "dd">
			<cfelseif Compare(letter, "j") EQ 0>
				<cfset pattern = "d">
			<cfelseif Compare(letter, "M") EQ 0>
				<cfset pattern = "MMM">
			<cfelseif Compare(letter, "F") EQ 0>
				<cfset pattern = "MMMM">
			<cfelseif Compare(letter, "Y") EQ 0>
				<cfset pattern = "yyyy">
			<cfelseif Compare(letter, "y") EQ 0>
				<cfset pattern = "yy">
			<cfelseif Compare(letter, "H") EQ 0>
				<cfset pattern = "HH">
			<cfelseif Compare(letter, "i") EQ 0>
				<cfset pattern = "mm">
			<cfelseif Compare(letter, "s") EQ 0>
				<cfset pattern = "ss">
			</cfif>

			<cfif Len(pattern)>
				<cfset df = CreateObject("java", "java.text.SimpleDateFormat").init(pattern, CreateObject("java", "java.util.Locale").US)>
				<cfset df.setTimeZone(CreateObject("java", "java.util.TimeZone").getTimeZone("UTC"))>
				<cfset result = result & df.format(date)>
			<cfelseif Compare(letter, "T") EQ 0>
				<cfset result = result & "GMT">
			<cfelse>
				<cfset result = result & letter>
			</cfif>
		</cfif>

		<cfset i = i + 1>
	</cfloop>

	<cfreturn result>
</cffunction>
