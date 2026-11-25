<!---
 * Class Seeder
 *
 * Difference: a seeder is a component in the folder Database/Seeds of the
 * app, and its class is App\Database\Seeds\<Name>; a seeder name with a
 * backslash is taken as the full class name, as in the original.
 *
 * Not ported yet: faker() (Faker is not ported) and the "Seeded:" line the
 * original writes to the command line.
--->
<cfcomponent output="no" hint="Class Seeder">

	<!---
	 * The name of the database group to use.
	 *
	 * @var string
	--->
	<cfset this.DBGroup = "">

	<!---
	 * Where we can find the Seed files.
	 *
	 * @var string
	--->
	<cfset this.seedPath = "">

	<!---
	 * An instance of the main Database configuration
	 *
	 * @var Database
	--->
	<cfset this.config = "">

	<!---
	 * Database Connection instance
	 *
	 * @var BaseConnection
	--->
	<cfset this.db = "">

	<!---
	 * Database Forge instance.
	 *
	 * @var Forge
	--->
	<cfset this.forge = "">

	<!---
	 * If true, will not display CLI messages.
	 *
	 * @var bool
	--->
	<cfset this.silent = false>

	<!---
	 * Seeder constructor.
	 *
	 * @param config The Config\Database
	 * @param db     A connection, an empty string is the null of the original
	 *
	 * @throws InvalidArgumentException
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfargument name="db" type="any" required="no" default="">
		<cfset var path = "">

		<cfset this.seedPath = REReplace(arguments.config.filesPath, "[\\/]+$", "") & "/Seeds/">

		<cfif Compare(Trim(arguments.config.filesPath), "") EQ 0>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Invalid filesPath set in the Config\Database.">
		</cfif>

		<cfset path = REReplace(this.seedPath, "[\\/]+$", "")>

		<cfif NOT CreateObject("java", "java.io.File").init(path).isDirectory()>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Unable to locate the seeds directory. Please check Config\Database::filesPath">
		</cfif>

		<cfset this.config = arguments.config>

		<cfif Compare(this.DBGroup, "") NEQ 0>
			<cfset this.db = static_("ColdIgniter\Database\Config").connect(this.DBGroup)>
		<cfelseif IsObject(arguments.db)>
			<cfset this.db = arguments.db>
		<cfelse>
			<cfset this.db = static_("ColdIgniter\Database\Config").connect()>
		</cfif>

		<cfset this.forge = static_("ColdIgniter\Database\Config").forge(this.db)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Gets the Config\Database instance.
	--->
	<cffunction name="getConfig" access="public" returntype="any" output="no">

		<cfreturn this.config>
	</cffunction>

	<!---
	 * Sets the location of the directory that seed files can be located in.
	 *
	 * @return Seeder
	--->
	<cffunction name="setPath" access="public" returntype="any" output="no">
		<cfargument name="path" type="string" required="yes">

		<cfset this.seedPath = REReplace(arguments.path, "[\\/]+$", "") & "/">

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the silent treatment.
	 *
	 * @return Seeder
	--->
	<cffunction name="setSilent" access="public" returntype="any" output="no">
		<cfargument name="silent" type="boolean" required="yes">

		<cfset this.silent = arguments.silent>

		<cfreturn this>
	</cffunction>

	<!---
	 * Loads the specified seeder and runs it.
	 *
	 * @throws InvalidArgumentException
	--->
	<cffunction name="call" access="public" returntype="void" output="no">
		<cfargument name="class" type="string" required="yes">
		<cfset var class_ = Trim(arguments.class)>
		<cfset var seeder = "">

		<cfif Compare(class_, "") EQ 0>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="No seeder was specified.">
		</cfif>

		<cfif Find("\", class_) EQ 0>
			<cfif NOT CreateObject("java", "java.io.File").init(this.seedPath & class_ & ".cfc").isFile()>
				<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="The specified seeder is not a valid file: #this.seedPath##class_#.cfc">
			</cfif>

			<cfset class_ = request.APP_NAMESPACE & "\Database\Seeds\" & class_>
		</cfif>

		<!--- Difference: the original includes the file; here the class has to be found by the autoloader --->
		<cfif NOT class_exists(class_)>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="The specified seeder is not a valid file: #class_#">
		</cfif>

		<cfset seeder = new_(class_, this.config, this.db)>
		<cfset seeder.setSilent(this.silent)>
		<cfset seeder.run()>
	</cffunction>

	<!---
	 * Child classes must implement this method and take care
	 * of inserting their data here.
	 *
	 * @return mixed
	 *
	 * @throws Exception
	--->
	<cffunction name="run" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The seeder has to implement run().">
	</cffunction>

</cfcomponent>
