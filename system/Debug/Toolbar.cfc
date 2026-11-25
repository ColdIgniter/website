<!---
 * Displays a toolbar with bits of stats to aid a developer in debugging.
 *
 * Inspiration: http://prophiler.fabfuel.de
 *
 * Difference: the times are seconds (see microtime()). The start time,
 * the total time, the memory, the segment values and the start and the
 * duration of a timeline row are written to the data as strings with a
 * plain decimal form (a Double could be written in the form 1.0E-4).
 *
 * Difference: the file of a request (WRITEPATH/debugbar/debugbar_<time>.ser)
 * is not JSON. There are no JSON functions on the server: json_encode()
 * and json_decode() are written in CFML, and took longer for one file
 * than the rest of the request. The file is written and read with the
 * object streams of Java (see writeData() and readData()), which took
 * about 0.4 ms each way for a file of 28 KB on the server. The file is
 * binary, and it is only read by the toolbar and by the History
 * collector. The data must be made of maps, structs, lists, strings,
 * numbers, Booleans and dates: a component cannot be written. Reading
 * such a file makes the objects that it names, so nothing else may
 * write to WRITEPATH/debugbar. The JSON format of ?debugbar_time is
 * still made with json_encode().
 *
 * Not ported yet: Kint (a value that is not a string is shown with
 * print_r()), the session data (there is no session), the XML format,
 * the peak memory (the memory is what the Java
 * runtime has in use), the downloads (there is no DownloadResponse) and
 * the check of the headers that are already sent (see hasNativeHeaderConflict()).
--->
<cfcomponent output="no" hint="Displays a toolbar with bits of stats to aid a developer in debugging">

	<!---
	 * Toolbar configuration settings.
	--->
	<cfset this.config = "">

	<!---
	 * Collectors to be used and displayed.
	 *
	 * A list of collector objects.
	--->
	<cfset this.collectors = ArrayNew(1)>

	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfset var collector = "">
		<cfset var i = 0>

		<cfset this.config = arguments.config>

		<cfloop from="1" to="#ArrayLen(arguments.config.collectors)#" index="i">
			<cfset collector = arguments.config.collectors[i]>

			<cfif NOT class_exists(collector)>
				<cfset log_message(
					"critical",
					"Toolbar collector does not exist (" & collector & ")."
					& " Please check collectors in the app/Config/Toolbar.cfc file."
				)>
			<cfelse>
				<cfset ArrayAppend(this.collectors, new_(collector))>
			</cfif>
		</cfloop>

		<cfreturn this>
	</cffunction>

	<!---
	 * Returns all the data required by Debug Bar
	 *
	 * @param startTime App start time
	 * @param totalTime Seconds the app has run
	 * @param request_  The request
	 * @param response  The response
	 *
	 * @return The data, a map (see writeData()); JSON text in the original
	--->
	<cffunction name="run" access="public" returntype="any" output="no">
		<cfargument name="startTime" type="numeric" required="yes">
		<cfargument name="totalTime" type="numeric" required="yes">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">
		<cfset var data = array_()>
		<cfset var totalMs = arguments.totalTime * 1000>
		<cfset var segmentDuration = 0>
		<cfset var runtime = CreateObject("java", "java.lang.Runtime").getRuntime()>
		<cfset var collected = "">
		<cfset var varData = "">
		<cfset var vars = array_()>
		<cfset var headings = "">
		<cfset var items = "">
		<cfset var rows = "">
		<cfset var heading = "">
		<cfset var key = "">
		<cfset var value = "">
		<cfset var it = "">
		<cfset var hit = "">
		<cfset var map = "">
		<cfset var responseData = "">
		<cfset var timeline = "">
		<cfset var row = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<!--- Data items used within the view. --->
		<cfset data["url"] = current_url()>
		<cfset data["method"] = arguments.request_.getMethod()>
		<cfset data["isAJAX"] = JavaCast("boolean", arguments.request_.isAJAX())>
		<cfset data["startTime"] = number_format(arguments.startTime, 6, ".", "")>
		<cfset data["totalTime"] = number_format(totalMs, 2, ".", "")>

		<!--- Difference: the memory in use, not the peak. --->
		<cfset data["totalMemory"] = number_format((runtime.totalMemory() - runtime.freeMemory()) / 1024 / 1024, 3, ".", "")>

		<cfset segmentDuration = roundTo(totalMs / 7)>
		<!--- Difference: a segment is never shorter than 5 ms, so there is no division by zero. --->
		<cfif segmentDuration LT 5>
			<cfset segmentDuration = 5>
		</cfif>
		<cfset data["segmentDuration"] = number_format(segmentDuration, 0, ".", "")>
		<cfset data["segmentCount"] = number_format(Ceiling(totalMs / segmentDuration), 0, ".", "")>
		<cfset data["CI_VERSION"] = static_("ColdIgniter\ColdIgniter").CI_VERSION>
		<cfset data["collectors"] = ArrayNew(1)>

		<cfloop from="1" to="#ArrayLen(this.collectors)#" index="i">
			<cfset collected = this.collectors[i].getAsArray()>

			<!---
			 Difference: the start and the duration of the timeline rows
			 are written in a plain decimal form.
			--->
			<cfset timeline = collected["timelineData"]>
			<cfif IsArray(timeline)>
				<cfloop from="1" to="#ArrayLen(timeline)#" index="j">
					<cfset row = timeline[j]>
					<cfset row["start"] = number_format(row["start"], 6, ".", "")>
					<cfset row["duration"] = number_format(row["duration"], 6, ".", "")>
				</cfloop>
			</cfif>

			<cfset ArrayAppend(data["collectors"], collected)>
		</cfloop>

		<cfset data["vars"] = vars>
		<cfset varData = array_()>
		<cfset vars["varData"] = varData>

		<cfset collected = collectVarData()>
		<cfset headings = collected.keySet().iterator()>
		<cfloop condition="headings.hasNext()">
			<cfset heading = headings.next()>
			<cfset items = collected[heading]>
			<cfset rows = array_()>

			<cfif IsStruct(items)>
				<cfset it = items.keySet().iterator()>
				<cfloop condition="it.hasNext()">
					<cfset key = it.next()>
					<cfset value = items[key]>

					<!--- Not ported yet: Kint, so a value that is not a string is shown with print_r(). --->
					<cfif IsSimpleValue(value)>
						<cfset rows[esc(key)] = esc(value)>
					<cfelse>
						<cfset rows[esc(key)] = "<pre>" & esc(print_r(value, true)) & "</pre>">
					</cfif>
				</cfloop>
			</cfif>

			<cfset varData[esc(heading)] = rows>
		</cfloop>

		<!--- Not ported yet: the session data (vars.session). --->

		<cfset map = dataSection(arguments.request_.getGet())>
		<cfif map.size() GT 0>
			<cfset vars["get"] = map>
		</cfif>

		<cfset map = dataSection(arguments.request_.getPost())>
		<cfif map.size() GT 0>
			<cfset vars["post"] = map>
		</cfif>

		<cfset map = headerSection(arguments.request_.headers())>
		<cfif map.size() GT 0>
			<cfset vars["headers"] = map>
		</cfif>

		<cfset map = dataSection(arguments.request_.getCookie())>
		<cfif map.size() GT 0>
			<cfset vars["cookies"] = map>
		</cfif>

		<cfif arguments.request_.isSecure()>
			<cfset vars["request"] = "HTTPS/" & arguments.request_.getProtocolVersion()>
		<cfelse>
			<cfset vars["request"] = "HTTP/" & arguments.request_.getProtocolVersion()>
		</cfif>

		<cfset responseData = array_(
			"statusCode", Val(arguments.response.getStatusCode()),
			"reason", esc(arguments.response.getReasonPhrase()),
			"contentType", esc(arguments.response.getHeaderLine("content-type")),
			"headers", headerSection(arguments.response.headers())
		)>
		<cfset vars["response"] = responseData>

		<cfset data["config"] = static_("ColdIgniter\Debug\Toolbar\Collectors\Config").display()>

		<cfset arguments.response.getCSP().addImageSrc("data:")>

		<cfreturn data>
	</cffunction>

	<!---
	 * Not in the original, where the data is JSON (see the top of this
	 * file). Writes the file of a request: two objects, one after the
	 * other. The first is small and has what the History collector shows
	 * of a request (the status, the method, the URL, isAJAX and the
	 * content type, each as text), so that the collector does not have to
	 * read the whole data of every request. The second is the data.
	 *
	 * @param filename The path of the file
	 * @param data     The data of run()
	--->
	<cffunction name="writeData" access="private" returntype="void" output="no">
		<cfargument name="filename" type="string" required="yes">
		<cfargument name="data" type="any" required="yes">
		<cfset var summary = StructNew()>
		<cfset var raw = "">
		<cfset var out = "">

		<cfset summary["status"] = dataText(arguments.data["vars"]["response"]["statusCode"])>
		<cfset summary["method"] = dataText(arguments.data["method"])>
		<cfset summary["url"] = dataText(arguments.data["url"])>
		<cfset summary["isAJAX"] = dataText(arguments.data["isAJAX"])>
		<cfset summary["contentType"] = dataText(arguments.data["vars"]["response"]["contentType"])>

		<cfset raw = CreateObject("java", "java.io.FileOutputStream").init(arguments.filename)>

		<!--- There is no finally: the file is closed in both ways out. --->
		<cftry>
			<cfset out = CreateObject("java", "java.io.ObjectOutputStream").init(
				CreateObject("java", "java.io.BufferedOutputStream").init(raw)
			)>
			<cfset out.writeObject(summary)>
			<cfset out.writeObject(arguments.data)>
			<cfset out.close()>

			<cfcatch type="any">
				<!---
				 A file with a part of the data is of no use. When it cannot
				 be deleted (another request may have it open), the first
				 error is still the one that is thrown.
				--->
				<cfset raw.close()>
				<cftry>
					<cffile action="delete" file="#arguments.filename#">
					<cfcatch type="any">
					</cfcatch>
				</cftry>

				<cfrethrow>
			</cfcatch>
		</cftry>
	</cffunction>

	<!---
	 * Not in the original. Reads the data back from the file of a request:
	 * maps that keep the order of their keys, and lists, as json_decode()
	 * gave them. A value has the type that it was written with.
	 *
	 * @param filename The path of the file that writeData() made
	--->
	<cffunction name="readData" access="private" returntype="any" output="no">
		<cfargument name="filename" type="string" required="yes">
		<cfset var raw = "">
		<cfset var stream = "">
		<cfset var data = "">

		<!---
		 There is no finally: the file is closed in both ways out. The
		 file is opened here too, as the History collector of another
		 request may have deleted it by now.
		--->
		<cftry>
			<cfset raw = CreateObject("java", "java.io.FileInputStream").init(arguments.filename)>
			<cfset stream = CreateObject("java", "java.io.ObjectInputStream").init(
				CreateObject("java", "java.io.BufferedInputStream").init(raw)
			)>

			<!--- The first object is for the History collector. --->
			<cfset stream.readObject()>
			<cfset data = stream.readObject()>
			<cfset raw.close()>

			<cfcatch type="any">
				<cfif NOT IsSimpleValue(raw)>
					<cfset raw.close()>
				</cfif>

				<cfthrow type="ColdIgniter.RuntimeException" message="The debug data of the request cannot be read.">
			</cfcatch>
		</cftry>

		<cfreturn data>
	</cffunction>

	<!---
	 * Not in the original. The text of a value, as json_encode() writes
	 * it: true or false for a Boolean, and a number without a group
	 * separator.
	--->
	<cffunction name="dataText" access="private" returntype="string" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfset var cls = arguments.value.getClass().getName()>

		<cfif cls EQ "java.lang.String">
			<cfreturn arguments.value>
		</cfif>

		<cfif cls EQ "java.lang.Boolean">
			<cfif arguments.value.booleanValue()>
				<cfreturn "true">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfif cls EQ "java.lang.Double" OR cls EQ "java.lang.Integer" OR cls EQ "java.lang.Long">
			<cfreturn Replace(arguments.value & "", ",", "", "all")>
		</cfif>

		<cfreturn arguments.value & "">
	</cffunction>

	<!---
	 * Not in the original, where each of the sections of the variables is
	 * a loop in run(). Escapes the names and the values of a map; a value
	 * that is not a string is shown with print_r().
	 *
	 * @return A map
	--->
	<cffunction name="dataSection" access="private" returntype="any" output="no">
		<cfargument name="source" type="any" required="yes">
		<cfset var result = array_()>
		<cfset var it = "">
		<cfset var key = "">
		<cfset var value = "">

		<cfif NOT IsStruct(arguments.source)>
			<cfreturn result>
		</cfif>

		<cfset it = arguments.source.keySet().iterator()>
		<cfloop condition="it.hasNext()">
			<cfset key = it.next()>
			<cfset value = arguments.source.get(key)>

			<cfif IsSimpleValue(value)>
				<cfset result[esc(key)] = esc(value)>
			<cfelse>
				<cfset result[esc(key)] = "<pre>" & esc(print_r(value, true)) & "</pre>">
			</cfif>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<!---
	 * Not in the original, where each of the two header sections of the
	 * variables is a loop in run(). Escapes the names and the value lines
	 * of the headers: a header is a Header, or an array of Headers for
	 * several headers of the same name, shown as " (1) value (2) value".
	 *
	 * @return A map
	--->
	<cffunction name="headerSection" access="private" returntype="any" output="no">
		<cfargument name="source" type="any" required="yes">
		<cfset var result = array_()>
		<cfset var it = "">
		<cfset var key = "">
		<cfset var value = "">
		<cfset var line = "">
		<cfset var i = 0>

		<cfset it = arguments.source.keySet().iterator()>
		<cfloop condition="it.hasNext()">
			<cfset key = it.next()>
			<cfset value = arguments.source.get(key)>

			<cfif IsArray(value)>
				<cfset line = "">

				<cfloop from="1" to="#ArrayLen(value)#" index="i">
					<cfset line = line & " (" & i & ") " & esc(value[i].getValueLine())>
				</cfloop>

				<cfset result[esc(key)] = line>
			<cfelse>
				<cfset result[esc(key)] = esc(value.getValueLine())>
			</cfif>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<!---
	 * Called within the view to display the timeline itself.
	 *
	 * Difference: there are no references, so the styles map is changed in
	 * place and the number of styles is kept in a map.
	 *
	 * @param collectors      A list of maps with the keys hasTimelineData and timelineData
	 * @param startTime       App start time
	 * @param segmentCount    The number of segments
	 * @param segmentDuration The duration of a segment in ms
	 * @param styles          A map of the styles, changed here
	--->
	<cffunction name="renderTimeline" access="public" returntype="string" output="no">
		<cfargument name="collectors" type="any" required="yes">
		<cfargument name="startTime" type="any" required="yes">
		<cfargument name="segmentCount" type="any" required="yes">
		<cfargument name="segmentDuration" type="any" required="yes">
		<cfargument name="styles" type="any" required="yes">
		<cfset var rows = collectTimelineData(arguments.collectors)>
		<cfset var styleCount = array_("count", 0)>

		<!--- Use recursive render function --->
		<cfreturn renderTimelineRecursive(rows, arguments.startTime, arguments.segmentCount, arguments.segmentDuration, arguments.styles, styleCount, 0, false)>
	</cffunction>

	<!---
	 * Recursively renders timeline elements and their children.
	 *
	 * @param rows       A list of maps
	 * @param styles     A map of the styles, changed here
	 * @param styleCount A map with the key count, changed here
	--->
	<cffunction name="renderTimelineRecursive" access="private" returntype="string" output="no">
		<cfargument name="rows" type="any" required="yes">
		<cfargument name="startTime" type="any" required="yes">
		<cfargument name="segmentCount" type="any" required="yes">
		<cfargument name="segmentDuration" type="any" required="yes">
		<cfargument name="styles" type="any" required="yes">
		<cfargument name="styleCount" type="any" required="yes">
		<cfargument name="level" type="numeric" required="no" default="0">
		<cfargument name="isChild" type="boolean" required="no" default="false">
		<cfset var displayTime = Val(arguments.segmentCount) * Val(arguments.segmentDuration)>
		<cfset var output = "">
		<cfset var row = "">
		<cfset var hasChildren = false>
		<cfset var isQuery = false>
		<cfset var open = false>
		<cfset var offset = 0>
		<cfset var length = 0>
		<cfset var count = 0>
		<cfset var i = 0>

		<!--- Difference: no division by zero. --->
		<cfif displayTime EQ 0>
			<cfset displayTime = 1>
		</cfif>

		<cfloop from="1" to="#ArrayLen(arguments.rows)#" index="i">
			<cfset row = arguments.rows[i]>
			<cfset hasChildren = false>
			<cfset isQuery = false>
			<cfif array_key_exists("children", row)>
				<cfset hasChildren = ArrayLen(row["children"]) GT 0>
			</cfif>
			<cfif array_key_exists("query", row)>
				<cfset isQuery = Compare(row["query"], "") NEQ 0>
			</cfif>

			<!--- Open controller timeline by default --->
			<cfset open = Compare(row["name"], "Controller") EQ 0>
			<cfset count = arguments.styleCount["count"]>

			<cfif hasChildren OR isQuery>
				<cfset output = output & "<tr class=""timeline-parent" & iif(open, de(" timeline-parent-open"), de("")) & """ id=""timeline-" & count & "_parent"" data-toggle=""childrows"" data-child=""timeline-" & count & """>">
			<cfelse>
				<cfset output = output & "<tr>">
			</cfif>

			<cfset output = output & "<td class=""" & iif(arguments.isChild, de("debug-bar-width30"), de("")) & " debug-bar-level-" & arguments.level & """ >" & iif(hasChildren OR isQuery, de("<nav></nav>"), de("")) & row["name"] & "</td>">
			<cfset output = output & "<td class=""" & iif(arguments.isChild, de("debug-bar-width10"), de("")) & """>" & row["component"] & "</td>">
			<cfset output = output & "<td class=""" & iif(arguments.isChild, de("debug-bar-width10 "), de("")) & "debug-bar-alignRight"">" & number_format(Val(row["duration"]) * 1000, 2) & " ms</td>">
			<cfset output = output & "<td class='debug-bar-noverflow' colspan='" & arguments.segmentCount & "'>">

			<!--- Difference: the numbers are written with 4 decimals. --->
			<cfset offset = (((Val(row["start"]) - Val(arguments.startTime)) * 1000) / displayTime) * 100>
			<cfset length = ((Val(row["duration"]) * 1000) / displayTime) * 100>

			<cfset arguments.styles["debug-bar-timeline-" & count] = "left: " & number_format(offset, 4, ".", "") & "%; width: " & number_format(length, 4, ".", "") & "%;">

			<cfset output = output & "<span class='timer debug-bar-timeline-" & count & "' title='" & number_format(length, 2) & "%'></span>">
			<cfset output = output & "</td>">
			<cfset output = output & "</tr>">

			<cfset arguments.styleCount["count"] = count + 1>

			<!--- Add children if any --->
			<cfif hasChildren OR isQuery>
				<cfset output = output & "<tr class=""child-row " & iif(open, de(""), de(" debug-bar-ndisplay")) & """ id=""timeline-" & count & "_children"" >">
				<cfset output = output & "<td colspan=""" & (Val(arguments.segmentCount) + 3) & """ class=""child-container"">">
				<cfset output = output & "<table class=""timeline"">">
				<cfset output = output & "<tbody>">

				<cfif isQuery>
					<!--- Output query string if query --->
					<cfset output = output & "<tr>">
					<cfset output = output & "<td class=""query-container debug-bar-level-" & (arguments.level + 1) & """ >" & row["query"] & "</td>">
					<cfset output = output & "</tr>">
				<cfelse>
					<!--- Recursively render children --->
					<cfset output = output & renderTimelineRecursive(row["children"], arguments.startTime, arguments.segmentCount, arguments.segmentDuration, arguments.styles, arguments.styleCount, arguments.level + 1, true)>
				</cfif>

				<cfset output = output & "</tbody>">
				<cfset output = output & "</table>">
				<cfset output = output & "</td>">
				<cfset output = output & "</tr>">
			</cfif>
		</cfloop>

		<cfreturn output>
	</cffunction>

	<!---
	 * Returns a sorted array of timeline data arrays from the collectors.
	 *
	 * Difference: there is no array_multisort(), so the rows are sorted by
	 * an insertion sort (it keeps the order of equal rows): the start
	 * first, then the longest duration first.
	 *
	 * @param collectors A list of maps with the keys hasTimelineData and timelineData
	 *
	 * @return A list of maps
	--->
	<cffunction name="collectTimelineData" access="private" returntype="any" output="no">
		<cfargument name="collectors" type="any" required="yes">
		<cfset var data = ArrayNew(1)>
		<cfset var sorted = ArrayNew(1)>
		<cfset var collector = "">
		<cfset var rows = "">
		<cfset var row = "">
		<cfset var i = 0>
		<cfset var j = 0>
		<cfset var k = 0>

		<!--- Collect it --->
		<cfloop from="1" to="#ArrayLen(arguments.collectors)#" index="i">
			<cfset collector = arguments.collectors[i]>

			<cfif collector["hasTimelineData"]>
				<cfset rows = collector["timelineData"]>
				<cfloop from="1" to="#ArrayLen(rows)#" index="j">
					<cfset ArrayAppend(data, rows[j])>
				</cfloop>
			</cfif>
		</cfloop>

		<!--- Sort it --->
		<cfloop from="1" to="#ArrayLen(data)#" index="i">
			<cfset row = data[i]>
			<cfset k = ArrayLen(sorted)>

			<cfloop condition="k GT 0">
				<!--- the row goes behind the first one that is not later, or not the same start and shorter --->
				<cfif Val(sorted[k]["start"]) GT Val(row["start"])>
					<cfset k = k - 1>
				<cfelseif Val(sorted[k]["start"]) EQ Val(row["start"]) AND Val(sorted[k]["duration"]) LT Val(row["duration"])>
					<cfset k = k - 1>
				<cfelse>
					<cfbreak>
				</cfif>
			</cfloop>

			<!--- Difference: ArrayInsertAt() cannot insert behind the last element, so that is an append. --->
			<cfif k EQ ArrayLen(sorted)>
				<cfset ArrayAppend(sorted, row)>
			<cfelse>
				<cfset ArrayInsertAt(sorted, k + 1, row)>
			</cfif>
		</cfloop>

		<!--- Add end time to each element --->
		<cfloop from="1" to="#ArrayLen(sorted)#" index="i">
			<cfset sorted[i]["end"] = Val(sorted[i]["start"]) + Val(sorted[i]["duration"])>
		</cfloop>

		<!--- Group it --->
		<cfreturn structureTimelineData(sorted)>
	</cffunction>

	<!---
	 * Arranges the already sorted timeline data into a parent => child structure.
	 *
	 * Difference: this is a loop, and the recursion is for the children only.
	 *
	 * @param elements A list of maps
	 *
	 * @return A list of maps
	--->
	<cffunction name="structureTimelineData" access="private" returntype="any" output="no">
		<cfargument name="elements" type="any" required="yes">
		<cfset var rest = ArrayNew(1)>
		<cfset var result = ArrayNew(1)>
		<cfset var children = "">
		<cfset var element = "">
		<cfset var i = 0>

		<!--- A copy, as the list is changed. --->
		<cfloop from="1" to="#ArrayLen(arguments.elements)#" index="i">
			<cfset ArrayAppend(rest, arguments.elements[i])>
		</cfloop>

		<cfloop condition="ArrayLen(rest) GT 0">
			<!--- We define ourselves as the first element of the array --->
			<cfset element = rest[1]>
			<cfset ArrayDeleteAt(rest, 1)>
			<cfset children = ArrayNew(1)>

			<!--- If we have children behind us, collect and attach them to us --->
			<cfloop condition="ArrayLen(rest) GT 0">
				<cfif Val(rest[1]["end"]) GT Val(element["end"])>
					<cfbreak>
				</cfif>
				<cfset ArrayAppend(children, rest[1])>
				<cfset ArrayDeleteAt(rest, 1)>
			</cfloop>

			<!--- Make sure our children know whether they have children, too --->
			<cfif ArrayLen(children) GT 0>
				<cfset element["children"] = structureTimelineData(children)>
			</cfif>

			<cfset ArrayAppend(result, element)>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<!---
	 * Returns an array of data from all of the modules
	 * that should be displayed in the 'Vars' tab.
	 *
	 * @return A map
	--->
	<cffunction name="collectVarData" access="private" returntype="any" output="no">
		<cfset var data = array_()>
		<cfset var collected = "">
		<cfset var it = "">
		<cfset var key = "">
		<cfset var i = 0>

		<cfif NOT this.config.collectVarData>
			<cfreturn data>
		</cfif>

		<cfloop from="1" to="#ArrayLen(this.collectors)#" index="i">
			<cfif this.collectors[i].hasVarData_()>
				<cfset collected = this.collectors[i].getVarData()>
				<cfset it = collected.keySet().iterator()>
				<cfloop condition="it.hasNext()">
					<cfset key = it.next()>
					<cfset data[key] = collected.get(key)>
				</cfloop>
			</cfif>
		</cfloop>

		<cfreturn data>
	</cffunction>

	<!---
	 * Rounds a number to the nearest incremental value.
	--->
	<cffunction name="roundTo" access="private" returntype="numeric" output="no">
		<cfargument name="number" type="numeric" required="yes">
		<cfargument name="increments" type="numeric" required="no" default="5">

		<cfreturn Ceiling(arguments.number / arguments.increments) * arguments.increments>
	</cffunction>

	<!---
	 * Prepare for debugging.
	 *
	 * Difference: a response that is a redirect, a response without a
	 * <head> or a </body>, and one that is sent as an attachment get no
	 * script; a request with another host than the one of the baseURL is not
	 * given the toolbar at all, not even the headers or a history file.
	 *
	 * @param request_ The request, or an empty string (null) for the service
	 * @param response The response, or an empty string (null) for the service
	--->
	<cffunction name="prepare" access="public" returntype="void" output="no">
		<cfargument name="request_" type="any" required="no" default="">
		<cfargument name="response" type="any" required="no" default="">
		<cfset var app = "">
		<cfset var stats = "">
		<cfset var data = "">
		<cfset var stamp = "">
		<cfset var dir = "">
		<cfset var kind = "">
		<cfset var status = 0>
		<cfset var body = "">
		<cfset var script = "">

		<!--- Not ported yet: is_cli() --->
		<cfif NOT request.CI_DEBUG>
			<cfreturn>
		</cfif>

		<cfif hasNativeHeaderConflict()>
			<cfreturn>
		</cfif>

		<cfset app = service("coldigniter")>

		<cfif is_null(arguments.request_)>
			<cfset arguments.request_ = service("request")>
		</cfif>
		<cfif is_null(arguments.response)>
			<cfset arguments.response = service("response")>
		</cfif>

		<!--- Not ported yet: no toolbar for a DownloadResponse --->
		<cfif Find("attachment", LCase(arguments.response.getHeaderLine("content-disposition"))) GT 0>
			<cfreturn>
		</cfif>

		<cfset stats = app.getPerformanceStats()>
		<cfset data = run(stats["startTime"], stats["totalTime"], arguments.request_, arguments.response)>

		<!--- Updated to microtime() so we can get history --->
		<cfset stamp = historyTime()>

		<cfset dir = request.WRITEPATH & "debugbar">
		<cfif NOT DirectoryExists(dir)>
			<cfdirectory action="create" directory="#dir#">
		</cfif>

		<cfset writeData(dir & request.DIRECTORY_SEPARATOR & "debugbar_" & stamp & ".ser", data)>

		<cfset kind = arguments.response.getHeaderLine("content-type")>
		<cfset status = Val(arguments.response.getStatusCode())>

		<!---
		 Non-HTML formats should not include the debugbar
		 then we send headers saying where to find the debug data
		 for this response
		--->
		<cfif shouldDisableToolbar(arguments.request_) OR Find("html", kind) EQ 0 OR (status GTE 300 AND status LT 400)>
			<cfset arguments.response.setHeader("Debugbar-Time", stamp)>
			<cfset arguments.response.setHeader("Debugbar-Link", site_url("?debugbar_time=" & stamp))>

			<cfreturn>
		</cfif>

		<!--- Not ported yet: the Kint script. --->
		<cfset script = Chr(10)
			& "<script " & csp_script_nonce() & " id=""debugbar_loader"" "
			& "data-time=""" & stamp & """ "
			& "src=""" & site_url() & "?debugbar""></script>"
			& "<script " & csp_script_nonce() & " id=""debugbar_dynamic_script""></script>"
			& "<style " & csp_style_nonce() & " id=""debugbar_dynamic_style""></style>"
			& Chr(10)>

		<cfset body = arguments.response.getBody()>

		<cfif Find("<head>", body) GT 0>
			<cfset arguments.response.setBody(Replace(body, "<head>", "<head>" & script, "one"))>

			<cfreturn>
		</cfif>

		<cfif Find("</body>", LCase(body)) GT 0>
			<cfset arguments.response.appendBody(script)>
		</cfif>
	</cffunction>

	<!---
	 * Inject debug toolbar into the response.
	 *
	 * Difference: the query string is read from the server values and parsed
	 * (a leading ? or & is dropped), as the index page of the URL ends with
	 * a ?, and a value that is not there cannot be told from an empty one
	 * with getGet(). The output is left in request.ColdIgniter.output, and
	 * exit_() ends the request.
	--->
	<cffunction name="respond" access="public" returntype="void" output="no">
		<cfset var query = parseQuery()>
		<cfset var output = "">
		<cfset var kind = "">
		<cfset var filename = "">
		<cfset var stamp = "">
		<cfset var data = "">

		<cfif request.ENVIRONMENT EQ "testing">
			<cfreturn>
		</cfif>

		<!---
		 If the request contains ?debugbar then we're
		 simply returning the loading script
		--->
		<cfif StructKeyExists(query, "debugbar")>
			<cfset output = file_get_contents(this.config.viewsPath & "toolbarloader.js")>
			<cfset output = Replace(output, "{url}", rtrim_(site_url(), "/"), "all")>

			<cfset request.ColdIgniter.output = output>
			<cfcontent type="application/javascript">

			<cfset exit_()>
		</cfif>

		<!---
		 Otherwise, if it includes ?debugbar_time, then
		 we should return the entire debugbar.
		--->
		<cfif StructKeyExists(query, "debugbar_time")>
			<cfset helper("security")>

			<!--- Negotiate the content-type to format the output --->
			<cfset kind = negotiate()>

			<cfset stamp = query["debugbar_time"]>
			<cfif NOT IsSimpleValue(stamp)>
				<cfset stamp = "">
			</cfif>

			<!---
			 Difference: the file is read with an object stream (see the top
			 of this file), so only a time in the form of historyTime() is
			 looked up.
			--->
			<cfif REFind("^[0-9]+\.[0-9]+$", stamp) EQ 0>
				<cfset stamp = "">
			</cfif>

			<cfset filename = sanitize_filename("debugbar_" & stamp)>
			<cfset filename = request.WRITEPATH & "debugbar" & request.DIRECTORY_SEPARATOR & filename & ".ser">

			<cfif is_file(filename)>
				<!--- Show the toolbar if it exists --->
				<cfset data = readData(filename)>
				<cfset request.ColdIgniter.output = format(data, kind, stamp)>
				<cfif Compare(kind, "json") EQ 0>
					<cfcontent type="application/json">
				<cfelse>
					<!--- Difference: the charset is named, the original gets it from default_charset. --->
					<cfcontent type="text/html; charset=UTF-8">
				</cfif>

				<cfset exit_()>
			</cfif>

			<!--- Filename not found --->
			<cfheader statuscode="404" statustext="Not Found">
			<cfset request.ColdIgniter.output = "">

			<!--- Exit here is needed to avoid loading the index page --->
			<cfset exit_()>
		</cfif>
	</cffunction>

	<!---
	 * Format output
	 *
	 * Difference: the stamp is an argument, as the get values cannot be used
	 * (see respond()), and the XML format is not ported yet.
	 *
	 * @param data   The data of the file of a request (see readData()), JSON text in the original
	 * @param format "html" or "json"
	 * @param stamp  The value of debugbar_time
	--->
	<cffunction name="format" access="private" returntype="string" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfargument name="format" type="string" required="no" default="html">
		<cfargument name="stamp" type="string" required="no" default="">
		<cfset var decoded = arguments.data>
		<cfset var history = "">
		<cfset var found = "">
		<cfset var output = "">
		<cfset var parser = "">

		<cfset found = REFind("[0-9]+\.[0-9]{6}", arguments.stamp, 1, true)>
		<cfif found.pos[1] GT 0>
			<cfset history = new_("ColdIgniter\Debug\Toolbar\Collectors\History")>
			<cfset history.setFiles(
				Mid(arguments.stamp, found.pos[1], found.len[1]),
				this.config.maxHistory
			)>

			<cfset ArrayAppend(decoded["collectors"], history.getAsArray())>
		</cfif>

		<cfif Compare(arguments.format, "html") EQ 0>
			<cfset decoded["styles"] = array_()>
			<cfset decoded["toolbar"] = this>
			<cfset parser = service("parser", this.config.viewsPath, "", false)>
			<cfset decoded["parser"] = parser>

			<!--- Difference: one throwaway object includes the view, and it reads the data by name. --->
			<cfset output = new_("ColdIgniter\View\Closure").call(this.config.viewsPath & "toolbar.tpl.cfm", decoded)>
		<cfelseif Compare(arguments.format, "json") EQ 0>
			<!---
			 Difference: a number that run() wrote in a plain decimal form is a string in this
			 output.
			 Not ported yet: JSONFormatter and XMLFormatter
			--->
			<cfset output = json_encode(decoded)>
		</cfif>

		<cfreturn output>
	</cffunction>

	<!---
	 * Checks if the native headers indicate a non-HTML response
	 * or if headers are already sent.
	 *
	 * Difference: the headers are not sent before the end of the request here,
	 * so there is no conflict, and the answer is always false. The response
	 * that is not HTML is found in prepare().
	--->
	<cffunction name="hasNativeHeaderConflict" access="private" returntype="boolean" output="no">
		<cfreturn false>
	</cffunction>

	<!---
	 * Determine if the toolbar should be disabled based on the request headers.
	 *
	 * This method allows checking both the presence of headers and their expected values.
	 * Useful for AJAX, HTMX, Unpoly, Turbo, etc., where partial HTML responses are expected.
	 *
	 * @return True if any header condition matches; false otherwise.
	--->
	<cffunction name="shouldDisableToolbar" access="private" returntype="boolean" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfset var headers = this.config.disableOnHeaders>
		<cfset var it = headers.keySet().iterator()>
		<cfset var headerName = "">
		<cfset var expectedValue = "">

		<cfloop condition="it.hasNext()">
			<cfset headerName = it.next()>
			<cfset expectedValue = headers.get(headerName)>

			<!--- header not present, skip --->
			<cfif arguments.request_.hasHeader(headerName)>
				<!--- If expectedValue is empty (null), only presence is enough --->
				<cfif is_null(expectedValue)>
					<cfreturn true>
				</cfif>

				<cfif Compare(LCase(arguments.request_.getHeaderLine(headerName)), LCase(expectedValue)) EQ 0>
					<cfreturn true>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn false>
	</cffunction>

	<!---
	 * Reset all collectors for worker mode.
	 * Calls reset() on collectors that support it.
	--->
	<cffunction name="reset" access="public" returntype="void" output="no">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(this.collectors)#" index="i">
			<cfif method_exists(this.collectors[i], "reset")>
				<cfset this.collectors[i].reset()>
			</cfif>
		</cfloop>
	</cffunction>

	<!---
	 * Not in the original. The time of the history file name: seconds, a
	 * dot and six digits, taken from the clock in whole milliseconds (the
	 * last three digits are zeros, and two requests in the same
	 * millisecond share a file).
	--->
	<cffunction name="historyTime" access="private" returntype="string" output="no">
		<cfset var ms = CreateObject("java", "java.lang.System").currentTimeMillis()>
		<cfset var seconds = Int(ms / 1000)>

		<cfreturn number_format(seconds, 0, ".", "") & "." & Right("00" & number_format(ms - seconds * 1000, 0, ".", ""), 3) & "000">
	</cffunction>

	<!---
	 * Not in the original. Reads the query string from the server values.
	 *
	 * @return A map of the names to the values
	--->
	<cffunction name="parseQuery" access="private" returntype="any" output="no">
		<cfset var query = service("superglobals").server("QUERY_STRING")>

		<cfreturn parse_str(REReplace(query, "^[?&]+", ""))>
	</cffunction>

	<!---
	 * Not in the original, where $request->negotiate() chooses. The first
	 * type of the Accept header that is supported wins (the q values are
	 * ignored), and the default is html.
	 *
	 * Not ported yet: the negotiator, and the xml format.
	 *
	 * @return "html" or "json"
	--->
	<cffunction name="negotiate" access="private" returntype="string" output="no">
		<cfset var accept = LCase(service("superglobals").server("HTTP_ACCEPT"))>
		<cfset var parts = explode(",", accept)>
		<cfset var type = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(parts)#" index="i">
			<cfset type = Trim(ListFirst(parts[i], ";"))>

			<cfif Compare(type, "text/html") EQ 0>
				<cfreturn "html">
			</cfif>
			<cfif Compare(type, "application/json") EQ 0>
				<cfreturn "json">
			</cfif>
		</cfloop>

		<cfreturn "html">
	</cffunction>

</cfcomponent>
