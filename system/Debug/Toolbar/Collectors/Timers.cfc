<!---
 * Timers collector
--->
<cfcomponent output="no" extends="BaseCollector" hint="Timers collector">

	<!---
	 * Whether this collector has data that can
	 * be displayed in the Timeline.
	--->
	<cfset this.hasTimeline = true>

	<!---
	 * Whether this collector needs to display
	 * content in a tab or not.
	--->
	<cfset this.hasTabContent = false>

	<!---
	 * The 'title' of this Collector.
	 * Used to name things in the toolbar HTML.
	--->
	<cfset this.title = "Timers">

	<!---
	 * Child classes should implement this to return the timeline data
	 * formatted for correct usage.
	 *
	 * @return A list of maps with the keys name, component, start and duration
	--->
	<cffunction name="formatTimelineData" access="private" returntype="any" output="no">
		<cfset var data = ArrayNew(1)>
		<cfset var benchmark = service("timer", true)>
		<cfset var rows = benchmark.getTimers(6)>
		<cfset var name = "">
		<cfset var info = "">
		<cfset var it = rows.keySet().iterator()>

		<cfloop condition="it.hasNext()">
			<cfset name = it.next()>
			<cfset info = rows[name]>

			<!--- Difference: there is no cfcontinue, so the total_execution timer is skipped with a cfif. --->
			<cfif Compare(name, "total_execution") NEQ 0>
				<cfset ArrayAppend(data, array_(
					"name", ucwords(Replace(name, "_", " ", "all")),
					"component", "Timer",
					"start", info["start"],
					"duration", info["end"] - info["start"]
				))>
			</cfif>
		</cfloop>

		<cfreturn data>
	</cffunction>

</cfcomponent>
