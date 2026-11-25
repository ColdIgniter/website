<!---
 * Cache configuration.
 *
 * Not ported yet: the options memcached and redis, and the option mode of
 * file (there is no chmod), because the handlers that use them are not
 * ported.
--->
<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="Cache configuration">

	<!---
	 * --------------------------------------------------------------------------
	 * Primary Handler
	 * --------------------------------------------------------------------------
	 *
	 * The name of the preferred handler that should be used. If for some reason
	 * it is not available, the $backupHandler will be used in its place.
	 *
	 * The file cache and the front page cache belong to each server, unless
	 * writable/cache is a folder that the servers share. They check the
	 * change time of each file, so a shared folder stays correct. Without a
	 * shared folder, a cached page or a cache delete only affects that one
	 * server.
	--->
	<cfset this.handler = "file">

	<!---
	 * --------------------------------------------------------------------------
	 * Backup Handler
	 * --------------------------------------------------------------------------
	 *
	 * The name of the handler that will be used in case the first one is
	 * unreachable. Often, 'file' is used here since the filesystem is
	 * always available, though that's not always practical for the app.
	--->
	<cfset this.backupHandler = "dummy">

	<!---
	 * --------------------------------------------------------------------------
	 * Key Prefix
	 * --------------------------------------------------------------------------
	 *
	 * This string is added to all cache item names to help avoid collisions
	 * if you run multiple applications with the same cache engine.
	--->
	<cfset this.prefix = "">

	<!---
	 * --------------------------------------------------------------------------
	 * Default TTL
	 * --------------------------------------------------------------------------
	 *
	 * The default number of seconds to save items when none is specified.
	 *
	 * WARNING: This is not used by framework handlers where 60 seconds is
	 * hard-coded, but may be useful to projects and modules. This will replace
	 * the hard-coded value in a future release.
	--->
	<cfset this.ttl = 60>

	<!---
	 * --------------------------------------------------------------------------
	 * Reserved Characters
	 * --------------------------------------------------------------------------
	 *
	 * A string of reserved characters that will not be allowed in keys or tags.
	 * Strings that violate this restriction will cause handlers to throw.
	 * Default: {}()/\@:
	 *
	 * NOTE: The default set is required for PSR-6 compliance.
	--->
	<cfset this.reservedCharacters = "{}()/\@:">

	<!---
	 * --------------------------------------------------------------------------
	 * File settings
	 * --------------------------------------------------------------------------
	 *
	 * Your file storage preferences can be specified below, if you are using
	 * the File driver.
	 *
	 * Named with an underscore, because "file" is a scope.
	 *
	 * Difference: memoryEntries is not in the original. It is the number
	 * of cached items (pages) that the file handler keeps in memory, in the
	 * application scope of the server, so that a hit does not read the file.
	 * The files stay the durable copy. 0 switches it off.
	 *
	 * @var map {storePath, memoryEntries}
	--->
	<cfset this.file_ = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.file_.put("storePath", request.WRITEPATH & "cache/")>
	<cfset this.file_.put("memoryEntries", "100")>

	<!---
	 * --------------------------------------------------------------------------
	 * Front pages
	 * --------------------------------------------------------------------------
	 *
	 * Difference: not in the original. When true, a page of the page cache
	 * (cachePage() in a controller) is also kept in the memory of the
	 * server, and the front controller serves it from there before the
	 * framework starts. That is the fastest way to serve a page.
	 *
	 * For a page served this way nothing of the framework runs: not the
	 * pre_system and post_system events, and no filters. It is used only for
	 * a GET request, outside development mode, with the file handler and
	 * its memoryEntries above 0, with the stock required filters, and for a
	 * response without cookies. The page is dropped when its cache file
	 * changes, is deleted or expires, and when Config\App, Config\Cache,
	 * Config\Filters or the .env file changes.
	 *
	 * @var boolean
	--->
	<cfset this.frontPages = true>

	<!---
	 * --------------------------------------------------------------------------
	 * Available Cache Handlers
	 * --------------------------------------------------------------------------
	 *
	 * This is a map of cache engine alias' and class names. Only engines
	 * that are listed here are allowed to be used.
	 *
	 * Not ported yet: apcu, memcached, predis, redis and wincache.
	 *
	 * @var map of name -> class name
	--->
	<cfset this.validHandlers = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.validHandlers.put("dummy", "ColdIgniter\Cache\Handlers\DummyHandler")>
	<cfset this.validHandlers.put("file", "ColdIgniter\Cache\Handlers\FileHandler")>

	<!---
	 * --------------------------------------------------------------------------
	 * Web Page Caching: Cache Include Query String
	 * --------------------------------------------------------------------------
	 *
	 * Whether to take the URL query string into consideration when generating
	 * output cache files. Valid options are:
	 *
	 *    false = Disabled
	 *    true  = Enabled, take all query parameters into account.
	 *            Please be aware that this may result in numerous cache
	 *            files generated for the same page over and over again.
	 *    list  = Enabled, but only take into account the specified list
	 *            of query parameters (an array of names).
	 *
	 * @var boolean|array
	--->
	<cfset this.cacheQueryString = false>

	<!---
	 * --------------------------------------------------------------------------
	 * Web Page Caching: Cache Status Codes
	 * --------------------------------------------------------------------------
	 *
	 * HTTP status codes that are allowed to be cached. Only responses with
	 * these status codes will be cached by the PageCache filter.
	 *
	 * Default: [] - Cache all status codes (backward compatible)
	 *
	 * WARNING: Using [] may cache undesired responses (404s, 500s).
	 * Consider setting an explicit list of status codes.
	 *
	 * Recommended: [200] - Only cache successful responses
	 *
	 * @var array of status codes
	--->
	<cfset this.cacheStatusCodes = ArrayNew(1)>

</cfcomponent>
