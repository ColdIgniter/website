<!---
 * Database Configuration
 *
 * Difference: the original extends CodeIgniter\Database\Config, which is
 * the connection manager. Here the class takes BaseConfig, which reads the
 * environment, and the manager is static_("ColdIgniter\Database\Config").
 *
 * Difference: each connection group is a map (see array_()), and a null is
 * an empty string. A boolean is the text "true" or "false".
 *
 * Difference: the original constructor sets defaultGroup to "tests" when
 * the environment is "testing". The constructor of BaseConfig cannot be
 * called from a constructor of this class, so connect() of the manager
 * does it: it picks the group "tests" when the environment is "testing".
 *
 * Not ported yet: the sample connections for the other drivers (the
 * comments of the original), as no driver is ported.
--->
<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="Database Configuration">

	<!---
	 * The directory that holds the Migrations and Seeds directories.
	--->
	<cfset this.filesPath = request.APPPATH & "Database" & request.DIRECTORY_SEPARATOR>

	<!---
	 * Lets you choose which connection group to use if no other is specified.
	--->
	<cfset this.defaultGroup = "default">

	<!---
	 * The default database connection.
	 *
	 * @var array<string, mixed>
	--->
	<cfset this.default = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.default["DSN"] = "">
	<cfset this.default["hostname"] = "localhost">
	<cfset this.default["username"] = "">
	<cfset this.default["password"] = "">
	<cfset this.default["database"] = "">
	<cfset this.default["DBDriver"] = "MySQLi">
	<cfset this.default["DBPrefix"] = "">
	<cfset this.default["pConnect"] = false>
	<cfset this.default["DBDebug"] = true>
	<cfset this.default["charset"] = "utf8mb4">
	<cfset this.default["DBCollat"] = "utf8mb4_general_ci">
	<cfset this.default["swapPre"] = "">
	<cfset this.default["encrypt"] = false>
	<cfset this.default["compress"] = false>
	<cfset this.default["strictOn"] = false>
	<cfset this.default["failover"] = ArrayNew(1)>
	<cfset this.default["port"] = 3306>
	<cfset this.default["numberNative"] = false>
	<cfset this.default["foundRows"] = false>
	<cfset this.default["dateFormat"] = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.default["dateFormat"]["date"] = "Y-m-d">
	<cfset this.default["dateFormat"]["datetime"] = "Y-m-d H:i:s">
	<cfset this.default["dateFormat"]["time"] = "H:i:s">

	<!---
	 * This database connection is used when running the automated database tests.
	 *
	 * @var array<string, mixed>
	--->
	<cfset this.tests = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.tests["DSN"] = "">
	<cfset this.tests["hostname"] = "127.0.0.1">
	<cfset this.tests["username"] = "">
	<cfset this.tests["password"] = "">
	<cfset this.tests["database"] = ":memory:">
	<cfset this.tests["DBDriver"] = "SQLite3">
	<cfset this.tests["DBPrefix"] = "db_">
	<cfset this.tests["pConnect"] = false>
	<cfset this.tests["DBDebug"] = true>
	<cfset this.tests["charset"] = "utf8">
	<cfset this.tests["DBCollat"] = "">
	<cfset this.tests["swapPre"] = "">
	<cfset this.tests["encrypt"] = false>
	<cfset this.tests["compress"] = false>
	<cfset this.tests["strictOn"] = true>
	<cfset this.tests["failover"] = ArrayNew(1)>
	<cfset this.tests["port"] = 3306>
	<cfset this.tests["foreignKeys"] = true>
	<cfset this.tests["busyTimeout"] = 1000>
	<cfset this.tests["synchronous"] = "">
	<cfset this.tests["dateFormat"] = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.tests["dateFormat"]["date"] = "Y-m-d">
	<cfset this.tests["dateFormat"]["datetime"] = "Y-m-d H:i:s">
	<cfset this.tests["dateFormat"]["time"] = "H:i:s">

</cfcomponent>
