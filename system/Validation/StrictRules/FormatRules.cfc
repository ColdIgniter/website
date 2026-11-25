<!---
 * Strict format validation Rules.
 *
 * Not ported yet: valid_json (see FormatRules).
 *
 * Difference: there is no type of a value, so a number and its text are the
 * same. Every rule gives false for a value that is a list or a map, and
 * passes the other values on. The original also gives false for an int where
 * a rule wants a string (alpha, alpha_space, ...).
 *
 * Difference: this component cannot extend or reach the one in the folder
 * above, so it creates it and calls it, as the original does.
--->
<cfcomponent output="no" hint="Strict format validation Rules">

	<!--- the non strict rules --->
	<cfset this.nonStrictFormatRules = "">

	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfset this.nonStrictFormatRules = new_("ColdIgniter\Validation\FormatRules")>

		<cfreturn this>
	</cffunction>

	<cffunction name="alpha" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.alpha(arguments.str)>
	</cffunction>

	<cffunction name="alpha_space" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.alpha_space(arguments.str)>
	</cffunction>

	<cffunction name="alpha_dash" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.alpha_dash(arguments.str)>
	</cffunction>

	<cffunction name="alpha_numeric_punct" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.alpha_numeric_punct(arguments.str)>
	</cffunction>

	<cffunction name="alpha_numeric" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.alpha_numeric(arguments.str)>
	</cffunction>

	<cffunction name="alpha_numeric_space" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.alpha_numeric_space(arguments.str)>
	</cffunction>

	<cffunction name="string" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.string(arguments.str)>
	</cffunction>

	<cffunction name="decimal" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.decimal(arguments.str)>
	</cffunction>

	<cffunction name="hex" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.hex(arguments.str)>
	</cffunction>

	<cffunction name="integer" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.integer(arguments.str)>
	</cffunction>

	<cffunction name="is_natural" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.is_natural(arguments.str)>
	</cffunction>

	<cffunction name="is_natural_no_zero" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.is_natural_no_zero(arguments.str)>
	</cffunction>

	<cffunction name="numeric" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.numeric(arguments.str)>
	</cffunction>

	<cffunction name="regex_match" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">
		<cfargument name="pattern" type="string" required="yes">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.regex_match(arguments.str, arguments.pattern)>
	</cffunction>

	<cffunction name="timezone" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.timezone(arguments.str)>
	</cffunction>

	<cffunction name="valid_base64" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.valid_base64(arguments.str)>
	</cffunction>

	<cffunction name="valid_email" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.valid_email(arguments.str)>
	</cffunction>

	<cffunction name="valid_emails" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.valid_emails(arguments.str)>
	</cffunction>

	<cffunction name="valid_ip" access="public" returntype="boolean" output="no">
		<cfargument name="ip" type="any" required="no" default="">
		<cfargument name="which" type="string" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.ip)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.valid_ip(arguments.ip, arguments.which)>
	</cffunction>

	<cffunction name="valid_url" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.valid_url(arguments.str)>
	</cffunction>

	<cffunction name="valid_url_strict" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">
		<cfargument name="validSchemes" type="string" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.valid_url_strict(arguments.str, arguments.validSchemes)>
	</cffunction>

	<cffunction name="valid_date" access="public" returntype="boolean" output="no">
		<cfargument name="str" type="any" required="no" default="">
		<cfargument name="format" type="string" required="no" default="">

		<cfif NOT IsSimpleValue(arguments.str)>
			<cfreturn false>
		</cfif>

		<cfreturn this.nonStrictFormatRules.valid_date(arguments.str, arguments.format)>
	</cffunction>

</cfcomponent>
