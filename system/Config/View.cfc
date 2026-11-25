<!---
 * View configuration
 *
 * Not ported yet: the coreFilters and corePlugins lists hold function
 * names for the Parser, which is not ported.
--->
<cfcomponent output="no" extends="BaseConfig" hint="View configuration">

	<!---
	 * When false, the view method will clear the data between each
	 * call.
	--->
	<cfset this.saveData = true>

	<!---
	 * Parser Filters map a filter name with any callable. When the
	 * Parser prepares a variable for display, it will chain it
	 * through the filters in the order defined, inserting any parameters.
	 *
	 * To prevent potential abuse, all filters MUST be defined here
	 * in order for them to be available for use within the Parser.
	--->
	<cfset this.filters = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Parser Plugins provide a way to extend the functionality provided
	 * by the core Parser by creating aliases that will be replaced with
	 * any callable. Can be single or tag pair.
	--->
	<cfset this.plugins = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Built-in View filters.
	--->
	<cfset this.coreFilters = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Built-in View plugins.
	--->
	<cfset this.corePlugins = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Merge the built-in and developer-configured filters and plugins,
	 * with preference to the developer ones.
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfset this.filters = array_merge(this.coreFilters, this.filters)>
		<cfset this.plugins = array_merge(this.corePlugins, this.plugins)>

		<cfset super.__construct()>

		<cfreturn this>
	</cffunction>

</cfcomponent>
