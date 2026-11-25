<!---
 * --------------------------------------------------------------------
 * Application Events
 * --------------------------------------------------------------------
 * Events allow you to tap into the execution of the program without
 * modifying or extending core files. This file provides a central
 * location to define your events, though they can always be added
 * at run-time, also, if needed.
 *
 * You create code that can execute by subscribing to events with
 * the 'on()' method. This accepts a callable that will be executed
 * when the event is triggered. There are no closures here: a callable
 * is a list of an object (or a class name) and a method name. See the top
 * of system/Events/Events.cfc.
 *
 * Example:
 *      <cfset myCallable = ArrayNew(1)>
 *      <cfset ArrayAppend(myCallable, myInstance)>
 *      <cfset ArrayAppend(myCallable, "myMethod")>
 *      <cfset static_("ColdIgniter\Events\Events").on("create", myCallable)>
 *
 * This file is included by Events::initialize_().
 *
 * Not ported yet: the part of the pre_system listener of the original that
 * checks that the output compression of the engine is off and starts output
 * buffering (neither applies: the output is not written from the framework),
 * and the hot reload route.
--->

<!---
 * --------------------------------------------------------------------
 * Debug Toolbar Listeners.
 * --------------------------------------------------------------------
 * If you delete, they will no longer be collected.
 *
 * Difference: there are no closures, so the listener of the original,
 * which calls service("toolbar").respond(), is the callable
 * [toolbar, "respond"]. The DBQuery listener, which the original adds
 * inside that listener, is added here.
--->
<cfif request.CI_DEBUG>
	<cfset toolbarListener = ArrayNew(1)>
	<cfset ArrayAppend(toolbarListener, service("toolbar"))>
	<cfset ArrayAppend(toolbarListener, "respond")>
	<cfset static_("ColdIgniter\Events\Events").on("DBQuery", "ColdIgniter\Debug\Toolbar\Collectors\Database::collect")>
	<cfset static_("ColdIgniter\Events\Events").on("pre_system", toolbarListener)>
</cfif>
