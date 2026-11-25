<!---
 * Events allows you to tap into the execution of the program without
 * modifying or extending core files. This file provides a central
 * location to hold all events, and a way to trigger them.
 *
 * The class is static in the original. Here it is used through
 * static_("ColdIgniter\Events\Events"), one shared object per request.
 *
 * The callable form: there are no closures on 6.1 and a detached function
 * reference loses its object, so a callable is a pair (a list of two):
 *
 *     [object-or-class-name, "method"]
 *
 * The first element is a component or the name of a class (reached with
 * static_()). The string "Class\Name::method" is accepted as well. The
 * listener is called as target.method(arguments...). A plain function name
 * is not ported yet. In config/Events.cfm a listener is registered as:
 *
 *     <cfset pair = ArrayNew(1)>
 *     <cfset ArrayAppend(pair, "App\Listeners\Audit")>
 *     <cfset ArrayAppend(pair, "onSystem")>
 *     <cfset static_("ColdIgniter\Events\Events").on("pre_system", pair)>
 *
 * A listener that returns false stops the chain. A listener that returns
 * nothing does not.
 *
 * Not ported yet: the search for Config/Events in the modules (needs the
 * locator), the time of the log in microseconds (only GetTickCount() exists,
 * so the log is in milliseconds), and cleanupForWorkerMode.
--->
<cfcomponent output="no" hint="Events">

	<!---
	 * The priorities of a listener. The lower the number, the earlier it runs.
	--->
	<cfset this.PRIORITY_LOW = 200>
	<cfset this.PRIORITY_NORMAL = 100>
	<cfset this.PRIORITY_HIGH = 10>

	<!---
	 * The list of listeners. A map: the key is the event name and the value
	 * a list of three: [1] true when sorted, [2] the priorities, [3] the
	 * callables. The map is ordered and case-sensitive.
	--->
	<cfset this.listeners_ = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Flag to let us know if we've read from the Config file(s)
	 * and have all of the defined events.
	--->
	<cfset this.initialized = false>

	<!---
	 * If true, events will not actually be fired.
	 * Useful during testing.
	--->
	<cfset this.simulate_ = false>

	<!---
	 * Stores information about the events for display in the debug toolbar.
	 * A list of maps with start, end and event. The times are in seconds (see microtime()).
	--->
	<cfset this.performanceLog = ArrayNew(1)>

	<!---
	 * A list of found files.
	--->
	<cfset this.files = ArrayNew(1)>

	<!---
	 * Ensures that we have a events file ready.
	--->
	<cffunction name="initialize_" access="public" returntype="void" output="no">
		<cfset var modules = "">
		<cfset var eventsFile = "">
		<cfset var eventFiles = ArrayNew(1)>

		<!--- Don't overwrite anything.... --->
		<cfif this.initialized>
			<cfreturn>
		</cfif>

		<cfset modules = new_("Config\Modules")>
		<cfset eventsFile = request.APPPATH & "Config/Events.cfm">

		<!--- Not ported yet: the search in the modules, when modules.shouldDiscover("events"). --->

		<cfset ArrayAppend(eventFiles, eventsFile)>
		<cfset this.files = eventFiles>

		<!--- Set early, so that an event triggered by the file does not read it again. --->
		<cfset this.initialized = true>

		<cfif is_file(eventsFile)>
			<cfinclude template="#includePath(eventsFile)#">
		</cfif>
	</cffunction>

	<!---
	 * Registers an action to happen on an event. The action can be any callable
	 * (see the top of this file).
	 *
	 * Prioritizing allows you to execute code before other listeners,
	 * so that they can modify what the others do.
	 *
	 * @param eventName
	 * @param callback
	 * @param priority  The lower the number, the earlier it runs.
	--->
	<cffunction name="on" access="public" returntype="void" output="no">
		<cfargument name="eventName" type="string" required="yes">
		<cfargument name="callback" type="any" required="yes">
		<cfargument name="priority" type="numeric" required="no" default="#this.PRIORITY_NORMAL#">
		<cfset var entry = ArrayNew(1)>

		<cfif NOT StructKeyExists(this.listeners_, arguments.eventName)>
			<!--- If there's only 1 item, it's sorted. --->
			<cfset ArrayAppend(entry, true)>
			<cfset ArrayAppend(entry, ArrayNew(1))>
			<cfset ArrayAppend(entry, ArrayNew(1))>
			<cfset this.listeners_[arguments.eventName] = entry>
			<cfset ArrayAppend(this.listeners_[arguments.eventName][2], arguments.priority)>
			<cfset ArrayAppend(this.listeners_[arguments.eventName][3], arguments.callback)>
		<cfelse>
			<!--- Not sorted --->
			<cfset this.listeners_[arguments.eventName][1] = false>
			<cfset ArrayAppend(this.listeners_[arguments.eventName][2], arguments.priority)>
			<cfset ArrayAppend(this.listeners_[arguments.eventName][3], arguments.callback)>
		</cfif>
	</cffunction>

	<!---
	 * Runs through all subscribed methods running them one at a time,
	 * until either:
	 *  a) All subscribers have finished or
	 *  b) a method returns false, at which point execution of subscribers stops.
	 *
	 * trigger(eventName, argument, argument, ...)
	 *
	 * @return false when a listener stopped the chain, otherwise true.
	--->
	<cffunction name="trigger" access="public" returntype="boolean" output="no">
		<cfargument name="eventName" type="string" required="yes">
		<cfset var listeners = ArrayNew(1)>
		<cfset var eventArguments = ArrayNew(1)>
		<cfset var result = "">
		<cfset var start = 0>
		<cfset var entry = "">
		<cfset var i = 0>

		<!--- Read in our Config/Events file so that we have them all! --->
		<cfif NOT this.initialized>
			<cfset initialize_()>
		</cfif>

		<cfloop from="2" to="#ArrayLen(arguments)#" index="i">
			<cfset ArrayAppend(eventArguments, arguments[i])>
		</cfloop>

		<cfset listeners = this.listeners(arguments.eventName)>

		<cfloop from="1" to="#ArrayLen(listeners)#" index="i">
			<cfset start = microtime(true)>
			<cfset result = true>

			<cfif NOT this.simulate_>
				<cfset result = callListener(listeners[i], eventArguments)>
			</cfif>

			<cfif request.CI_DEBUG>
				<cfset entry = array_("start", start, "end", microtime(true),"event", arguments.eventName)>
				<cfset ArrayAppend(this.performanceLog, entry)>
			</cfif>

			<!---
			 Upstream stops only for the value false itself. On this server
			 <cfreturn false> gives the string "false" (probed), so a string
			 that is exactly "false" stops the chain; the string "false" cannot
			 be told apart from false. A java.lang.Boolean false (JavaCast) stops
			 it too. 0, "0", "no" and "" do not.
			--->
			<cfif IsSimpleValue(result)>
				<cfif Compare(result, "false") EQ 0>
					<cfreturn false>
				</cfif>
				<cfif result.getClass().getName() EQ "java.lang.Boolean">
					<cfif NOT result>
						<cfreturn false>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<!---
	 * Getter for the internal listeners list, sorted by priority.
	 * Difference: equal priorities keep the order they were registered in,
	 * where array_multisort() of the original orders them by the callable
	 * value.
	 *
	 * @return A list of callables.
	--->
	<cffunction name="listeners" access="public" returntype="array" output="no">
		<cfargument name="eventName" type="string" required="yes">
		<cfset var i = 0>
		<cfset var j = 0>
		<cfset var tmp = "">

		<cfif NOT StructKeyExists(this.listeners_, arguments.eventName)>
			<cfreturn ArrayNew(1)>
		</cfif>

		<!--- The list is not sorted --->
		<cfif NOT this.listeners_[arguments.eventName][1]>
			<!---
			 Sort it! A stable insertion sort of both lists together.
			 Difference: equal priorities keep their registration order (see above).
			--->
			<cfloop from="2" to="#ArrayLen(this.listeners_[arguments.eventName][2])#" index="i">
				<cfset j = i>
				<cfloop condition="j GT 1 AND this.listeners_[arguments.eventName][2][j - 1] GT this.listeners_[arguments.eventName][2][j]">
					<cfset tmp = this.listeners_[arguments.eventName][2][j]>
					<cfset this.listeners_[arguments.eventName][2][j] = this.listeners_[arguments.eventName][2][j - 1]>
					<cfset this.listeners_[arguments.eventName][2][j - 1] = tmp>
					<cfset tmp = this.listeners_[arguments.eventName][3][j]>
					<cfset this.listeners_[arguments.eventName][3][j] = this.listeners_[arguments.eventName][3][j - 1]>
					<cfset this.listeners_[arguments.eventName][3][j - 1] = tmp>
					<cfset j = j - 1>
				</cfloop>
			</cfloop>

			<!--- Mark it as sorted already! --->
			<cfset this.listeners_[arguments.eventName][1] = true>
		</cfif>

		<cfreturn this.listeners_[arguments.eventName][3]>
	</cffunction>

	<!---
	 * Removes a single listener from an event.
	 *
	 * @return true when a listener was removed.
	--->
	<cffunction name="removeListener" access="public" returntype="boolean" output="no">
		<cfargument name="eventName" type="string" required="yes">
		<cfargument name="listener" type="any" required="yes">
		<cfset var i = 0>

		<cfif NOT StructKeyExists(this.listeners_, arguments.eventName)>
			<cfreturn false>
		</cfif>

		<cfloop from="1" to="#ArrayLen(this.listeners_[arguments.eventName][3])#" index="i">
			<cfif sameCallable(this.listeners_[arguments.eventName][3][i], arguments.listener)>
				<cfset ArrayDeleteAt(this.listeners_[arguments.eventName][2], i)>
				<cfset ArrayDeleteAt(this.listeners_[arguments.eventName][3], i)>

				<cfreturn true>
			</cfif>
		</cfloop>

		<cfreturn false>
	</cffunction>

	<!---
	 * Removes all listeners.
	 *
	 * If the event_name is specified, only listeners for that event will be
	 * removed, otherwise all listeners for all events are removed.
	--->
	<cffunction name="removeAllListeners" access="public" returntype="void" output="no">
		<cfargument name="eventName" type="string" required="no" default="">

		<cfif NOT is_null(arguments.eventName)>
			<cfset StructDelete(this.listeners_, arguments.eventName)>
		<cfelse>
			<cfset this.listeners_ = CreateObject("java", "java.util.LinkedHashMap").init()>
		</cfif>
	</cffunction>

	<!---
	 * Sets the path to the file that routes are read from.
	--->
	<cffunction name="setFiles" access="public" returntype="void" output="no">
		<cfargument name="files" type="array" required="yes">

		<cfset this.files = arguments.files>
	</cffunction>

	<!---
	 * Returns the files that were found/loaded during this request.
	--->
	<cffunction name="getFiles" access="public" returntype="array" output="no">
		<cfreturn this.files>
	</cffunction>

	<!---
	 * Turns simulation on or off. When on, events will not be triggered,
	 * simply logged. Helpful during testing when you don't actually want
	 * the tests to run.
	--->
	<cffunction name="simulate" access="public" returntype="void" output="no">
		<cfargument name="choice" type="boolean" required="no" default="true">

		<cfset this.simulate_ = arguments.choice>
	</cffunction>

	<!---
	 * Getter for the performance log records.
	--->
	<cffunction name="getPerformanceLogs" access="public" returntype="array" output="no">
		<cfreturn this.performanceLog>
	</cffunction>

	<!---
	 * Calls a listener. See the top of this file for the callable form.
	 * This stands in for $listener(...$arguments) of the original.
	 *
	 * @return What the listener returned, or an empty string.
	--->
	<cffunction name="callListener" access="private" returntype="any" output="no">
		<cfargument name="listener" type="any" required="yes">
		<cfargument name="eventArguments" type="array" required="yes">
		<cfset var target = "">
		<cfset var method = "">
		<cfset var call = "">
		<cfset var result = "">
		<cfset var i = 0>

		<cfif IsArray(arguments.listener)>
			<cfset target = arguments.listener[1]>
			<cfset method = arguments.listener[2]>
		<cfelse>
			<!--- Not ported yet: a plain function name. --->
			<cfset target = ListFirst(Replace(arguments.listener, "::", Chr(1)), Chr(1))>
			<cfset method = ListLast(Replace(arguments.listener, "::", Chr(1)), Chr(1))>
		</cfif>

		<cfif NOT IsObject(target)>
			<cfset target = static_(target)>
		</cfif>

		<cfloop from="1" to="#ArrayLen(arguments.eventArguments)#" index="i">
			<cfset call = ListAppend(call, "arguments.eventArguments[#i#]")>
		</cfloop>

		<cfset result = Evaluate("target.#method#(#call#)")>

		<cfif NOT IsDefined("result")>
			<cfreturn "">
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * Finds whether two callables are the same: the same method on the same
	 * object (identity) or on the same class name.
	--->
	<cffunction name="sameCallable" access="private" returntype="boolean" output="no">
		<cfargument name="a" type="any" required="yes">
		<cfargument name="b" type="any" required="yes">
		<cfset var system = CreateObject("java", "java.lang.System")>
		<cfset var ta = "">
		<cfset var tb = "">

		<cfif IsArray(arguments.a) AND IsArray(arguments.b)>
			<cfset ta = arguments.a[1]>
			<cfset tb = arguments.b[1]>

			<cfif Compare(arguments.a[2], arguments.b[2]) NEQ 0>
				<cfreturn false>
			</cfif>

			<cfif IsObject(ta) AND IsObject(tb)>
				<cfreturn system.identityHashCode(ta) EQ system.identityHashCode(tb)>
			</cfif>

			<cfif NOT IsObject(ta) AND NOT IsObject(tb)>
				<cfreturn Compare(ta, tb) EQ 0>
			</cfif>

			<cfreturn false>
		</cfif>

		<cfif NOT IsArray(arguments.a) AND NOT IsArray(arguments.b)>
			<cfreturn Compare(arguments.a, arguments.b) EQ 0>
		</cfif>

		<cfreturn false>
	</cffunction>

</cfcomponent>
