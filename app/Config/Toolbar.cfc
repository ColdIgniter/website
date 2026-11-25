<!---
 * --------------------------------------------------------------------------
 * Debug Toolbar
 * --------------------------------------------------------------------------
 *
 * The Debug Toolbar provides a way to see information about the performance
 * and state of your application during that page display. By default it will
 * NOT be displayed under production environments, and will only display if
 * `CI_DEBUG` is true, since if it's not, there's not much to display anyway.
--->
<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="Debug Toolbar configuration">

	<!---
	 * --------------------------------------------------------------------------
	 * Toolbar Collectors
	 * --------------------------------------------------------------------------
	 *
	 * List of toolbar collectors that will be called when Debug Toolbar
	 * fires up and collects data from.
	 *
	 * A list of class names.
	 *
	 * Not ported yet: the Cache collector (it is commented out in the
	 * original as well).
	--->
	<cfset this.collectors = ArrayNew(1)>
	<cfset ArrayAppend(this.collectors, "ColdIgniter\Debug\Toolbar\Collectors\Timers")>
	<cfset ArrayAppend(this.collectors, "ColdIgniter\Debug\Toolbar\Collectors\Database")>
	<cfset ArrayAppend(this.collectors, "ColdIgniter\Debug\Toolbar\Collectors\Logs")>
	<cfset ArrayAppend(this.collectors, "ColdIgniter\Debug\Toolbar\Collectors\Views")>
	<!--- ColdIgniter\Debug\Toolbar\Collectors\Cache (not ported yet) --->
	<cfset ArrayAppend(this.collectors, "ColdIgniter\Debug\Toolbar\Collectors\Files")>
	<cfset ArrayAppend(this.collectors, "ColdIgniter\Debug\Toolbar\Collectors\Routes")>
	<cfset ArrayAppend(this.collectors, "ColdIgniter\Debug\Toolbar\Collectors\Events")>

	<!---
	 * --------------------------------------------------------------------------
	 * Collect Var Data
	 * --------------------------------------------------------------------------
	 *
	 * If set to false var data from the views will not be collected. Useful to
	 * avoid high memory usage when there are lots of data passed to the view.
	--->
	<cfset this.collectVarData = true>

	<!---
	 * --------------------------------------------------------------------------
	 * Max History
	 * --------------------------------------------------------------------------
	 *
	 * `maxHistory` sets a limit on the number of past requests that are stored,
	 * helping to conserve file space used to store them. You can set it to
	 * 0 (zero) to not have any history stored, or -1 for unlimited history.
	--->
	<cfset this.maxHistory = 20>

	<!---
	 * --------------------------------------------------------------------------
	 * Toolbar Views Path
	 * --------------------------------------------------------------------------
	 *
	 * The full path to the the views that are used by the toolbar.
	 * This MUST have a trailing slash.
	--->
	<cfset this.viewsPath = request.SYSTEMPATH & "Debug" & request.DIRECTORY_SEPARATOR & "Toolbar" & request.DIRECTORY_SEPARATOR & "Views" & request.DIRECTORY_SEPARATOR>

	<!---
	 * --------------------------------------------------------------------------
	 * Max Queries
	 * --------------------------------------------------------------------------
	 *
	 * If the Database Collector is enabled, it will log every query that the
	 * the system generates so they can be displayed on the toolbar's timeline
	 * and in the query log. This can lead to memory issues in some instances
	 * with hundreds of queries.
	 *
	 * `maxQueries` defines the maximum amount of queries that will be stored.
	--->
	<cfset this.maxQueries = 100>

	<!---
	 * --------------------------------------------------------------------------
	 * Watched Directories
	 * --------------------------------------------------------------------------
	 *
	 * Contains an array of directories that will be watched for changes and
	 * used to determine if the hot-reload feature should reload the page or not.
	 * We restrict the values to keep performance as high as possible.
	 *
	 * NOTE: The ROOTPATH will be prepended to all values.
	 *
	 * Not ported yet: the hot reload feature, so nothing reads this yet.
	--->
	<cfset this.watchedDirectories = ArrayNew(1)>
	<cfset ArrayAppend(this.watchedDirectories, "app")>

	<!---
	 * --------------------------------------------------------------------------
	 * Watched File Extensions
	 * --------------------------------------------------------------------------
	 *
	 * Contains an array of file extensions that will be watched for changes and
	 * used to determine if the hot-reload feature should reload the page or not.
	 *
	 * Difference: cfm and cfc are the extensions of the source files here, where
	 * the original lists its own. Not ported yet: the hot reload feature, so
	 * nothing reads this yet.
	--->
	<cfset this.watchedExtensions = ArrayNew(1)>
	<cfset ArrayAppend(this.watchedExtensions, "cfm")>
	<cfset ArrayAppend(this.watchedExtensions, "cfc")>
	<cfset ArrayAppend(this.watchedExtensions, "css")>
	<cfset ArrayAppend(this.watchedExtensions, "js")>
	<cfset ArrayAppend(this.watchedExtensions, "html")>
	<cfset ArrayAppend(this.watchedExtensions, "svg")>
	<cfset ArrayAppend(this.watchedExtensions, "json")>
	<cfset ArrayAppend(this.watchedExtensions, "env")>

	<!---
	 * --------------------------------------------------------------------------
	 * Ignored HTTP Headers
	 * --------------------------------------------------------------------------
	 *
	 * ColdIgniter Debug Toolbar normally injects HTML and JavaScript into every
	 * HTML response. This is correct for full page loads, but it breaks requests
	 * that expect only a clean HTML fragment.
	 *
	 * Libraries like HTMX, Unpoly, and Hotwire (Turbo) update parts of the page or
	 * manage navigation on the client side. Injecting the Debug Toolbar into their
	 * responses can cause invalid HTML, duplicated scripts, or JavaScript errors
	 * (such as infinite loops or "Maximum call stack size exceeded").
	 *
	 * Any request containing one of the following headers is treated as a
	 * client-managed or partial request, and the Debug Toolbar injection is skipped.
	 *
	 * A map (see java.util.LinkedHashMap) of header names to values. The value is an empty
	 * string where the original has null (any value of the header).
	--->
	<cfset this.disableOnHeaders = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.disableOnHeaders["X-Requested-With"] = "xmlhttprequest">
	<cfset this.disableOnHeaders["HX-Request"] = "true">
	<cfset this.disableOnHeaders["X-Up-Version"] = "">

</cfcomponent>
