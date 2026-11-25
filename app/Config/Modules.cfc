<!---
 * Modules Configuration.
 *
 * NOTE: This class is required prior to Autoloader instantiation,
 *       and does not extend BaseConfig.
--->
<cfcomponent output="no" parent="ColdIgniter\Modules\Modules">

	<!---
	 * --------------------------------------------------------------------------
	 * Enable Auto-Discovery?
	 * --------------------------------------------------------------------------
	 *
	 * If true, then auto-discovery will happen across all elements listed in
	 * $aliases below. If false, no auto-discovery will happen at all,
	 * giving a slight performance boost.
	--->
	<cfset this.enabled = true>

	<!---
	 * --------------------------------------------------------------------------
	 * Enable Auto-Discovery Within Composer Packages?
	 * --------------------------------------------------------------------------
	 *
	 * If true, then auto-discovery will happen across all namespaces loaded
	 * by Composer, as well as the namespaces configured locally.
	--->
	<cfset this.discoverInComposer = true>

	<!---
	 * The Composer package list for Auto-Discovery
	 * This setting is optional.
	 *
	 * E.g.:
	 *   [
	 *       'only' => [
	 *           // List up all packages to auto-discover
	 *           'codeigniter4/shield',
	 *       ],
	 *   ]
	 *   or
	 *   [
	 *       'exclude' => [
	 *           // List up packages to exclude.
	 *           'vendor/package',
	 *       ],
	 *   ]
	--->
	<cfset this.composerPackages = ArrayNew(1)>

	<!---
	 * --------------------------------------------------------------------------
	 * Auto-Discovery Rules
	 * --------------------------------------------------------------------------
	 *
	 * Aliases list of all discovery classes that will be active and used during
	 * the current application request.
	 *
	 * If it is not listed, only the base application elements will be used.
	--->
	<cfset this.aliases = ArrayNew(1)>
	<cfset ArrayAppend(this.aliases, "events")>
	<cfset ArrayAppend(this.aliases, "filters")>
	<cfset ArrayAppend(this.aliases, "registrars")>
	<cfset ArrayAppend(this.aliases, "routes")>
	<cfset ArrayAppend(this.aliases, "services")>

</cfcomponent>
