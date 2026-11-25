<!---
 * -------------------------------------------------------------------
 * AUTOLOADER CONFIGURATION
 * -------------------------------------------------------------------
 *
 * This file defines the namespaces and class maps so the Autoloader
 * can find the files as needed.
 *
 * NOTE: If you use an identical key in $psr4 or $classmap, then
 *       the values in this file will overwrite the framework's values.
 *
 * NOTE: This class is required prior to Autoloader instantiation,
 *       and does not extend BaseConfig.
--->
<cfcomponent output="no" parent="ColdIgniter\Config\AutoloadConfig">

	<!---
	 * -------------------------------------------------------------------
	 * Namespaces
	 * -------------------------------------------------------------------
	 * This maps the locations of any namespaces in your application to
	 * their location on the file system. These are used by the autoloader
	 * to locate files the first time they have been instantiated.
	 *
	 * The 'Config' (APPPATH . 'Config') and 'ColdIgniter' (SYSTEMPATH) are
	 * already mapped for you.
	 *
	 * You may change the name of the 'App' namespace if you wish,
	 * but this should be done prior to creating any namespaced classes,
	 * else you will need to modify all of those classes for this to work.
	--->
	<cfset this.psr4 = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.psr4[request.APP_NAMESPACE] = request.APPPATH>

	<!---
	 * -------------------------------------------------------------------
	 * Class Map
	 * -------------------------------------------------------------------
	 * The class map provides a map of class names and their exact
	 * location on the drive. Classes loaded in this manner will have
	 * slightly faster performance because they will not have to be
	 * searched for within one or more directories as they would if they
	 * were being autoloaded through a namespace.
	 *
	 * Prototype:
	 *   $classmap = [
	 *       'MyClass'   => '/path/to/class/file.cfc'
	 *   ];
	--->
	<cfset this.classmap = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * -------------------------------------------------------------------
	 * Files
	 * -------------------------------------------------------------------
	 * The files array provides a list of paths to __non-class__ files
	 * that will be autoloaded. This can be useful for bootstrap operations
	 * or for loading functions.
	 *
	 * Prototype:
	 *   $files = [
	 *       '/path/to/my/file.cfm',
	 *   ];
	--->
	<cfset this.files = ArrayNew(1)>

	<!---
	 * -------------------------------------------------------------------
	 * Helpers
	 * -------------------------------------------------------------------
	 * Prototype:
	 *   $helpers = [
	 *       'form',
	 *   ];
	--->
	<cfset this.helpers = ArrayNew(1)>

</cfcomponent>
