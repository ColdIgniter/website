<!---
 * Logs collector
--->
<cfcomponent output="no" extends="BaseCollector" hint="Logs collector">

	<!---
	 * Whether this collector has data that can
	 * be displayed in the Timeline.
	--->
	<cfset this.hasTimeline = false>

	<!---
	 * Whether this collector needs to display
	 * content in a tab or not.
	--->
	<cfset this.hasTabContent = true>

	<!---
	 * The 'title' of this Collector.
	 * Used to name things in the toolbar HTML.
	--->
	<cfset this.title = "Logs">

	<!---
	 * Our collected data.
	 *
	 * A list of maps with the keys level and msg.
	--->
	<cfset this.data = ArrayNew(1)>

	<!---
	 * Returns the data of this collector to be formatted in the toolbar.
	 *
	 * @return A map with the key logs
	--->
	<cffunction name="display" access="public" returntype="any" output="no">
		<cfreturn array_("logs", collectLogs())>
	</cffunction>

	<!---
	 * Does this collector actually have any data to display?
	--->
	<cffunction name="isEmpty" access="public" returntype="boolean" output="no">
		<cfset collectLogs()>

		<cfreturn ArrayLen(this.data) EQ 0>
	</cffunction>

	<!---
	 * Display the icon.
	 *
	 * Icon from https://icons8.com - 1em package
	--->
	<cffunction name="icon" access="public" returntype="string" output="no">
		<cfreturn "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAACYSURBVEhLYxgFJIHU1FSjtLS0i0D8AYj7gEKMEBkqAaAFF4D4ERCvAFrwH4gDoFIMKSkpFkB+OTEYqgUTACXfA/GqjIwMQyD9H2hRHlQKJFcBEiMGQ7VgAqCBvUgK32dmZspCpagGGNPT0/1BLqeF4bQHQJePpiIwhmrBBEADR1MRfgB0+WgqAmOoFkwANHA0FY0CUgEDAwCQ0PUpNB3kqwAAAABJRU5ErkJggg==">
	</cffunction>

	<!---
	 * Ensures the data has been collected.
	 *
	 * @return A list of maps with the keys level and msg
	--->
	<cffunction name="collectLogs" access="private" returntype="any" output="no">
		<cfset var logger = "">

		<cfif ArrayLen(this.data) GT 0>
			<cfreturn this.data>
		</cfif>

		<cfset logger = service("logger")>

		<cfif NOT StructKeyExists(logger, "logCache")>
			<cfreturn this.data>
		</cfif>

		<cfset this.data = logger.logCache>

		<cfreturn this.data>
	</cffunction>

</cfcomponent>
