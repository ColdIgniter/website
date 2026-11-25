<!---
 * Files collector
 *
 * Difference: there is no get_included_files(). The files are the ones
 * recorded in request.ColdIgniter.included, which are the files loaded by
 * require_once() and the file of each component the autoloader created.
 * Not ported yet: the views and the config files (they are included, not
 * required, so they are not recorded).
--->
<cfcomponent output="no" extends="BaseCollector" hint="Files collector">

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
	<cfset this.title = "Files">

	<!---
	 * Returns any information that should be shown next to the title.
	--->
	<cffunction name="getTitleDetails" access="public" returntype="string" output="no">
		<cfreturn "( " & StructCount(request.ColdIgniter.included) & " )">
	</cffunction>

	<!---
	 * Returns the data of this collector to be formatted in the toolbar
	 *
	 * @return A map with the keys coreFiles and userFiles, each a list of
	 *         maps with the keys path and name
	--->
	<cffunction name="display" access="public" returntype="any" output="no">
		<cfset var rawFiles = StructKeyArray(request.ColdIgniter.included)>
		<cfset var coreKeys = ArrayNew(1)>
		<cfset var userKeys = ArrayNew(1)>
		<cfset var coreFiles = ArrayNew(1)>
		<cfset var userFiles = ArrayNew(1)>
		<cfset var names = CreateObject("java", "java.util.HashMap").init()>
		<cfset var file = "">
		<cfset var path = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(rawFiles)#" index="i">
			<cfset file = rawFiles[i]>
			<cfset path = clean_path(file)>
			<cfset names.put(path, basename(file))>

			<cfif Find("SYSTEMPATH", path) GT 0>
				<cfset ArrayAppend(coreKeys, path)>
			<cfelse>
				<cfset ArrayAppend(userKeys, path)>
			</cfif>
		</cfloop>

		<!--- Difference: the original sorts the maps, which orders them by the first key, the path. --->
		<cfset ArraySort(userKeys, "text", "asc")>
		<cfset ArraySort(coreKeys, "text", "asc")>

		<cfloop from="1" to="#ArrayLen(coreKeys)#" index="i">
			<cfset ArrayAppend(coreFiles, array_("path", coreKeys[i], "name", names.get(coreKeys[i])))>
		</cfloop>
		<cfloop from="1" to="#ArrayLen(userKeys)#" index="i">
			<cfset ArrayAppend(userFiles, array_("path", userKeys[i], "name", names.get(userKeys[i])))>
		</cfloop>

		<cfreturn array_("coreFiles", coreFiles, "userFiles", userFiles)>
	</cffunction>

	<!---
	 * Displays the number of included files as a badge in the tab button.
	--->
	<cffunction name="getBadgeValue" access="public" returntype="any" output="no">
		<cfreturn StructCount(request.ColdIgniter.included)>
	</cffunction>

	<!---
	 * Display the icon.
	 *
	 * Icon from https://icons8.com - 1em package
	--->
	<cffunction name="icon" access="public" returntype="string" output="no">
		<cfreturn "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAGBSURBVEhL7ZQ9S8NQGIVTBQUncfMfCO4uLgoKbuKQOWg+OkXERRE1IAXrIHbVDrqIDuLiJgj+gro7S3dnpfq88b1FMTE3VZx64HBzzvvZWxKnj15QCcPwCD5HUfSWR+JtzgmtsUcQBEva5IIm9SwSu+95CAWbUuy67qBa32ByZEDpIaZYZSZMjjQuPcQUq8yEyYEb8FSerYeQVGbAFzJkX1PyQWLhgCz0BxTCekC1Wp0hsa6yokzhed4oje6Iz6rlJEkyIKfUEFtITVtQdAibn5rMyaYsMS+a5wTv8qeXMhcU16QZbKgl3hbs+L4/pnpdc87MElZgq10p5DxGdq8I7xrvUWUKvG3NbSK7ubngYzdJwSsF7TiOh9VOgfcEz1UayNe3JUPM1RWC5GXYgTfc75B4NBmXJnAtTfpABX0iPvEd9ezALwkplCFXcr9styiNOKc1RRZpaPM9tcqBwlWzGY1qPL9wjqRBgF5BH6j8HWh2S7MHlX8PrmbK+k/8PzjOOzx1D3i1pKTTAAAAAElFTkSuQmCC">
	</cffunction>

</cfcomponent>
