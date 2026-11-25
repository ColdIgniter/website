<!---
 * Factories for creating instances.
 *
 * Factories allow dynamic loading of components by their path
 * and name. The "shared instance" implementation provides a
 * large performance boost and helps keep code clean of lengthy
 * instantiation checks.
 *
 * The class is static in the original. Here it is used through
 * static_("ColdIgniter\Config\Factories").
 *
 * Not ported yet: options, the locator search for a class by its short
 * name in every namespace, injectMock, reset, and the factories cache.
 * A short name is looked for in the Config namespace only.
--->
<cfcomponent output="no" hint="Factories for creating instances">

	<!---
	 * Explicit options for the Config
	 * component to prevent logic loops.
	--->
	<cfset this.configOptions = StructNew()>
	<cfset this.configOptions["component"] = "config">
	<cfset this.configOptions["path"] = "Config">
	<cfset this.configOptions["instanceOf"] = "">
	<cfset this.configOptions["getShared"] = true>
	<cfset this.configOptions["preferApp"] = true>

	<!---
	 * Mapping of class aliases to their true Fully Qualified Class Name (FQCN).
	 *
	 * Class aliases can be:
	 *     - FQCN. E.g., 'App\Lib\SomeLib'
	 *     - short classname. E.g., 'SomeLib'
	 *     - short classname with sub-directories. E.g., 'Sub/SomeLib'
	 *
	 * [component => [alias => FQCN]]
	--->
	<cfset this.aliases = StructNew()>

	<!---
	 * Store for instances of any component that
	 * has been requested as "shared".
	 *
	 * A multi-dimensional array with components as
	 * keys to the array of name-indexed instances.
	 *
	 * [component => [FQCN => instance]]
	--->
	<cfset this.instances = StructNew()>

	<!---
	 * Simple method to get the shared instance fast.
	--->
	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="component" type="string" required="yes">
		<cfargument name="alias" type="string" required="yes">
		<cfset var class = "">
		<cfset var arguments_ = ArrayNew(1)>

		<cfif StructKeyExists(this.aliases, arguments.component) AND StructKeyExists(this.aliases[arguments.component], arguments.alias)>
			<cfset class = this.aliases[arguments.component][arguments.alias]>

			<cfif StructKeyExists(this.instances[arguments.component], class)>
				<cfreturn this.instances[arguments.component][class]>
			</cfif>
		</cfif>

		<cfset ArrayAppend(arguments_, arguments.alias)>

		<cfreturn __callStatic(arguments.component, arguments_)>
	</cffunction>

	<!---
	 * Loads instances based on the method component name. Either
	 * creates a new instance or returns an existing shared instance.
	 *
	 * @return The instance, or an empty string if the class is not found
	--->
	<cffunction name="__callStatic" access="public" returntype="any" output="no">
		<cfargument name="component" type="string" required="yes">
		<cfargument name="arguments_" type="array" required="yes">
		<cfset var alias = arguments.arguments_[1]>
		<cfset var options = StructNew()>
		<cfset var class = "">

		<cfset arguments.component = LCase(arguments.component)>

		<!--- Determine the component-specific options --->
		<cfif ArrayLen(arguments.arguments_) GT 1>
			<cfset options = arguments.arguments_[2]>
		</cfif>

		<cfset alias = REReplace(alias, "^\\+", "")>

		<cfif NOT StructKeyExists(this.aliases, arguments.component)>
			<cfset this.aliases[arguments.component] = StructNew()>
			<cfset this.instances[arguments.component] = StructNew()>
		</cfif>

		<cfif StructKeyExists(options, "getShared") AND NOT options["getShared"]>
			<cfif StructKeyExists(this.aliases[arguments.component], alias)>
				<cfreturn new_(this.aliases[arguments.component][alias])>
			</cfif>

			<!--- Try to locate the class --->
			<cfset class = locateClass(arguments.component, alias)>
			<cfif class NEQ "">
				<cfreturn new_(class)>
			</cfif>

			<cfreturn "">
		</cfif>

		<!--- Check for an existing definition --->
		<cfif StructKeyExists(this.aliases[arguments.component], alias)>
			<cfset class = this.aliases[arguments.component][alias]>

			<cfif StructKeyExists(this.instances[arguments.component], class)>
				<cfreturn this.instances[arguments.component][class]>
			</cfif>
		</cfif>

		<!--- Try to locate the class --->
		<cfset class = locateClass(arguments.component, alias)>
		<cfif class EQ "">
			<cfreturn "">
		</cfif>

		<cfset this.instances[arguments.component][class] = new_(class)>
		<cfset this.aliases[arguments.component][alias] = class>

		<!--- If a short classname is specified, also register FQCN to share the instance. --->
		<cfif NOT StructKeyExists(this.aliases[arguments.component], class)>
			<cfset this.aliases[arguments.component][class] = class>
		</cfif>

		<cfreturn this.instances[arguments.component][class]>
	</cffunction>

	<!---
	 * Finds a component class
	 *
	 * @param alias Class alias. See the aliases property.
	 *
	 * @return The class name, or an empty string if it is not found
	--->
	<cffunction name="locateClass" access="private" returntype="string" output="no">
		<cfargument name="component" type="string" required="yes">
		<cfargument name="alias" type="string" required="yes">
		<cfset var class = "">

		<!--- Check if the class alias was namespaced --->
		<cfif Find("\", arguments.alias) GT 0>
			<cfif class_exists(arguments.alias)>
				<cfreturn arguments.alias>
			</cfif>

			<cfreturn "">
		</cfif>

		<!--- Have to do this the hard way... --->
		<cfset class = this.configOptions["path"] & "\" & Replace(arguments.alias, "/", "\", "all")>
		<cfif class_exists(class)>
			<cfreturn class>
		</cfif>

		<cfreturn "">
	</cffunction>

</cfcomponent>
