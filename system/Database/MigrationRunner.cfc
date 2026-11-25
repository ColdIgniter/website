<!---
 * Class MigrationRunner
 *
 * There is no command line here: the methods are called from a controller
 * (or any code), and a message that the original keeps for the command
 * line is kept in the same list (getCliMessages()), without the colours.
 *
 * Difference: a migration file is a component, and a component name has to
 * be valid, so the file name is M<YmdHis>_<Name>.cfc (see
 * Config\Migrations). The class of a migration is the namespace,
 * Database\Migrations and the file name without ".cfc"; its version is the
 * timestamp and its name the part after the underscore. The regular
 * expression of the original, with its hyphen and underscore forms of the
 * timestamp, is replaced by the one in this.regex.
 *
 * Difference: the files are found in the folder Database/Migrations of the
 * folders of a namespace (the Autoloader's namespaces), with cfdirectory,
 * which has no recurse here: only that folder is searched, not the ones
 * below it.
 *
 * Difference: there is no stdClass; a migration and a history row are maps
 * (see array_()), read with brackets. There is no try/finally: the lock is
 * released by the methods that take it, on every way out (also an error,
 * which is thrown again). Time::now()->getTimestamp() is time().
 *
 * Difference: the original adds the progress lines to the cli messages only
 * when running in the command line (is_cli()); here that is never, so
 * addHistory() and removeHistory() add none. The lines the original
 * colours are added plain.
 *
 * Not ported yet: $path (a folder of migration files that replaces the
 * namespaces, which the original only uses in its tests).
--->
<cfcomponent output="no" hint="Class MigrationRunner">

	<!---
	 * Whether or not migrations are allowed to run.
	 *
	 * @var bool
	--->
	<cfset this.enabled = false>

	<!---
	 * Name of table to store meta information
	 *
	 * @var string
	--->
	<cfset this.table = "">

	<!---
	 * The Namespace where migrations can be found.
	 * An empty string (null in the original) is all namespaces.
	 *
	 * @var string
	--->
	<cfset this.namespace = request.APP_NAMESPACE>

	<!---
	 * The database Group to migrate.
	 *
	 * @var string
	--->
	<cfset this.group = "">

	<!---
	 * The migration name.
	 *
	 * @var string
	--->
	<cfset this.name = "">

	<!---
	 * The pattern used to locate migration file versions (see the top of
	 * this file). A regular expression for REFind(): the letter M, the
	 * timestamp, an underscore and the name.
	 *
	 * @var string
	--->
	<cfset this.regex = "^M[0-9]{14}_[A-Za-z0-9_]+$">

	<!---
	 * The main database connection. Used to store
	 * migration information in.
	 *
	 * @var BaseConnection
	--->
	<cfset this.db = "">

	<!---
	 * If true, will continue instead of throwing
	 * exceptions.
	 *
	 * @var bool
	--->
	<cfset this.silent = false>

	<!---
	 * used to return messages for CLI.
	 *
	 * @var list<string>
	--->
	<cfset this.cliMessages = ArrayNew(1)>

	<!---
	 * Tracks whether we have already ensured
	 * the table exists or not.
	 *
	 * @var bool
	--->
	<cfset this.tableChecked = false>

	<!---
	 * Lock the migration table.
	--->
	<cfset this.lock = false>

	<!---
	 * Tracks whether we have already ensured
	 * the lock table exists or not.
	--->
	<cfset this.lockTableChecked = false>

	<!---
	 * The database Group filter.
	 *
	 * @var string An empty string is null
	--->
	<cfset this.groupFilter = "">

	<!---
	 * Used to skip current migration.
	 *
	 * @var bool
	--->
	<cfset this.groupSkip = false>

	<!---
	 * The migration can manage multiple databases. So it should always use the
	 * default DB group so that it creates the `migrations` table in the default
	 * DB group. Therefore, passing $db is for testing purposes only.
	 *
	 * @param settings The Config\Migrations (not named config: that would hide config())
	 * @param db     DB group, a connection or a map of settings. For testing purposes only.
	 *               An empty string is the null of the original.
	 *
	 * @throws ConfigException
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="settings" type="any" required="yes">
		<cfargument name="db" type="any" required="no" default="">

		<cfset this.enabled = arguments.settings.enabled>
		<cfset this.table = arguments.settings.table>
		<cfset this.lock = arguments.settings.lock>

		<!--- Even if a DB connection is passed, since it is a test, it is assumed to use the default group name --->
		<cfif IsSimpleValue(arguments.db) AND Compare(arguments.db, "") NEQ 0>
			<cfset this.group = arguments.db>
		<cfelse>
			<cfset this.group = config("Config\Database").defaultGroup>
		</cfif>

		<cfset this.db = db_connect(arguments.db)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Locate and run all new migrations
	 *
	 * @param group An empty string is all groups
	 *
	 * @return bool
	 *
	 * @throws ConfigException
	 * @throws RuntimeException
	--->
	<cffunction name="latest" access="public" returntype="boolean" output="no">
		<cfargument name="group" type="string" required="no" default="">
		<cfset var result = false>

		<cfif NOT this.enabled>
			<cfset static_("ColdIgniter\Exceptions\ConfigException").forDisabledMigrations()>
		</cfif>

		<cfset ensureTable()>

		<!--- Try to acquire lock - exit gracefully if another process is running migrations --->
		<cfif this.lock AND NOT acquireMigrationLock()>
			<cfset ArrayAppend(this.cliMessages, Chr(9) & lang("Migrations.locked"))>

			<cfreturn true>
		</cfif>

		<cftry>
			<cfset result = runLatest(arguments.group)>

			<cfcatch type="any">
				<cfif this.lock>
					<cfset releaseMigrationLock()>
				</cfif>

				<cfrethrow>
			</cfcatch>
		</cftry>

		<cfif this.lock>
			<cfset releaseMigrationLock()>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * Not in the original. The part of latest() that runs under the lock.
	--->
	<cffunction name="runLatest" access="private" returntype="boolean" output="no">
		<cfargument name="group" type="string" required="yes">
		<cfset var migrations = "">
		<cfset var uids = "">
		<cfset var history = "">
		<cfset var batch = 0>
		<cfset var message = "">
		<cfset var data = "">
		<cfset var i = 0>

		<cfif Compare(arguments.group, "") NEQ 0>
			<cfset this.groupFilter = arguments.group>
			<cfset setGroup(arguments.group)>
		</cfif>

		<cfset migrations = findMigrations()>

		<cfif StructCount(migrations) EQ 0>
			<cfreturn true>
		</cfif>

		<cfset history = getHistory(arguments.group)>

		<cfloop from="1" to="#ArrayLen(history)#" index="i">
			<cfset StructDelete(migrations, getObjectUid(history[i]))>
		</cfloop>

		<cfset batch = getLastBatch() + 1>
		<cfset uids = array_keys(migrations)>

		<cfloop from="1" to="#ArrayLen(uids)#" index="i">
			<cfif migrate("up", migrations[uids[i]])>
				<cfif this.groupSkip>
					<cfset this.groupSkip = false>
				<cfelse>
					<cfset addHistory(migrations[uids[i]], batch)>
				</cfif>
			<cfelse>
				<cfset this.regress(-1)>

				<cfset message = lang("Migrations.generalFault")>

				<cfif this.silent>
					<cfset ArrayAppend(this.cliMessages, Chr(9) & message)>

					<cfreturn false>
				</cfif>

				<cfthrow type="ColdIgniter.RuntimeException" message="#message#">
			</cfif>
		</cfloop>

		<cfset data = array_("enabled", this.enabled, "table", this.table, "namespace", this.namespace, "group", this.group, "name", this.name, "silent", this.silent, "method", "latest")>
		<cfset static_("ColdIgniter\Events\Events").trigger("migrate", data)>

		<cfreturn true>
	</cffunction>

	<!---
	 * Migrate down to a previous batch
	 *
	 * Calls each migration step required to get to the provided batch
	 *
	 * @param targetBatch Target batch number, or negative for a relative batch, 0 for all
	 * @param group       Deprecated. The designation has no effect.
	 *
	 * @return bool True on success, FALSE on failure or no migrations are found
	 *
	 * @throws ConfigException
	 * @throws RuntimeException
	--->
	<cffunction name="regress" access="public" returntype="boolean" output="no">
		<cfargument name="targetBatch" type="numeric" required="no" default="0">
		<cfargument name="group" type="string" required="no" default="">
		<cfset var result = false>

		<cfif NOT this.enabled>
			<cfset static_("ColdIgniter\Exceptions\ConfigException").forDisabledMigrations()>
		</cfif>

		<cfset ensureTable()>

		<!--- Try to acquire lock - exit gracefully if another process is running migrations --->
		<cfif this.lock AND NOT acquireMigrationLock()>
			<cfset ArrayAppend(this.cliMessages, Chr(9) & lang("Migrations.locked"))>

			<cfreturn true>
		</cfif>

		<cftry>
			<cfset result = runRegress(arguments.targetBatch)>

			<cfcatch type="any">
				<cfif this.lock>
					<cfset releaseMigrationLock()>
				</cfif>

				<cfrethrow>
			</cfcatch>
		</cftry>

		<cfif this.lock>
			<cfset releaseMigrationLock()>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * Not in the original. The part of regress() that runs under the lock.
	--->
	<cffunction name="runRegress" access="private" returntype="boolean" output="no">
		<cfargument name="targetBatch" type="numeric" required="yes">
		<cfset var target = arguments.targetBatch>
		<cfset var batches = getBatches()>
		<cfset var batch = 0>
		<cfset var position = 0>
		<cfset var message = "">
		<cfset var tmpNamespace = "">
		<cfset var allMigrations = "">
		<cfset var migrations = ArrayNew(1)>
		<cfset var history = "">
		<cfset var uid = "">
		<cfset var migration = "">
		<cfset var data = "">
		<cfset var i = 0>

		<cfif target LT 0>
			<!--- the original reads $batches[count - 1 + $target] ?? 0 --->
			<cfset position = ArrayLen(batches) + target>

			<cfif position GTE 1 AND position LTE ArrayLen(batches)>
				<cfset target = batches[position]>
			<cfelse>
				<cfset target = 0>
			</cfif>
		</cfif>

		<cfif ArrayLen(batches) EQ 0 AND target EQ 0>
			<cfreturn true>
		</cfif>

		<cfif target NEQ 0 AND NOT in_array(target, batches)>
			<cfset message = lang("Migrations.batchNotFound") & target>

			<cfif this.silent>
				<cfset ArrayAppend(this.cliMessages, Chr(9) & message)>

				<cfreturn false>
			</cfif>

			<cfthrow type="ColdIgniter.RuntimeException" message="#message#">
		</cfif>

		<cfset tmpNamespace = this.namespace>

		<cfset this.namespace = "">
		<cfset allMigrations = findMigrations()>

		<cfloop condition="ArrayLen(batches) GT 0">
			<cfset batch = batches[ArrayLen(batches)]>
			<cfset ArrayDeleteAt(batches, ArrayLen(batches))>

			<cfif batch LTE target>
				<cfbreak>
			</cfif>

			<cfset history = getBatchHistory(batch, "desc")>

			<cfloop from="1" to="#ArrayLen(history)#" index="i">
				<cfset uid = getObjectUid(history[i])>

				<cfif NOT StructKeyExists(allMigrations, uid)>
					<cfset message = lang("Migrations.gap") & " " & history[i]["version"]>

					<cfif this.silent>
						<cfset ArrayAppend(this.cliMessages, Chr(9) & message)>

						<cfreturn false>
					</cfif>

					<cfthrow type="ColdIgniter.RuntimeException" message="#message#">
				</cfif>

				<cfset migration = allMigrations[uid]>
				<cfset migration["history"] = history[i]>
				<cfset ArrayAppend(migrations, migration)>
			</cfloop>
		</cfloop>

		<cfloop from="1" to="#ArrayLen(migrations)#" index="i">
			<cfif migrate("down", migrations[i])>
				<cfset removeHistory(migrations[i]["history"])>
			<cfelse>
				<cfset message = lang("Migrations.generalFault")>

				<cfif this.silent>
					<cfset ArrayAppend(this.cliMessages, Chr(9) & message)>

					<cfreturn false>
				</cfif>

				<cfthrow type="ColdIgniter.RuntimeException" message="#message#">
			</cfif>
		</cfloop>

		<cfset data = array_("enabled", this.enabled, "table", this.table, "namespace", this.namespace, "group", this.group, "name", this.name, "silent", this.silent, "method", "regress")>
		<cfset static_("ColdIgniter\Events\Events").trigger("migrate", data)>

		<cfset this.namespace = tmpNamespace>

		<cfreturn true>
	</cffunction>

	<!---
	 * Migrate a single file regardless of order or batches.
	 * Method "up" or "down" determined by presence in history.
	 * NOTE: This is not recommended and provided mostly for testing.
	 *
	 * @param path      Full path to a valid migration file
	 * @param namespace Namespace of the target migration
	 *
	 * @return bool
	--->
	<cffunction name="force" access="public" returntype="boolean" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfargument name="namespace" type="string" required="yes">
		<cfargument name="group" type="string" required="no" default="">
		<cfset var result = false>

		<cfif NOT this.enabled>
			<cfset static_("ColdIgniter\Exceptions\ConfigException").forDisabledMigrations()>
		</cfif>

		<cfset ensureTable()>

		<!--- Try to acquire lock - exit gracefully if another process is running migrations --->
		<cfif this.lock AND NOT acquireMigrationLock()>
			<cfset ArrayAppend(this.cliMessages, Chr(9) & lang("Migrations.locked"))>

			<cfreturn true>
		</cfif>

		<cftry>
			<cfset result = runForce(arguments.path, arguments.namespace, arguments.group)>

			<cfcatch type="any">
				<cfif this.lock>
					<cfset releaseMigrationLock()>
				</cfif>

				<cfrethrow>
			</cfcatch>
		</cftry>

		<cfif this.lock>
			<cfset releaseMigrationLock()>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * Not in the original. The part of force() that runs under the lock.
	--->
	<cffunction name="runForce" access="private" returntype="boolean" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfargument name="namespace" type="string" required="yes">
		<cfargument name="group" type="string" required="yes">
		<cfset var migration = "">
		<cfset var method = "up">
		<cfset var history = "">
		<cfset var batch = 0>
		<cfset var message = "">
		<cfset var i = 0>

		<cfif Compare(arguments.group, "") NEQ 0>
			<cfset this.groupFilter = arguments.group>
			<cfset setGroup(arguments.group)>
		</cfif>

		<cfset migration = migrationFromFile(arguments.path, arguments.namespace)>

		<cfif NOT IsStruct(migration)>
			<cfset message = lang("Migrations.notFound")>

			<cfif this.silent>
				<cfset ArrayAppend(this.cliMessages, Chr(9) & message)>

				<cfreturn false>
			</cfif>

			<cfthrow type="ColdIgniter.RuntimeException" message="#message#">
		</cfif>

		<cfset setNamespace(migration["namespace"])>

		<cfset history = getHistory(this.group)>

		<cfloop from="1" to="#ArrayLen(history)#" index="i">
			<cfif Compare(getObjectUid(history[i]), migration["uid"]) EQ 0>
				<cfset method = "down">
				<cfset migration["history"] = history[i]>
				<cfbreak>
			</cfif>
		</cfloop>

		<cfif Compare(method, "up") EQ 0>
			<cfset batch = getLastBatch() + 1>

			<cfif migrate("up", migration) AND NOT this.groupSkip>
				<cfset addHistory(migration, batch)>

				<cfreturn true>
			</cfif>

			<cfset this.groupSkip = false>
		<cfelseif migrate("down", migration)>
			<cfset removeHistory(migration["history"])>

			<cfreturn true>
		</cfif>

		<cfset message = lang("Migrations.generalFault")>

		<cfif this.silent>
			<cfset ArrayAppend(this.cliMessages, Chr(9) & message)>

			<cfreturn false>
		</cfif>

		<cfthrow type="ColdIgniter.RuntimeException" message="#message#">
	</cffunction>

	<!---
	 * Retrieves list of available migration scripts
	 *
	 * @return array<string, array> List of all located migrations by their UID,
	 *                              a map (see array_()) in the order of the UID
	--->
	<cffunction name="findMigrations" access="public" returntype="any" output="no">
		<cfset var namespaces = ArrayNew(1)>
		<cfset var found = "">
		<cfset var migrations = array_()>
		<cfset var sorted = array_()>
		<cfset var uids = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<cfif Compare(this.namespace, "") NEQ 0>
			<cfset ArrayAppend(namespaces, this.namespace)>
		<cfelse>
			<cfset namespaces = array_keys(request.ColdIgniter.autoloader.getNamespace())>
		</cfif>

		<cfloop from="1" to="#ArrayLen(namespaces)#" index="i">
			<cfif NOT (Compare(request.ENVIRONMENT, "testing") NEQ 0 AND Compare(namespaces[i], "Tests\Support") EQ 0)>
				<cfset found = findNamespaceMigrations(namespaces[i])>

				<cfloop from="1" to="#ArrayLen(found)#" index="j">
					<cfset migrations[found[j]["uid"]] = found[j]>
				</cfloop>
			</cfif>
		</cfloop>

		<!--- Sort migrations ascending by their UID (version) --->
		<cfset uids = array_keys(migrations)>
		<cfset ArraySort(uids, "text", "asc")>

		<cfloop from="1" to="#ArrayLen(uids)#" index="i">
			<cfset sorted[uids[i]] = migrations[uids[i]]>
		</cfloop>

		<cfreturn sorted>
	</cffunction>

	<!---
	 * Retrieves a list of available migration scripts for one namespace
	 *
	 * Difference: the original asks the file locator for the files of the
	 * folder Database/Migrations of the namespace (the locator is not
	 * ported). Here that folder is read in each folder of the namespace.
	 *
	 * @return list<array> A list of maps (see array_())
	--->
	<cffunction name="findNamespaceMigrations" access="public" returntype="array" output="no">
		<cfargument name="namespace" type="string" required="yes">
		<cfset var migrations = ArrayNew(1)>
		<cfset var directories = request.ColdIgniter.autoloader.getNamespace(arguments.namespace)>
		<cfset var directory = "">
		<cfset var files = "">
		<cfset var migration = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(directories)#" index="i">
			<cfset directory = REReplace(directories[i], "[\\/]+$", "") & request.DIRECTORY_SEPARATOR & "Database" & request.DIRECTORY_SEPARATOR & "Migrations">

			<cfif CreateObject("java", "java.io.File").init(directory).isDirectory()>
				<!--- cfdirectory has no recurse here, and the folder is flat --->
				<cfdirectory action="list" directory="#directory#" name="files" filter="*.cfc">

				<cfloop query="files">
					<cfif Compare(files.type, "File") EQ 0>
						<cfset migration = migrationFromFile(directory & request.DIRECTORY_SEPARATOR & files.name, arguments.namespace)>

						<cfif IsStruct(migration)>
							<cfset ArrayAppend(migrations, migration)>
						</cfif>
					</cfif>
				</cfloop>
			</cfif>
		</cfloop>

		<cfreturn migrations>
	</cffunction>

	<!---
	 * Create a migration object from a file path.
	 *
	 * Difference: the class is the namespace, Database\Migrations and the
	 * file name, as the file locator is not ported to read it from the file.
	 *
	 * @param path Full path to a valid migration file.
	 *
	 * @return A map (see array_()), or false on failure
	--->
	<cffunction name="migrationFromFile" access="private" returntype="any" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfargument name="namespace" type="string" required="yes">
		<cfset var filename = "">
		<cfset var migration = "">

		<cfif Compare(LCase(Right(arguments.path, 4)), ".cfc") NEQ 0>
			<cfreturn false>
		</cfif>

		<cfset filename = basename(arguments.path, ".cfc")>

		<cfif REFind(this.regex, filename) EQ 0>
			<cfreturn false>
		</cfif>

		<cfset migration = array_()>

		<cfset migration["version"] = getMigrationNumber(filename)>
		<cfset migration["name"] = getMigrationName(filename)>
		<cfset migration["path"] = arguments.path>
		<cfset migration["class"] = arguments.namespace & "\Database\Migrations\" & filename>
		<cfset migration["namespace"] = arguments.namespace>
		<cfset migration["uid"] = getObjectUid(migration)>

		<cfreturn migration>
	</cffunction>

	<!---
	 * Allows other scripts to modify on the fly as needed.
	 *
	 * @param namespace An empty string is all namespaces (null)
	 *
	 * @return MigrationRunner
	--->
	<cffunction name="setNamespace" access="public" returntype="any" output="no">
		<cfargument name="namespace" type="string" required="yes">

		<cfset this.namespace = arguments.namespace>

		<cfreturn this>
	</cffunction>

	<!---
	 * Allows other scripts to modify on the fly as needed.
	 *
	 * @return MigrationRunner
	--->
	<cffunction name="setGroup" access="public" returntype="any" output="no">
		<cfargument name="group" type="string" required="yes">

		<cfset this.group = arguments.group>

		<cfreturn this>
	</cffunction>

	<!---
	 * @return MigrationRunner
	--->
	<cffunction name="setName" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfset this.name = arguments.name>

		<cfreturn this>
	</cffunction>

	<!---
	 * If $silent == true, then will not throw exceptions and will
	 * attempt to continue gracefully.
	 *
	 * @return MigrationRunner
	--->
	<cffunction name="setSilent" access="public" returntype="any" output="no">
		<cfargument name="silent" type="boolean" required="yes">

		<cfset this.silent = arguments.silent>

		<cfreturn this>
	</cffunction>

	<!---
	 * Extracts the migration number from a filename
	 *
	 * @param migration A migration filename w/o path.
	--->
	<cffunction name="getMigrationNumber" access="private" returntype="string" output="no">
		<cfargument name="migration" type="string" required="yes">

		<cfif REFind(this.regex, arguments.migration) NEQ 0>
			<cfreturn Mid(arguments.migration, 2, 14)>
		</cfif>

		<cfreturn "0">
	</cffunction>

	<!---
	 * Extracts the migration name from a filename
	 *
	 * Note: The migration name should be the classname, but maybe they are
	 *       different.
	 *
	 * @param migration A migration filename w/o path.
	--->
	<cffunction name="getMigrationName" access="private" returntype="string" output="no">
		<cfargument name="migration" type="string" required="yes">

		<cfif REFind(this.regex, arguments.migration) NEQ 0>
			<cfreturn Mid(arguments.migration, 17, Len(arguments.migration))>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * Uses the non-repeatable portions of a migration or history
	 * to create a sortable unique key
	 *
	 * @param object migration or $history, a map (see array_())
	--->
	<cffunction name="getObjectUid" access="public" returntype="string" output="no">
		<cfargument name="object" type="any" required="yes">

		<cfreturn REReplace(arguments.object["version"], "[^0-9]", "", "all") & arguments.object["class"]>
	</cffunction>

	<!---
	 * Retrieves messages formatted for CLI output
	 *
	 * @return list<string>
	--->
	<cffunction name="getCliMessages" access="public" returntype="array" output="no">

		<cfreturn this.cliMessages>
	</cffunction>

	<!---
	 * Clears any CLI messages.
	 *
	 * @return MigrationRunner
	--->
	<cffunction name="clearCliMessages" access="public" returntype="any" output="no">

		<cfset this.cliMessages = ArrayNew(1)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Truncates the history table.
	 *
	 * @return void
	--->
	<cffunction name="clearHistory" access="public" returntype="void" output="no">

		<cfif this.db.tableExists(this.table)>
			<cfset this.db.table(this.table).truncate()>
		</cfif>
	</cffunction>

	<!---
	 * Add a history to the table.
	 *
	 * @param migration A map (see array_())
	 *
	 * @return void
	--->
	<cffunction name="addHistory" access="private" returntype="void" output="no">
		<cfargument name="migration" type="any" required="yes">
		<cfargument name="batch" type="numeric" required="yes">
		<cfset var row = array_("version", arguments.migration["version"], "class", arguments.migration["class"], "group", this.group, "namespace", arguments.migration["namespace"], "time", JavaCast("int", time()), "batch", JavaCast("int", arguments.batch))>

		<cfset this.db.table(this.table).insert_(row)>
	</cffunction>

	<!---
	 * Removes a single history
	 *
	 * @param history A map (see array_())
	 *
	 * @return void
	--->
	<cffunction name="removeHistory" access="private" returntype="void" output="no">
		<cfargument name="history" type="any" required="yes">

		<cfset this.db.table(this.table).where("id", arguments.history["id"]).delete()>
	</cffunction>

	<!---
	 * Grabs the full migration history from the database for a group
	 *
	 * @return list<array> A list of maps (see array_())
	--->
	<cffunction name="getHistory" access="public" returntype="array" output="no">
		<cfargument name="group" type="string" required="no" default="default">
		<cfset var builder = "">
		<cfset var query = "">

		<cfset ensureTable()>

		<cfset builder = this.db.table(this.table)>

		<!--- If group was specified then use it --->
		<cfif Compare(arguments.group, "") NEQ 0>
			<cfset builder.where("group", arguments.group)>
		</cfif>

		<!--- If a namespace was specified then use it --->
		<cfif Compare(this.namespace, "") NEQ 0>
			<cfset builder.where("namespace", this.namespace)>
		</cfif>

		<cfset query = builder.orderBy("id", "ASC").get()>

		<cfif NOT IsObject(query)>
			<cfreturn ArrayNew(1)>
		</cfif>

		<cfreturn query.getResultObject()>
	</cffunction>

	<!---
	 * Returns the migration history for a single batch.
	 *
	 * @param order
	 *
	 * @return list<array> A list of maps (see array_())
	--->
	<cffunction name="getBatchHistory" access="public" returntype="array" output="no">
		<cfargument name="batch" type="numeric" required="yes">
		<cfargument name="order" type="string" required="no" default="asc">
		<cfset var query = "">

		<cfset ensureTable()>

		<cfset query = this.db.table(this.table).where("batch", JavaCast("int", arguments.batch)).orderBy("id", arguments.order).get()>

		<cfif NOT IsObject(query)>
			<cfreturn ArrayNew(1)>
		</cfif>

		<cfreturn query.getResultObject()>
	</cffunction>

	<!---
	 * Returns all the batches from the database history in order
	 *
	 * @return list<int>
	--->
	<cffunction name="getBatches" access="public" returntype="array" output="no">
		<cfset var batches = ArrayNew(1)>
		<cfset var rows = "">
		<cfset var i = 0>

		<cfset ensureTable()>

		<cfset rows = this.db.table(this.table).select("batch").distinct().orderBy("batch", "asc").get().getResultArray()>

		<cfloop from="1" to="#ArrayLen(rows)#" index="i">
			<cfset ArrayAppend(batches, Int(Val(rows[i]["batch"])))>
		</cfloop>

		<cfreturn batches>
	</cffunction>

	<!---
	 * Returns the value of the last batch in the database.
	--->
	<cffunction name="getLastBatch" access="public" returntype="numeric" output="no">
		<cfset var batch = "">

		<cfset ensureTable()>

		<cfset batch = this.db.table(this.table).selectMax("batch").get().getResultObject()>

		<cfif ArrayLen(batch) GT 0>
			<cfreturn Int(Val(batch[ArrayLen(batch)]["batch"]))>
		</cfif>

		<cfreturn 0>
	</cffunction>

	<!---
	 * Returns the version number of the first migration for a batch.
	 * Mostly just for tests.
	--->
	<cffunction name="getBatchStart" access="public" returntype="string" output="no">
		<cfargument name="batch" type="numeric" required="yes">
		<cfset var batch_ = arguments.batch>
		<cfset var batches = "">
		<cfset var migration = "">

		<cfif batch_ LT 0>
			<cfset batches = getBatches()>

			<cfif ArrayLen(batches) GT 0>
				<cfset batch_ = batches[ArrayLen(batches)]>
			<cfelse>
				<cfset batch_ = 0>
			</cfif>
		</cfif>

		<cfset migration = this.db.table(this.table).where("batch", JavaCast("int", batch_)).orderBy("id", "asc").limit(JavaCast("int", 1)).get().getResultObject()>

		<cfif ArrayLen(migration) GT 0>
			<cfreturn migration[1]["version"]>
		</cfif>

		<cfreturn "0">
	</cffunction>

	<!---
	 * Returns the version number of the last migration for a batch.
	 * Mostly just for tests.
	--->
	<cffunction name="getBatchEnd" access="public" returntype="string" output="no">
		<cfargument name="batch" type="numeric" required="yes">
		<cfset var batch_ = arguments.batch>
		<cfset var batches = "">
		<cfset var migration = "">

		<cfif batch_ LT 0>
			<cfset batches = getBatches()>

			<cfif ArrayLen(batches) GT 0>
				<cfset batch_ = batches[ArrayLen(batches)]>
			<cfelse>
				<cfset batch_ = 0>
			</cfif>
		</cfif>

		<cfset migration = this.db.table(this.table).where("batch", JavaCast("int", batch_)).orderBy("id", "desc").limit(JavaCast("int", 1)).get().getResultObject()>

		<cfif ArrayLen(migration) EQ 0>
			<cfreturn "0">
		</cfif>

		<cfreturn migration[1]["version"]>
	</cffunction>

	<!---
	 * Ensures that we have created our migrations table
	 * in the database.
	 *
	 * @return void
	--->
	<cffunction name="ensureTable" access="public" returntype="void" output="no">
		<cfset var forge = "">
		<cfset var fields = array_()>

		<cfif this.tableChecked OR this.db.tableExists(this.table)>
			<cfreturn>
		</cfif>

		<cfset forge = static_("ColdIgniter\Database\Config").forge(this.db)>

		<cfset fields["id"] = array_("type", "BIGINT", "constraint", 20, "unsigned", true, "auto_increment", true)>
		<cfset fields["version"] = array_("type", "VARCHAR", "constraint", 255, "null", false)>
		<cfset fields["class"] = array_("type", "VARCHAR", "constraint", 255, "null", false)>
		<cfset fields["group"] = array_("type", "VARCHAR", "constraint", 255, "null", false)>
		<cfset fields["namespace"] = array_("type", "VARCHAR", "constraint", 255, "null", false)>
		<cfset fields["time"] = array_("type", "INT", "constraint", 11, "null", false)>
		<cfset fields["batch"] = array_("type", "INT", "constraint", 11, "unsigned", true, "null", false)>

		<cfset forge.addField(fields)>

		<cfset forge.addPrimaryKey("id")>
		<cfset forge.createTable(this.table, true)>

		<cfset this.tableChecked = true>
	</cffunction>

	<!---
	 * Ensures that we have created our migration
	 * lock table in the database.
	 *
	 * @return string The lock table name
	--->
	<cffunction name="ensureLockTable" access="private" returntype="string" output="no">
		<cfset var lockTable = this.table & "_lock">
		<cfset var forge = "">
		<cfset var fields = array_()>

		<cfif this.lockTableChecked OR this.db.tableExists(lockTable)>
			<cfset this.lockTableChecked = true>

			<cfreturn lockTable>
		</cfif>

		<cfset forge = static_("ColdIgniter\Database\Config").forge(this.db)>

		<cfset fields["id"] = array_("type", "BIGINT", "auto_increment", true)>
		<cfset fields["lock_name"] = array_("type", "VARCHAR", "constraint", 255, "null", false, "unique", true)>
		<cfset fields["acquired_at"] = array_("type", "INTEGER", "null", false)>

		<cfset forge.addField(fields)>

		<cfset forge.addPrimaryKey("id")>
		<cfset forge.createTable(lockTable, true)>

		<cfset this.lockTableChecked = true>

		<cfreturn lockTable>
	</cffunction>

	<!---
	 * Acquire exclusive lock on migrations to prevent concurrent execution
	 *
	 * @return bool True if lock was acquired, false if another process holds the lock
	--->
	<cffunction name="acquireMigrationLock" access="private" returntype="boolean" output="no">
		<cfset var lockTable = ensureLockTable()>
		<cfset var row = array_("lock_name", "migration_process", "acquired_at", JavaCast("int", time()))>
		<cfset var acquired = false>
		<cfset var insertResult = "">

		<cftry>
			<cfset insertResult = this.db.table(lockTable).insert_(row)>

			<!--- Difference: with DBDebug off a failed insert returns false instead of throwing, and insertID() can be stale, so the result is checked too --->
			<cfset acquired = NOT identical_(insertResult, "false") AND Val(this.db.insertID()) GT 0>

			<!--- Lock already exists or other error --->
			<cfcatch type="ColdIgniter.Database.Exceptions.DatabaseException">
				<cfset acquired = false>
			</cfcatch>
		</cftry>

		<cfreturn acquired>
	</cffunction>

	<!---
	 * Release migration lock
	 *
	 * @return bool True if successfully released, false on error
	--->
	<cffunction name="releaseMigrationLock" access="private" returntype="boolean" output="no">
		<cfset var lockTable = ensureLockTable()>
		<cfset var result = this.db.table(lockTable).where("lock_name", "migration_process").delete()>

		<cfif identical_(result, "false")>
			<cfset log_message("warning", "Failed to release migration lock")>

			<cfreturn false>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!---
	 * Handles the actual running of a migration.
	 *
	 * Difference: the original includes the file; here the class is
	 * created by the autoloader, which finds the file by the class name.
	 *
	 * @param direction "up" or "down"
	 * @param migration The migration to run, a map (see array_())
	--->
	<cffunction name="migrate" access="private" returntype="boolean" output="no">
		<cfargument name="direction" type="string" required="yes">
		<cfargument name="migration" type="any" required="yes">
		<cfset var class = arguments.migration["class"]>
		<cfset var message = "">
		<cfset var instance = "">
		<cfset var group = "">

		<cfset setName(arguments.migration["name"])>

		<!--- Validate the migration file structure --->
		<cfif NOT class_exists(class)>
			<cfset message = Replace(lang("Migrations.classNotFound"), "%s", class)>

			<cfif this.silent>
				<cfset ArrayAppend(this.cliMessages, Chr(9) & message)>

				<cfreturn false>
			</cfif>

			<cfthrow type="ColdIgniter.RuntimeException" message="#message#">
		</cfif>

		<cfset instance = new_(class, static_("ColdIgniter\Database\Config").forge(this.db))>
		<cfset group = instance.getDBGroup()>

		<cfif Compare(group, "") EQ 0>
			<cfset group = this.group>
		</cfif>

		<cfif Compare(request.ENVIRONMENT, "testing") NEQ 0 AND Compare(group, "tests") EQ 0 AND Compare(this.groupFilter, "tests") NEQ 0>
			<cfset this.groupSkip = true>

			<cfreturn true>
		</cfif>

		<cfif Compare(arguments.direction, "up") EQ 0 AND Compare(this.groupFilter, "") NEQ 0 AND Compare(this.groupFilter, group) NEQ 0>
			<cfset this.groupSkip = true>

			<cfreturn true>
		</cfif>

		<cfif NOT method_exists(instance, arguments.direction)>
			<cfset message = Replace(lang("Migrations.missingMethod"), "%s", arguments.direction)>

			<cfif this.silent>
				<cfset ArrayAppend(this.cliMessages, Chr(9) & message)>

				<cfreturn false>
			</cfif>

			<cfthrow type="ColdIgniter.RuntimeException" message="#message#">
		</cfif>

		<cfset Evaluate("instance.#arguments.direction#()")>

		<cfreturn true>
	</cffunction>

</cfcomponent>
