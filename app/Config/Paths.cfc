<!---
 * Paths
 *
 * Holds the paths that are used by the system to
 * locate the main directories, app, system, etc.
 *
 * Modifying these allows you to restructure your application,
 * share a system folder between multiple applications, and more.
 *
 * All paths are relative to the project's root folder.
 *
 * NOTE: This class is required prior to Autoloader instantiation,
 *       and does not extend BaseConfig.
--->
<cfcomponent output="no">

	<!--- The folder this file is in, without a trailing slash. --->
	<cfset __DIR__ = GetDirectoryFromPath(GetCurrentTemplatePath())>
	<cfset __DIR__ = Left(__DIR__, Len(__DIR__) - 1)>

	<!---
	 * ---------------------------------------------------------------
	 * SYSTEM FOLDER NAME
	 * ---------------------------------------------------------------
	 *
	 * This must contain the name of your "system" folder. Include
	 * the path if the folder is not in the same directory as this file.
	--->
	<cfset this.systemDirectory = __DIR__ & "/../../system">

	<!---
	 * ---------------------------------------------------------------
	 * APPLICATION FOLDER NAME
	 * ---------------------------------------------------------------
	 *
	 * If you want this front controller to use a different "app"
	 * folder than the default one you can set its name here. The folder
	 * can also be renamed or relocated anywhere on your server. If
	 * you do, use a full server path.
	--->
	<cfset this.appDirectory = __DIR__ & "/..">

	<!---
	 * ---------------------------------------------------------------
	 * WRITABLE DIRECTORY NAME
	 * ---------------------------------------------------------------
	 *
	 * This variable must contain the name of your "writable" directory.
	 * The writable directory allows you to group all directories that
	 * need write permission to a single place that can be tucked away
	 * for maximum security, keeping it out of the app and/or
	 * system directories.
	--->
	<cfset this.writableDirectory = __DIR__ & "/../../writable">

	<!---
	 * ---------------------------------------------------------------
	 * TESTS DIRECTORY NAME
	 * ---------------------------------------------------------------
	 *
	 * This variable must contain the name of your "tests" directory.
	--->
	<cfset this.testsDirectory = __DIR__ & "/../../tests">

	<!---
	 * ---------------------------------------------------------------
	 * VIEW DIRECTORY NAME
	 * ---------------------------------------------------------------
	 *
	 * This variable must contain the name of the directory that
	 * contains the view files used by your application. By
	 * default this is in `app/Views`. This value
	 * is used when no value is provided to `Services::renderer()`.
	--->
	<cfset this.viewDirectory = __DIR__ & "/../Views">

	<!---
	 * ---------------------------------------------------------------
	 * ENVIRONMENT DIRECTORY NAME
	 * ---------------------------------------------------------------
	 *
	 * This variable must contain the name of the directory where
	 * the .env file is located.
	 * Please consider security implications when changing this
	 * value - the directory should not be publicly accessible.
	--->
	<cfset this.envDirectory = __DIR__ & "/../../">

</cfcomponent>
