<cfsetting enablecfoutputonly="yes">
<!---
 *---------------------------------------------------------------
 * SET THE CURRENT DIRECTORY
 *---------------------------------------------------------------
--->

<!--- Path to the front controller (this file) --->
<cfset request.FCPATH = GetDirectoryFromPath(GetCurrentTemplatePath())>

<!---
 Not in the original. The application scope of this site is switched on
 here, once, for the page cache and for the tables that the framework keeps
 between requests (shared_() in Polyfills). The name is made from the path
 of this folder. A site that has its own Application.cfm has its
 application (and so its session scope) renamed by this line for the rest
 of the request. request.ColdIgniterApplication says whether the scope
 can be used: a server with application variables switched off still works,
 only without those memories.
--->
<cfset request.ColdIgniterApplication = false>

<cftry>
	<cfapplication name="ColdIgniter#LCase(Hash(request.FCPATH))#">
	<cfset request.ColdIgniterApplication = IsStruct(application)>

	<cfcatch type="any">
		<cfset request.ColdIgniterApplication = false>
	</cfcatch>
</cftry>

<!---
 *---------------------------------------------------------------
 * BOOTSTRAP THE APPLICATION
 *---------------------------------------------------------------
 * This process sets up the path constants, loads and registers
 * our autoloader, loads our constants and fires up an
 * environment-specific bootstrapping.
--->

<!--- LOAD OUR PATHS CONFIG FILE --->
<!--- This is the line that might need to be changed, depending on your folder structure. --->
<cfinclude template="../app/Config/Paths.cfm">
<!--- ^^^ Change this line if you move your application folder --->

<!--- cfinclude only takes a relative path, so the system folder is reached from the top of the drive. --->
<cfset rootDirectory = RepeatString("../", ListLen(REReplace(request.FCPATH, "^[A-Za-z]:", ""), "\/"))>
<cfset systemDirectory = rootDirectory & REReplace(Replace(paths.systemDirectory, "\", "/", "all"), "^([A-Za-z]:)?/", "")>

<!---
 *---------------------------------------------------------------
 * CHECK CFML VERSION
 *---------------------------------------------------------------
--->
<cfinclude template="#systemDirectory#/Polyfills/version_compare.cfm">

<cfset minCfmlVersion = "6.1">
<cfset cfmlVersion = Replace(Server.ColdFusion.ProductVersion, ",", ".", "all")>
<cfif version_compare(cfmlVersion, minCfmlVersion, "lt")>
	<cfset message = "Your CFML version must be #minCfmlVersion# or higher to run ColdIgniter. Current version: #cfmlVersion#">

	<cfheader statuscode="503" statustext="Service Unavailable">
	<cfoutput>#message#</cfoutput>

	<cfabort>
</cfif>

<!---
 Not in the original. A page of the page cache that is kept in the memory
 of the application (this site) is served here, before the framework starts (see the file).
--->
<cfinclude template="#systemDirectory#/Cache/FrontPage.cfm">

<!--- LOAD THE FRAMEWORK BOOTSTRAP FILE --->
<cfinclude template="#systemDirectory#/Boot.cfm">

<cfset Boot.bootWeb(paths)>

<!---
 Not in the original. The page buffer holds 8 KB by default, and a longer
 body leaves in many small parts, which is slow (over a second for 125 KB).
 The buffer is made as large as the body (counted in characters), so the
 body leaves in one part. The server keeps the larger buffer for later
 requests, so it never grows past 1 MB.
--->
<cftry>
	<cfif Len(request.ColdIgniter.output) GT GetPageContext().getResponse().getBufferSize()>
		<cfset GetPageContext().getResponse().setBufferSize(JavaCast("int", Min(Len(request.ColdIgniter.output) + 4096, 1048576)))>
	</cfif>

	<cfcatch type="any"></cfcatch>
</cftry>

<!--- No output can leave a method, so the response leaves the body here to be written. --->
<cfoutput>#request.ColdIgniter.output#</cfoutput>
