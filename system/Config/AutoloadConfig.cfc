<!---
 * AUTOLOADER CONFIGURATION
 *
 * This file defines the namespaces and class maps so the Autoloader
 * can find the files as needed.
--->
<cfcomponent output="no" hint="Autoloader configuration">

	<!---
	 * -------------------------------------------------------------------
	 * Namespaces
	 * -------------------------------------------------------------------
	 * This maps the locations of any namespaces in your application to
	 * their location on the file system. These are used by the autoloader
	 * to locate files the first time they have been instantiated.
	 *
	 * The '/app' and '/system' directories are already mapped for you.
	 * you may change the name of the 'App' namespace if you wish,
	 * but this should be done prior to creating any namespaced classes,
	 * else you will need to modify all of those classes for this to work.
	--->
	<cfset this.psr4 = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * -------------------------------------------------------------------
	 * Class Map
	 * -------------------------------------------------------------------
	 * The class map provides a map of class names and their exact
	 * location on the drive. Classes loaded in this manner will have
	 * slightly faster performance because they will not have to be
	 * searched for within one or more directories as they would if they
	 * were being autoloaded through a namespace.
	--->
	<cfset this.classmap = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * -------------------------------------------------------------------
	 * Files
	 * -------------------------------------------------------------------
	 * The files array provides a list of paths to __non-class__ files
	 * that will be autoloaded. This can be useful for bootstrap operations
	 * or for loading functions.
	--->
	<cfset this.files = ArrayNew(1)>

	<!---
	 * -------------------------------------------------------------------
	 * Namespaces
	 * -------------------------------------------------------------------
	 * This maps the locations of any namespaces in your application
	 * to their location on the file system. These are used by the
	 * Autoloader to locate files the first time they have been instantiated.
	 *
	 * Do not change the name of the ColdIgniter namespace or your application
	 * will break.
	--->
	<cfset this.corePsr4 = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.corePsr4["ColdIgniter"] = request.SYSTEMPATH>
	<cfset this.corePsr4["Config"] = request.APPPATH & "Config">

	<!---
	 * -------------------------------------------------------------------
	 * Class Map
	 * -------------------------------------------------------------------
	 * The class map provides a map of class names and their exact
	 * location on the drive.
	 *
	 * Not ported yet: the original lists the PSR and Laminas Escaper
	 * classes here.
	--->
	<cfset this.coreClassmap = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * -------------------------------------------------------------------
	 * Core Files
	 * -------------------------------------------------------------------
	 * List of files from the framework to be autoloaded early.
	--->
	<cfset this.coreFiles = ArrayNew(1)>

	<!---
	 * Constructor.
	 *
	 * Merge the built-in and developer-configured psr4 and classmap,
	 * with preference to the developer ones.
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<!--- Not ported yet: the ColdIgniter\Devkit namespace of the testing environment --->

		<cfset this.psr4 = array_merge(this.corePsr4, this.psr4)>
		<cfset this.classmap = array_merge(this.coreClassmap, this.classmap)>
		<cfset this.files = array_merge(this.coreFiles, this.files)>

		<cfreturn this>
	</cffunction>

</cfcomponent>
