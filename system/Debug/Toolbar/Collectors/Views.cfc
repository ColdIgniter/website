<!---
 * Views collector
--->
<cfcomponent output="no" extends="BaseCollector" hint="Views collector">

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
	 * Whether this collector needs to display
	 * a label or not.
	--->
	<cfset this.hasLabel = true>

	<!---
	 * Whether this collector has data that
	 * should be shown in the Vars tab.
	--->
	<cfset this.hasVarData = true>

	<!---
	 * The 'title' of this Collector.
	 * Used to name things in the toolbar HTML.
	--->
	<cfset this.title = "Views">

	<!---
	 * Instance of the shared Renderer service
	--->
	<cfset this.viewer = "">

	<!---
	 * Views counter
	 *
	 * @deprecated 4.7.5 Unused.
	--->
	<cfset this.views = ArrayNew(1)>

	<cffunction name="initViewer" access="private" returntype="void" output="no">
		<cfif is_null(this.viewer)>
			<cfset this.viewer = service("renderer")>
		</cfif>
	</cffunction>

	<!---
	 * Child classes should implement this to return the timeline data
	 * formatted for correct usage.
	 *
	 * @return A list of maps with the keys name, component, start and duration
	--->
	<cffunction name="formatTimelineData" access="private" returntype="any" output="no">
		<cfset var data = ArrayNew(1)>
		<cfset var rows = "">
		<cfset var info = "">
		<cfset var i = 0>

		<cfset initViewer()>

		<cfset rows = this.viewer.getPerformanceData()>

		<cfloop from="1" to="#ArrayLen(rows)#" index="i">
			<cfset info = rows[i]>
			<cfset ArrayAppend(data, array_(
				"name", "View: " & info["view"],
				"component", "Views",
				"start", info["start"],
				"duration", info["end"] - info["start"]
			))>
		</cfloop>

		<cfreturn data>
	</cffunction>

	<!---
	 * Gets a collection of data that should be shown in the 'Vars' tab.
	 * The format is a map of sections, each with their own map
	 * of key/value pairs.
	 *
	 * @return A map of maps
	--->
	<cffunction name="getVarData" access="public" returntype="any" output="no">
		<cfset initViewer()>

		<cfreturn array_("View Data", this.viewer.getData())>
	</cffunction>

	<!---
	 * Returns a count of all views.
	--->
	<cffunction name="getBadgeValue" access="public" returntype="any" output="no">
		<cfset initViewer()>

		<cfreturn ArrayLen(this.viewer.getPerformanceData())>
	</cffunction>

	<!---
	 * Display the icon.
	 *
	 * Icon from https://icons8.com - 1em package
	--->
	<cffunction name="icon" access="public" returntype="string" output="no">
		<cfreturn "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAADeSURBVEhL7ZSxDcIwEEWNYA0YgGmgyAaJLTcUaaBzQQEVjMEabBQxAdw53zTHiThEovGTfnE/9rsoRUxhKLOmaa6Uh7X2+UvguLCzVxN1XW9x4EYHzik033Hp3X0LO+DaQG8MDQcuq6qao4qkHuMgQggLvkPLjqh00ZgFDBacMJYFkuwFlH1mshdkZ5JPJERA9JpI6xNCBESvibQ+IURA9JpI6xNCBESvibQ+IURA9DTsuHTOrVFFxixgB/eUFlU8uKJ0eDBFOu/9EvoeKnlJS2/08Tc8NOwQ8sIfMeYFjqKDjdU2sp4AAAAASUVORK5CYII=">
	</cffunction>

</cfcomponent>
