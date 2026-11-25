<!---
 * Session configuration.
 *
 * Not ported yet: the Memcached and Redis handlers (the driver list names
 * the ones that exist), and so lockRetryInterval and lockMaxRetries, which
 * only those handlers use.
--->
<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="Session configuration">

	<!---
	 * --------------------------------------------------------------------------
	 * Session Driver
	 * --------------------------------------------------------------------------
	 *
	 * The session storage driver to use:
	 * - `ColdIgniter\Session\Handlers\ArrayHandler` (for testing)
	 * - `ColdIgniter\Session\Handlers\FileHandler`
	 * - `ColdIgniter\Session\Handlers\DatabaseHandler`
	 *
	 * The FileHandler keeps the sessions on each server. Behind a load
	 * balancer, use the DatabaseHandler (see the schema in the comment
	 * below) or sticky sessions.
	 *
	 * @var class-string<BaseHandler>
	--->
	<cfset this.driver = "ColdIgniter\Session\Handlers\FileHandler">

	<!---
	 * --------------------------------------------------------------------------
	 * Session Cookie Name
	 * --------------------------------------------------------------------------
	 *
	 * The session cookie name, must contain only [0-9a-z_-] characters
	 *
	 * @var string
	--->
	<cfset this.cookieName = "ci_session">

	<!---
	 * --------------------------------------------------------------------------
	 * Session Expiration
	 * --------------------------------------------------------------------------
	 *
	 * The number of SECONDS you want the session to last.
	 * Setting to 0 (zero) means expire when the browser is closed.
	 *
	 * @var int
	--->
	<cfset this.expiration = 7200>

	<!---
	 * --------------------------------------------------------------------------
	 * Session Save Path
	 * --------------------------------------------------------------------------
	 *
	 * The location to save sessions to and is driver dependent.
	 *
	 * For the 'files' driver, it's a path to a writable directory.
	 * WARNING: Only absolute paths are supported!
	 *
	 * For the 'database' driver, it's a table name.
	 * Please read up the manual for the format with other session drivers.
	 *
	 * IMPORTANT: You are REQUIRED to set a valid save path!
	 *
	 * @var string
	--->
	<cfset this.savePath = request.WRITEPATH & "session">

	<!---
	 * --------------------------------------------------------------------------
	 * Session Match IP
	 * --------------------------------------------------------------------------
	 *
	 * Whether to match the user's IP address when reading the session data.
	 *
	 * WARNING: If you're using the database driver, don't forget to update
	 *          your session table's PRIMARY KEY when changing this setting.
	 *
	 * @var bool
	--->
	<cfset this.matchIP = false>

	<!---
	 * --------------------------------------------------------------------------
	 * Session Time to Update
	 * --------------------------------------------------------------------------
	 *
	 * How many seconds between ColdIgniter regenerating the session ID.
	 *
	 * @var int
	--->
	<cfset this.timeToUpdate = 300>

	<!---
	 * --------------------------------------------------------------------------
	 * Session Regenerate Destroy
	 * --------------------------------------------------------------------------
	 *
	 * Whether to destroy session data associated with the old session ID
	 * when auto-regenerating the session ID. When set to FALSE, the data
	 * will be later deleted by the garbage collector.
	 *
	 * @var bool
	--->
	<cfset this.regenerateDestroy = false>

	<!---
	 * --------------------------------------------------------------------------
	 * Session Database Group
	 * --------------------------------------------------------------------------
	 *
	 * DB Group for the database session. An empty string is null: the
	 * default group of Config\Database is used.
	 *
	 * @var string|null
	--->
	<cfset this.DBGroup = "">

</cfcomponent>
