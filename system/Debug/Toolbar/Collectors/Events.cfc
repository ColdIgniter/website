<!---
 * Events collector
--->
<cfcomponent output="no" extends="BaseCollector" hint="Events collector">

	<!---
	 * Whether this collector has data that can
	 * be displayed in the Timeline.
	--->
	<cfset this.hasTimeline = true>

	<!---
	 * Whether this collector needs to display
	 * content in a tab or not.
	--->
	<cfset this.hasTabContent = true>

	<!---
	 * Whether this collector has data that
	 * should be shown in the Vars tab.
	--->
	<cfset this.hasVarData = false>

	<!---
	 * The 'title' of this Collector.
	 * Used to name things in the toolbar HTML.
	--->
	<cfset this.title = "Events">

	<!---
	 * Child classes should implement this to return the timeline data
	 * formatted for correct usage.
	 *
	 * @return A list of maps with the keys name, component, start and duration
	--->
	<cffunction name="formatTimelineData" access="private" returntype="any" output="no">
		<cfset var data = ArrayNew(1)>
		<cfset var rows = static_("ColdIgniter\Events\Events").getPerformanceLogs()>
		<cfset var info = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(rows)#" index="i">
			<cfset info = rows[i]>
			<cfset ArrayAppend(data, array_(
				"name", "Event: " & info["event"],
				"component", "Events",
				"start", info["start"],
				"duration", info["end"] - info["start"]
			))>
		</cfloop>

		<cfreturn data>
	</cffunction>

	<!---
	 * Returns the data of this collector to be formatted in the toolbar
	 *
	 * @return A map with the key events, a map of event names to maps with
	 *         the keys event, duration and count
	--->
	<cffunction name="display" access="public" returntype="any" output="no">
		<cfset var events = array_()>
		<cfset var data = array_("events", events)>
		<cfset var rows = static_("ColdIgniter\Events\Events").getPerformanceLogs()>
		<cfset var row = "">
		<cfset var key = "">
		<cfset var it = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(rows)#" index="i">
			<cfset row = rows[i]>
			<cfset key = row["event"]>

			<cfif NOT array_key_exists(key, events)>
				<cfset events[key] = array_(
					"event", key,
					"duration", (row["end"] - row["start"]) * 1000,
					"count", 1
				)>
			<cfelse>
				<cfset events[key]["duration"] = events[key]["duration"] + (row["end"] - row["start"]) * 1000>
				<cfset events[key]["count"] = events[key]["count"] + 1>
			</cfif>
		</cfloop>

		<cfset it = events.keySet().iterator()>
		<cfloop condition="it.hasNext()">
			<cfset key = it.next()>
			<cfset events[key]["duration"] = number_format(events[key]["duration"], 2)>
		</cfloop>

		<cfreturn data>
	</cffunction>

	<!---
	 * Gets the "badge" value for the button.
	--->
	<cffunction name="getBadgeValue" access="public" returntype="any" output="no">
		<cfreturn ArrayLen(static_("ColdIgniter\Events\Events").getPerformanceLogs())>
	</cffunction>

	<!---
	 * Display the icon.
	 *
	 * Icon from https://icons8.com - 1em package
	--->
	<cffunction name="icon" access="public" returntype="string" output="no">
		<cfreturn "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAEASURBVEhL7ZXNDcIwDIVTsRBH1uDQDdquUA6IM1xgCA6MwJUN2hk6AQzAz0vl0ETUxC5VT3zSU5w81/mRMGZysixbFEVR0jSKNt8geQU9aRpFmp/keX6AbjZ5oB74vsaN5lSzA4tLSjpBFxsjeSuRy4d2mDdQTWU7YLbXTNN05mKyovj5KL6B7q3hoy3KwdZxBlT+Ipz+jPHrBqOIynZgcZonoukb/0ckiTHqNvDXtXEAaygRbaB9FvUTjRUHsIYS0QaSp+Dw6wT4hiTmYHOcYZsdLQ2CbXa4ftuuYR4x9vYZgdb4vsFYUdmABMYeukK9/SUme3KMFQ77+Yfzh8eYF8+orDuDWU5LAAAAAElFTkSuQmCC">
	</cffunction>

</cfcomponent>
