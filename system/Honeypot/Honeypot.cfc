<!---
 * class Honeypot
--->
<cfcomponent output="no" hint="Honeypot">

	<!---
	 * Our configuration.
	--->
	<cfset this.config = "">

	<!---
	 * The container, with {template} in it.
	--->
	<cfset this.container = "">

	<!---
	 * Constructor.
	 *
	 * Difference: the container is kept in the object, not written back
	 * to the config.
	 *
	 * @param config The Config\Honeypot
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">

		<cfset this.config = arguments.config>
		<cfset this.container = this.config.container>

		<cfif this.container EQ "" OR NOT Find("{template}", this.container)>
			<cfset this.container = "<div style=""display:none"">{template}</div>">
		</cfif>

		<cfif this.config.template EQ "">
			<cfset static_("ColdIgniter\Honeypot\Exceptions\HoneypotException").forNoTemplate()>
		</cfif>

		<cfif this.config.name EQ "">
			<cfset static_("ColdIgniter\Honeypot\Exceptions\HoneypotException").forNoNameField()>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Checks the request if honeypot field has data.
	 *
	 * Difference: a post value is posted as text, so only an empty string,
	 * "0" and an empty array count as no content.
	--->
	<cffunction name="hasContent" access="public" returntype="boolean" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfset var value = arguments.request_.getPost(this.config.name)>

		<cfif IsArray(value)>
			<cfreturn ArrayLen(value) GT 0>
		</cfif>

		<cfif IsSimpleValue(value)>
			<cfreturn Compare(value, "") NEQ 0 AND Compare(value, "0") NEQ 0>
		</cfif>

		<cfreturn NOT StructIsEmpty(value)>
	</cffunction>

	<!---
	 * Attaches Honeypot template to response.
	--->
	<cffunction name="attachHoneypot" access="public" returntype="void" output="no">
		<cfargument name="response" type="any" required="yes">
		<cfset var bodyBefore = arguments.response.getBody()>
		<cfset var prepField = "">
		<cfset var bodyAfter = "">
		<cfset var cspOn = "">
		<cfset var style = "">

		<cfif is_null(bodyBefore)>
			<cfreturn>
		</cfif>

		<!---
		 Difference: the config is looked at first, so that the policy object
		 is not made for a request when the policy is off.
		--->
		<cfset cspOn = false>
		<cfif config("Config\App").CSPEnabled>
			<cfset cspOn = arguments.response.getCSP().enabled()>
		</cfif>

		<cfif cspOn>
			<!--- Add id attribute to the container tag. --->
			<cfset this.container = ReplaceNoCase(this.container, ">{template}", " id=""" & this.config.containerId & """>{template}", "ALL")>
		</cfif>

		<cfset prepField = prepareTemplate(this.config.template)>

		<!--- ReplaceNoCase scans the body once, with no backtracking --->
		<cfset bodyAfter = ReplaceNoCase(bodyBefore, "</form>", prepField & "</form>", "ALL")>

		<cfif cspOn AND Compare(bodyBefore, bodyAfter) NEQ 0>
			<!--- Add style tag for the container tag in the head tag. --->
			<cfset style = "<style " & csp_style_nonce() & ">##" & this.config.containerId & " { display:none }</style>">
			<cfset bodyAfter = ReplaceNoCase(bodyAfter, "</head>", style & "</head>", "ALL")>
		</cfif>

		<cfset arguments.response.setBody(bodyAfter)>
	</cffunction>

	<!---
	 * Prepares the template by adding label
	 * content and field name.
	--->
	<cffunction name="prepareTemplate" access="private" returntype="string" output="no">
		<cfargument name="template" type="string" required="yes">

		<cfset arguments.template = ReplaceNoCase(arguments.template, "{label}", this.config.label, "ALL")>
		<cfset arguments.template = ReplaceNoCase(arguments.template, "{name}", this.config.name, "ALL")>

		<cfif this.config.hidden>
			<cfreturn ReplaceNoCase(this.container, "{template}", arguments.template, "ALL")>
		</cfif>

		<cfreturn arguments.template>
	</cffunction>

</cfcomponent>
