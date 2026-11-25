<!---
 * Refuses a subject that is too long for a regular expression whose
 * pattern is written by the developer.
 *
 * Difference: not in the original. The regular expressions of Java have no
 * time limit, and a pattern that backtracks takes time that grows with the
 * square or the cube of the subject, so one request can hold the processor
 * until the server is restarted. A subject longer than the limit is refused
 * before the match is tried. The limit is Config\App regexSubjectLimit
 * (8192 characters when the setting is not there). A pattern the framework
 * writes itself and has made linear does not call this.
 *
 * @param subject The text that the pattern is about to be run on
 *
 * @throws ColdIgniter.Exceptions.FrameworkException when the subject is longer than the limit
--->
<cffunction name="regex_guard_" returntype="void" output="no" hint="Refuses a subject that is too long for a developer pattern">
	<cfargument name="subject" type="string" required="yes">
	<cfset var limit = 8192>
	<cfset var factories = "">

	<!---
	 * The shared Config\App is read straight from where Factories keeps it,
	 * which is what Factories::get() returns once the object is there. This
	 * runs before every match, and the two function calls cost more than the
	 * match. Until the object is there the call is made as before. When
	 * Config\App cannot be loaded or has no regexSubjectLimit, both reads
	 * fail and the limit is 8192; app/Config/App.cfc sets the value, so
	 * that costs time only when the setting or Config\App is missing.
	--->
	<cftry>
		<cfset factories = request.ColdIgniter.statics["ColdIgniter\Config\Factories"]>
		<cfset limit = factories.instances["config"][factories.aliases["config"]["Config\App"]].regexSubjectLimit>

		<cfcatch type="any">
			<cftry>
				<cfset limit = static_("ColdIgniter\Config\Factories").get("config", "Config\App").regexSubjectLimit>

				<cfcatch type="any">
					<cfset limit = 8192>
				</cfcatch>
			</cftry>
		</cfcatch>
	</cftry>

	<cfif Len(arguments.subject) GT limit>
		<cfthrow type="ColdIgniter.Exceptions.FrameworkException" errorcode="500" message="The text is #Len(arguments.subject)# characters long, more than the #limit# that a regular expression is run on (see regexSubjectLimit in Config\App).">
	</cfif>
</cffunction>
