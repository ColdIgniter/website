<!---
 * Formats a date and time with the letters of the original.
 *
 * Supported letters: d j D l N w m n M F Y y a A g G h H i s u, and a
 * backslash to escape the next character. Any other character is kept as
 * it is. The timestamp is a CFML date and time, the default is now. A
 * microsecond is not known, the letter u gives the milliseconds and 000.
--->
<cffunction name="date" returntype="string" output="no" hint="Formats a date and time">
	<cfargument name="format" type="string" required="yes">
	<cfargument name="timestamp" type="any" required="no" default="#Now()#">
	<cfset var result = "">
	<cfset var letter = "">
	<cfset var position = 0>
	<cfset var weekday = DayOfWeek(arguments.timestamp)>
	<cfset var i = 1>

	<cfloop condition="i LTE Len(arguments.format)">
		<cfset letter = Mid(arguments.format, i, 1)>

		<!--- A switch does not tell d from D, so the letter is turned into its position --->
		<cfset position = Find(letter, "djDlNwmnMFYyaAgGhHisu")>

		<cfif Compare(letter, "\") EQ 0>
			<cfset i = i + 1>
			<cfset result = result & Mid(arguments.format, i, 1)>
		<cfelse>
			<cfswitch expression="#position#">
				<cfcase value="1"><cfset result = result & DateFormat(arguments.timestamp, "dd")></cfcase>
				<cfcase value="2"><cfset result = result & DateFormat(arguments.timestamp, "d")></cfcase>
				<cfcase value="3"><cfset result = result & DateFormat(arguments.timestamp, "ddd")></cfcase>
				<cfcase value="4"><cfset result = result & DateFormat(arguments.timestamp, "dddd")></cfcase>
				<cfcase value="5"><cfset result = result & ((weekday + 5) MOD 7 + 1)></cfcase>
				<cfcase value="6"><cfset result = result & (weekday - 1)></cfcase>
				<cfcase value="7"><cfset result = result & DateFormat(arguments.timestamp, "mm")></cfcase>
				<cfcase value="8"><cfset result = result & DateFormat(arguments.timestamp, "m")></cfcase>
				<cfcase value="9"><cfset result = result & DateFormat(arguments.timestamp, "mmm")></cfcase>
				<cfcase value="10"><cfset result = result & DateFormat(arguments.timestamp, "mmmm")></cfcase>
				<cfcase value="11"><cfset result = result & DateFormat(arguments.timestamp, "yyyy")></cfcase>
				<cfcase value="12"><cfset result = result & DateFormat(arguments.timestamp, "yy")></cfcase>
				<cfcase value="13"><cfset result = result & LCase(TimeFormat(arguments.timestamp, "tt"))></cfcase>
				<cfcase value="14"><cfset result = result & UCase(TimeFormat(arguments.timestamp, "tt"))></cfcase>
				<cfcase value="15"><cfset result = result & TimeFormat(arguments.timestamp, "h")></cfcase>
				<cfcase value="16"><cfset result = result & TimeFormat(arguments.timestamp, "H")></cfcase>
				<cfcase value="17"><cfset result = result & TimeFormat(arguments.timestamp, "hh")></cfcase>
				<cfcase value="18"><cfset result = result & TimeFormat(arguments.timestamp, "HH")></cfcase>
				<cfcase value="19"><cfset result = result & TimeFormat(arguments.timestamp, "mm")></cfcase>
				<cfcase value="20"><cfset result = result & TimeFormat(arguments.timestamp, "ss")></cfcase>
				<cfcase value="21"><cfset result = result & NumberFormat(TimeFormat(arguments.timestamp, "l"), "000") & "000"></cfcase>
				<cfdefaultcase><cfset result = result & letter></cfdefaultcase>
			</cfswitch>
		</cfif>

		<cfset i = i + 1>
	</cfloop>

	<cfreturn result>
</cffunction>
