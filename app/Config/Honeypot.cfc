<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="Honeypot configuration">

	<!---
	 * Makes Honeypot visible or not to human
	--->
	<cfset this.hidden = true>

	<!---
	 * Honeypot Label Content
	--->
	<cfset this.label = "Fill This Field">

	<!---
	 * Honeypot Field Name
	--->
	<cfset this.name = "honeypot">

	<!---
	 * Honeypot HTML Template
	--->
	<cfset this.template = "<label>{label}</label><input type=""text"" name=""{name}"" value="""">">

	<!---
	 * Honeypot container
	 *
	 * If you enabled CSP, you can remove `style="display:none"`.
	--->
	<cfset this.container = "<div style=""display:none"">{template}</div>">

	<!---
	 * The id attribute for Honeypot container tag
	 *
	 * Used when CSP is enabled.
	--->
	<cfset this.containerId = "hpc">

</cfcomponent>
