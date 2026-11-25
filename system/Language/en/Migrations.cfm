<!---
 * Migrations language settings
 *
 * A language file is included by the Language component, and has to
 * set the variable "lines" to a map (see array_()); that stands in for
 * the "return [...]" of the original. The keys keep their order.
 *
 * The lines for the command line (Migration Command, Migrate Status) are
 * kept as they are; there is no command line here.
--->
<cfset lines = array_()>

<!--- Migration Runner --->
<cfset lines["missingTable"] = "Migrations table must be set.">
<cfset lines["disabled"] = "Migrations have been loaded but are disabled or setup incorrectly.">
<cfset lines["notFound"] = "Migration file not found: ">
<cfset lines["batchNotFound"] = "Target batch not found: ">
<cfset lines["empty"] = "No Migration files found">
<cfset lines["gap"] = "There is a gap in the migration sequence near version number: ">
<cfset lines["classNotFound"] = "The migration class ""%s"" could not be found.">
<cfset lines["missingMethod"] = "The migration class is missing an ""%s"" method.">
<cfset lines["locked"] = "Migrations already running in another process. Skipping.">

<!--- Migration Command --->
<cfset lines["migHelpLatest"] = Chr(9) & Chr(9) & "Migrates database to latest available migration.">
<cfset lines["migHelpCurrent"] = Chr(9) & Chr(9) & "Migrates database to version set as 'current' in configuration.">
<cfset lines["migHelpVersion"] = Chr(9) & "Migrates database to version {v}.">
<cfset lines["migHelpRollback"] = Chr(9) & "Runs all migrations 'down' to version 0.">
<cfset lines["migHelpRefresh"] = Chr(9) & Chr(9) & "Uninstalls and re-runs all migrations to freshen database.">
<cfset lines["migHelpSeed"] = Chr(9) & "Runs the seeder named [name].">
<cfset lines["migCreate"] = Chr(9) & "Creates a new migration named [name]">
<cfset lines["nameMigration"] = "Name the migration file">
<cfset lines["migNumberError"] = "Migration number must be three digits, and there must not be any gaps in the sequence.">
<cfset lines["rollBackConfirm"] = "Are you sure you want to rollback?">
<cfset lines["refreshConfirm"] = "Are you sure you want to refresh?">

<cfset lines["latest"] = "Running all new migrations...">
<cfset lines["generalFault"] = "Migration failed!">
<cfset lines["migrated"] = "Migrations complete.">
<cfset lines["migInvalidVersion"] = "Invalid version number provided.">
<cfset lines["toVersionPH"] = "Migrating to version %s...">
<cfset lines["toVersion"] = "Migrating to current version...">
<cfset lines["rollingBack"] = "Rolling back migrations to batch: ">
<cfset lines["noneFound"] = "No migrations were found.">
<cfset lines["migSeeder"] = "Seeder name">
<cfset lines["migMissingSeeder"] = "You must provide a seeder name.">
<cfset lines["nameSeeder"] = "Name the seeder file">
<cfset lines["removed"] = "Rolling back: ">
<cfset lines["added"] = "Running: ">

<!--- Migrate Status --->
<cfset lines["namespace"] = "Namespace">
<cfset lines["filename"] = "Filename">
<cfset lines["version"] = "Version">
<cfset lines["group"] = "Group">
<cfset lines["on"] = "Migrated On: ">
<cfset lines["batch"] = "Batch">
