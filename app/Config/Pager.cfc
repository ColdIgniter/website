<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="Pager configuration">

	<!---
	 * --------------------------------------------------------------------------
	 * Templates
	 * --------------------------------------------------------------------------
	 *
	 * Pagination links are rendered out using views to configure their
	 * appearance. This array contains aliases and the view names to
	 * use when rendering the links.
	 *
	 * Within each view, the Pager object will be available as pager,
	 * and the desired group as pagerGroup;
	 *
	 * @var array<string, string>
	--->
	<cfset this.templates = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.templates["default_full"] = "ColdIgniter\Pager\Views\default_full">
	<cfset this.templates["default_simple"] = "ColdIgniter\Pager\Views\default_simple">
	<cfset this.templates["default_head"] = "ColdIgniter\Pager\Views\default_head">

	<!---
	 * --------------------------------------------------------------------------
	 * Items Per Page
	 * --------------------------------------------------------------------------
	 *
	 * The default number of results shown in a single page.
	--->
	<cfset this.perPage = 20>

</cfcomponent>
