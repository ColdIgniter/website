<!---
 * Validation configuration.
 *
 * Not ported yet: CreditCardRules (it is left out of the rule sets below).
 *
 * Difference: a rule group is a map (see array_()) of fields, and a group of
 * messages is a map of maps. Write them in the body of the component with
 * CreateObject("java", "java.util.LinkedHashMap").init(), or in the
 * constructor with array_(), which is not known in the body.
--->
<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="Validation configuration">

	<!---
	 * --------------------------------------------------------------------
	 * Setup
	 * --------------------------------------------------------------------
	 *
	 * Stores the classes that contain the rules that are available.
	 *
	 * @var list<string>
	--->
	<cfset this.ruleSets = ArrayNew(1)>
	<cfset ArrayAppend(this.ruleSets, "ColdIgniter\Validation\StrictRules\Rules")>
	<cfset ArrayAppend(this.ruleSets, "ColdIgniter\Validation\StrictRules\FormatRules")>
	<cfset ArrayAppend(this.ruleSets, "ColdIgniter\Validation\StrictRules\FileRules")>

	<!---
	 * Specifies the views that contain the validation errors, by the name
	 * that listErrors() and showError() are given.
	 *
	 * @var array<string, string>
	--->
	<cfset this.templates = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.templates["list"] = "ColdIgniter\Validation\Views\list">
	<cfset this.templates["single"] = "ColdIgniter\Validation\Views\single">

	<!---
	 * --------------------------------------------------------------------
	 * Rules
	 * --------------------------------------------------------------------
	--->

</cfcomponent>
