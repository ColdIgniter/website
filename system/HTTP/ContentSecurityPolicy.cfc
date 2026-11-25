<!---
 * Provides tools for working with the Content-Security-Policy header
 * to help defeat XSS attacks.
 *
 * @see http://www.html5rocks.com/en/tutorials/security/content-security-policy/
 * @see http://content-security-policy.com/
 *
 * Difference: a source list (the value of a directive) is, as in the
 * original, a string, an empty list (ArrayNew(1), for null and for []) or a
 * map (java.util.LinkedHashMap) of the source to the reporting flag. The flag
 * is an empty string (null), 1 (report only) or 0 (enforce). A list given
 * by the config is turned into a map when it has items. The maps are only
 * made when a source is added, as CreateObject() is costly.
 *
 * Difference: the properties reportOnly and upgradeInsecureRequests have a
 * trailing underscore (reportOnly_, upgradeInsecureRequests_), as the
 * methods of the same names exist. The properties reportURI and reportTo are
 * an empty string when they are null. The names of the directives and of the
 * properties are two lists (directiveNames and directiveProps) in place of
 * a map, and validSources is a comma separated list.
 *
 * Difference: the nonce placeholders are replaced by Find() and Replace(),
 * which are linear, in place of a regular expression with a callback. The
 * nonce is only made when its placeholder is in the body, as in the original.
 *
 * Difference: a nonce is 12 bytes of java.security.SecureRandom (see
 * random_bytes()), as base64 text.
 *
 * Difference: the reporting endpoints are a map made on the first
 * addReportingEndpoints(), and the headers that are built are lists of the
 * finished text of each directive.
--->
<cfcomponent output="no" hint="Provides tools for working with the Content-Security-Policy header">

	<!---
	 * The names of the directives, in the order of the header, and the names
	 * of the properties of them, in the same order. The first 21 take a list
	 * of sources.
	--->
	<cfset this.directiveNames = "base-uri,child-src,connect-src,default-src,font-src,form-action,frame-ancestors,frame-src,img-src,media-src,object-src,plugin-types,script-src,style-src,sandbox,manifest-src,script-src-elem,script-src-attr,style-src-elem,style-src-attr,worker-src,report-uri,report-to">
	<cfset this.directiveProps = "baseURI,childSrc,connectSrc,defaultSrc,fontSrc,formAction,frameAncestors,frameSrc,imageSrc,mediaSrc,objectSrc,pluginTypes,scriptSrc,styleSrc,sandbox,manifestSrc,scriptSrcElem,scriptSrcAttr,styleSrcElem,styleSrcAttr,workerSrc,reportURI,reportTo">
	<cfset this.sourceListCount = 21>

	<!---
	 * Used for security enhancements to restrict the domains that browsers
	 * allow to be loaded as base-uri and so on, from a source list.
	--->
	<cfset this.baseURI = ArrayNew(1)>
	<cfset this.childSrc = ArrayNew(1)>
	<cfset this.connectSrc = ArrayNew(1)>
	<cfset this.defaultSrc = ArrayNew(1)>
	<cfset this.fontSrc = ArrayNew(1)>
	<cfset this.formAction = ArrayNew(1)>
	<cfset this.frameAncestors = ArrayNew(1)>
	<cfset this.frameSrc = ArrayNew(1)>
	<cfset this.imageSrc = ArrayNew(1)>
	<cfset this.mediaSrc = ArrayNew(1)>
	<cfset this.objectSrc = ArrayNew(1)>
	<cfset this.pluginTypes = ArrayNew(1)>
	<cfset this.scriptSrc = ArrayNew(1)>
	<cfset this.styleSrc = ArrayNew(1)>
	<cfset this.sandbox = ArrayNew(1)>

	<!---
	 * Used for security enhancements to restrict the URI that the browser
	 * sends reports to. An empty string is null.
	--->
	<cfset this.reportURI = "">

	<!---
	 * The reporting endpoint that report-to names. An empty string is null.
	--->
	<cfset this.reportTo = "">

	<!---
	 * CSP Level 3 Directives
	--->
	<cfset this.manifestSrc = ArrayNew(1)>
	<cfset this.scriptSrcElem = ArrayNew(1)>
	<cfset this.scriptSrcAttr = ArrayNew(1)>
	<cfset this.styleSrcElem = ArrayNew(1)>
	<cfset this.styleSrcAttr = ArrayNew(1)>
	<cfset this.workerSrc = ArrayNew(1)>

	<!---
	 * Instructs user agents to treat all of a site's insecure URLs
	 * as though they have been replaced with secure URLs.
	--->
	<cfset this.upgradeInsecureRequests_ = false>

	<!---
	 * Set to true to make all policies report only.
	--->
	<cfset this.reportOnly_ = false>

	<!---
	 * Used for security enhancements: the keywords of a source list that
	 * go in single quotes, as a comma separated list.
	--->
	<cfset this.validSources = "self,none,unsafe-inline,unsafe-eval,strict-dynamic,unsafe-hashes,report-sample,unsafe-allow-redirects,wasm-unsafe-eval,trusted-types-eval,report-sha256,report-sha384,report-sha512">

	<!---
	 * Nonce for style tags, and for script tags. An empty string is null.
	--->
	<cfset this.styleNonce = "">
	<cfset this.scriptNonce = "">

	<!---
	 * Nonce placeholder for style tags.
	--->
	<cfset this.styleNonceTag = "{csp-style-nonce}">

	<!---
	 * Nonce placeholder for script tags.
	--->
	<cfset this.scriptNonceTag = "{csp-script-nonce}">

	<!---
	 * Replace nonce tag automatically?
	--->
	<cfset this.autoNonce = true>

	<!---
	 * The text of each directive that is built, for the header of the
	 * policy and for the header of the report only policy.
	--->
	<cfset this.tempHeaders = ArrayNew(1)>
	<cfset this.reportOnlyHeaders = ArrayNew(1)>

	<!---
	 * Whether the CSP is enabled (Config\App).
	--->
	<cfset this.CSPEnabled = false>

	<!---
	 * An array of header Reporting-Endpoints (name to URL): an empty string
	 * until an endpoint is added, then a map.
	--->
	<cfset this.reportingEndpoints = "">

	<!---
	 * Constructor.
	 *
	 * Stores our default values from the Config\ContentSecurityPolicy.
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfset var settings = "reportOnly,upgradeInsecureRequests,styleNonceTag,scriptNonceTag,autoNonce,reportURI,reportTo">
		<cfset var setting = "">
		<cfset var value = "">
		<cfset var i = 0>

		<cfset this.CSPEnabled = variables.config("Config\App").CSPEnabled>

		<!--- the settings that are not a directive with a source list --->
		<cfloop list="#settings#" index="setting">
			<cfif StructKeyExists(arguments.config, setting)>
				<cfif setting EQ "reportOnly" OR setting EQ "upgradeInsecureRequests">
					<cfset this[setting & "_"] = arguments.config[setting]>
				<cfelse>
					<cfset this[setting] = arguments.config[setting]>
				</cfif>
			</cfif>
		</cfloop>

		<cfloop from="1" to="#this.sourceListCount#" index="i">
			<cfset setting = ListGetAt(this.directiveProps, i)>

			<cfif StructKeyExists(arguments.config, setting)>
				<cfset value = arguments.config[setting]>

				<!---
				 Config sets these directives as list<string>|string
				 but we need them as a map internally.
				--->
				<cfif IsArray(value) AND ArrayLen(value) GT 0>
					<cfset this[setting] = listToMap_(value)>
				<cfelse>
					<cfset this[setting] = value>
				</cfif>
			</cfif>
		</cfloop>

		<cfif IsSimpleValue(this.styleSrc)>
			<cfset this.styleSrc = stringToMap_(this.styleSrc)>
		</cfif>

		<cfif IsSimpleValue(this.scriptSrc)>
			<cfset this.scriptSrc = stringToMap_(this.scriptSrc)>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Whether Content Security Policy is being enforced.
	--->
	<cffunction name="enabled" access="public" returntype="boolean" output="no">
		<cfreturn this.CSPEnabled>
	</cffunction>

	<!---
	 * Get the nonce for the style tag.
	--->
	<cffunction name="getStyleNonce" access="public" returntype="string" output="no">
		<cfif this.styleNonce EQ "">
			<cfset this.styleNonce = ToBase64(random_bytes(12))>
			<cfset addStyleSrc("nonce-" & this.styleNonce)>

			<cfif NOT isEmptyList_(this.styleSrcElem)>
				<cfset addStyleSrcElem("nonce-" & this.styleNonce)>
			</cfif>
		</cfif>

		<cfreturn this.styleNonce>
	</cffunction>

	<!---
	 * Get the nonce for the script tag.
	--->
	<cffunction name="getScriptNonce" access="public" returntype="string" output="no">
		<cfif this.scriptNonce EQ "">
			<cfset this.scriptNonce = ToBase64(random_bytes(12))>
			<cfset addScriptSrc("nonce-" & this.scriptNonce)>

			<cfif NOT isEmptyList_(this.scriptSrcElem)>
				<cfset addScriptSrcElem("nonce-" & this.scriptNonce)>
			</cfif>
		</cfif>

		<cfreturn this.scriptNonce>
	</cffunction>

	<!---
	 * Compiles and sets the appropriate headers in the request.
	 *
	 * Should be called just prior to sending the response to the user agent.
	--->
	<cffunction name="finalize" access="public" returntype="void" output="no">
		<cfargument name="response" type="any" required="yes">

		<cfset generateNonces(arguments.response)>
		<cfset buildHeaders(arguments.response)>
	</cffunction>

	<!---
	 * If TRUE, nothing will be restricted. Instead all violations will
	 * be reported to the reportURI for monitoring. This is useful when
	 * you are just starting to implement the policy, and will help
	 * determine what errors need to be addressed before you turn on
	 * all filtering.
	 *
	 * Violations are reported to the reportURI.
	 *
	 * @param value
	 *
	 * @return $this
	--->
	<cffunction name="reportOnly" access="public" returntype="any" output="no">
		<cfargument name="value" type="boolean" required="no" default="true">

		<cfset this.reportOnly_ = arguments.value>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new base_uri value. Can be either a URI or a quoted source.
	 *
	 * @param uri               a string, or a list of them
	 * @param explicitReporting whether to report or enforce; an empty string (null) uses reportOnly
	--->
	<cffunction name="addBaseURI" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "baseURI", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new valid endpoint for child frames and frames and workers.
	--->
	<cffunction name="addChildSrc" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "childSrc", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new valid endpoint for a form's action.
	--->
	<cffunction name="addConnectSrc" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "connectSrc", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new valid endpoint for a form's action.
	--->
	<cffunction name="addDefaultSrc" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "defaultSrc", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Set the default source, replacing the ones that were set.
	--->
	<cffunction name="setDefaultSrc" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset this.defaultSrc = ArrayNew(1)>
		<cfset addDefaultSrc(arguments.uri, arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new valid endpoint for fonts if unsafe-inline is used.
	--->
	<cffunction name="addFontSrc" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "fontSrc", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new valid endpoint for a form's action.
	--->
	<cffunction name="addFormAction" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "formAction", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new resource that should allow embedding the resource using
	 * <frame>, <iframe>, <object>, <embed>, or <applet>.
	--->
	<cffunction name="addFrameAncestor" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "frameAncestors", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new valid endpoint for valid frame sources.
	--->
	<cffunction name="addFrameSrc" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "frameSrc", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new valid endpoint for valid image sources.
	--->
	<cffunction name="addImageSrc" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "imageSrc", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new valid endpoint for valid video and audio.
	--->
	<cffunction name="addMediaSrc" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "mediaSrc", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new valid manifest source.
	--->
	<cffunction name="addManifestSrc" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "manifestSrc", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new valid endpoint for objects, embed and applets.
	--->
	<cffunction name="addObjectSrc" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "objectSrc", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Limits the types of plugins that can be used. Can be either
	 * a URI or a quoted source.
	--->
	<cffunction name="addPluginType" access="public" returntype="any" output="no">
		<cfargument name="mime" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.mime, "pluginTypes", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Specifies a sandbox policy for the page. The flags are a string or a
	 * list of them; an empty string sets the sandbox without a flag.
	--->
	<cffunction name="addSandbox" access="public" returntype="any" output="no">
		<cfargument name="flags" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.flags, "sandbox", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new valid endpoint for scripts.
	--->
	<cffunction name="addScriptSrc" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "scriptSrc", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new valid endpoint for script elements.
	--->
	<cffunction name="addScriptSrcElem" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "scriptSrcElem", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new valid endpoint for script attributes (inline event handlers).
	--->
	<cffunction name="addScriptSrcAttr" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "scriptSrcAttr", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new valid endpoint for stylesheets.
	--->
	<cffunction name="addStyleSrc" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "styleSrc", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new valid endpoint for style elements.
	--->
	<cffunction name="addStyleSrcElem" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "styleSrcElem", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new valid endpoint for style attributes.
	--->
	<cffunction name="addStyleSrcAttr" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "styleSrcAttr", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds a new valid endpoint for worker scripts.
	--->
	<cffunction name="addWorkerSrc" access="public" returntype="any" output="no">
		<cfargument name="uri" type="any" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">

		<cfset addOption(arguments.uri, "workerSrc", arguments.explicitReporting)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets whether the user agents should rewrite URL schemes, changing
	 * HTTP to HTTPS.
	--->
	<cffunction name="upgradeInsecureRequests" access="public" returntype="any" output="no">
		<cfargument name="value" type="boolean" required="no" default="true">

		<cfset this.upgradeInsecureRequests_ = arguments.value>

		<cfreturn this>
	</cffunction>

	<!---
	 * Specifies a URL where a browser will send reports when a content
	 * security policy is violated.
	--->
	<cffunction name="setReportURI" access="public" returntype="any" output="no">
		<cfargument name="uri" type="string" required="yes">

		<cfset this.reportURI = arguments.uri>

		<cfreturn this>
	</cffunction>

	<!---
	 * Specifies a reporting endpoint to which violation reports ought to be sent.
	 * An empty string removes the endpoint and the report URI.
	 *
	 * @throws InvalidArgumentException
	--->
	<cffunction name="setReportToEndpoint" access="public" returntype="any" output="no">
		<cfargument name="endpoint" type="string" required="yes">

		<cfif arguments.endpoint EQ "">
			<cfset this.reportURI = "">
			<cfset this.reportTo = "">

			<cfreturn this>
		</cfif>

		<cfif NOT IsStruct(this.reportingEndpoints) OR NOT this.reportingEndpoints.containsKey(JavaCast("string", arguments.endpoint))>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="The reporting endpoint ""#arguments.endpoint#"" has not been defined.">
		</cfif>

		<!--- for BC with browsers that do not support `report-to` --->
		<cfset this.reportURI = this.reportingEndpoints.get(JavaCast("string", arguments.endpoint))>
		<cfset this.reportTo = arguments.endpoint>

		<cfreturn this>
	</cffunction>

	<!---
	 * Adds reporting endpoints, a map of the name to the URL (see array_()).
	--->
	<cffunction name="addReportingEndpoints" access="public" returntype="any" output="no">
		<cfargument name="endpoint" type="any" required="yes">
		<cfset var names = arguments.endpoint.keySet().iterator()>
		<cfset var name = "">

		<cfif NOT IsStruct(this.reportingEndpoints)>
			<cfset this.reportingEndpoints = CreateObject("java", "java.util.LinkedHashMap").init()>
		</cfif>

		<cfloop condition="names.hasNext()">
			<cfset name = names.next()>
			<cfset this.reportingEndpoints.put(JavaCast("string", name), arguments.endpoint.get(name))>
		</cfloop>

		<cfreturn this>
	</cffunction>

	<!---
	 * Clears a directive.
	 *
	 * @param directive the name of the directive, such as `style-src`
	--->
	<cffunction name="clearDirective" access="public" returntype="void" output="no">
		<cfargument name="directive" type="string" required="yes">
		<cfset var position = ListFind(this.directiveNames, arguments.directive)>

		<cfif position EQ 0>
			<cfreturn>
		</cfif>

		<cfif arguments.directive EQ "report-uri">
			<cfset this.reportURI = "">

			<cfreturn>
		</cfif>

		<cfif arguments.directive EQ "report-to">
			<cfset this.reportURI = "">
			<cfset this.reportTo = "">

			<cfreturn>
		</cfif>

		<cfset this[ListGetAt(this.directiveProps, position)] = ArrayNew(1)>
	</cffunction>

	<!---
	 * DRY method to add an string or array to a class property.
	 *
	 * @param options           a string, or a list of them
	 * @param target            the name of the property
	 * @param explicitReporting whether to report or enforce; an empty string (null) uses reportOnly
	--->
	<cffunction name="addOption" access="private" returntype="void" output="no">
		<cfargument name="options" type="any" required="yes">
		<cfargument name="target" type="string" required="yes">
		<cfargument name="explicitReporting" type="any" required="no" default="">
		<cfset var flag = 0>
		<cfset var map = "">
		<cfset var list = "">
		<cfset var option = "">
		<cfset var i = 0>

		<cfif arguments.explicitReporting EQ "">
			<cfset arguments.explicitReporting = this.reportOnly_>
		</cfif>

		<cfif arguments.explicitReporting>
			<cfset flag = 1>
		</cfif>

		<!--- Ensure we have an array to work with... --->
		<cfif IsSimpleValue(this[arguments.target])>
			<cfset this[arguments.target] = parseSourceList(this[arguments.target])>
		<cfelseif NOT IsStruct(this[arguments.target])>
			<cfset this[arguments.target] = CreateObject("java", "java.util.LinkedHashMap").init()>
		</cfif>

		<cfset map = this[arguments.target]>

		<cfif IsArray(arguments.options)>
			<cfset list = arguments.options>
		<cfelse>
			<cfset list = ArrayNew(1)>
			<cfset ArrayAppend(list, arguments.options)>
		</cfif>

		<cfloop from="1" to="#ArrayLen(list)#" index="i">
			<cfset option = list[i]>
			<cfset map.put(JavaCast("string", Trim(option & "")), flag)>
		</cfloop>
	</cffunction>

	<!---
	 * Creates a nonce for the style and script tags in the body, and puts
	 * it in place of their placeholders. When the policy is off the
	 * placeholders are removed.
	--->
	<cffunction name="generateNonces" access="private" returntype="void" output="no">
		<cfargument name="response" type="any" required="yes">
		<cfset var body = "">
		<cfset var changed = false>
		<cfset var jsonEscape = false>
		<cfset var attr = "">

		<cfif enabled() AND NOT this.autoNonce>
			<cfreturn>
		</cfif>

		<cfset body = arguments.response.getBody()>

		<cfif NOT IsSimpleValue(body) OR body EQ "">
			<cfreturn>
		</cfif>

		<!--- Replace style and script placeholders with nonces --->
		<cfif Len(this.styleNonceTag) GT 0 AND Find(this.styleNonceTag, body) GT 0>
			<cfset attr = "">

			<cfif enabled()>
				<cfset attr = nonceAttribute_(getStyleNonce(), arguments.response)>
			</cfif>

			<cfset body = Replace(body, this.styleNonceTag, attr, "all")>
			<cfset changed = true>
		</cfif>

		<cfif Len(this.scriptNonceTag) GT 0 AND Find(this.scriptNonceTag, body) GT 0>
			<cfset attr = "">

			<cfif enabled()>
				<cfset attr = nonceAttribute_(getScriptNonce(), arguments.response)>
			</cfif>

			<cfset body = Replace(body, this.scriptNonceTag, attr, "all")>
			<cfset changed = true>
		</cfif>

		<cfif changed>
			<cfset arguments.response.setBody(body)>
		</cfif>
	</cffunction>

	<!---
	 * The nonce="..." attribute. The quotes are escaped for a JSON
	 * response, to keep the body valid.
	--->
	<cffunction name="nonceAttribute_" access="private" returntype="string" output="no">
		<cfargument name="nonce" type="string" required="yes">
		<cfargument name="response" type="any" required="yes">
		<cfset var attr = 'nonce="' & arguments.nonce & '"'>

		<!--- Escape quotes for JSON responses to prevent corrupting the JSON body --->
		<cfif Find("json", arguments.response.getHeaderLine("Content-Type")) GT 0>
			<cfset attr = Replace(attr, '"', '\"', "all")>
		</cfif>

		<cfreturn attr>
	</cffunction>

	<!---
	 * Based on the current state of the elements, will add the appropriate
	 * Content-Security-Policy and Content-Security-Policy-Report-Only headers
	 * with their values to the response object.
	--->
	<cffunction name="buildHeaders" access="private" returntype="void" output="no">
		<cfargument name="response" type="any" required="yes">
		<cfset var i = 0>
		<cfset var name = "">
		<cfset var property = "">
		<cfset var endpoints = ArrayNew(1)>
		<cfset var names = "">
		<cfset var key = "">

		<cfif NOT enabled()>
			<cfreturn>
		</cfif>

		<!--- Ensure both are set --->
		<cfif isBlank_(this.baseURI)>
			<cfset this.baseURI = "self">
		</cfif>

		<cfif isBlank_(this.defaultSrc)>
			<cfset this.defaultSrc = "self">
		</cfif>

		<cfloop from="1" to="#ListLen(this.directiveNames)#" index="i">
			<cfset name = ListGetAt(this.directiveNames, i)>
			<cfset property = ListGetAt(this.directiveProps, i)>

			<cfif NOT (name EQ "report-uri" AND this.reportURI EQ "") AND NOT (name EQ "report-to" AND this.reportTo EQ "")>
				<cfset addToHeader(name, this[property])>
			</cfif>
		</cfloop>

		<!--- Compile each generated header value before appending it to the response. --->
		<cfif IsStruct(this.reportingEndpoints) AND NOT this.reportingEndpoints.isEmpty()>
			<cfset names = this.reportingEndpoints.keySet().iterator()>

			<cfloop condition="names.hasNext()">
				<cfset key = names.next()>
				<cfset ArrayAppend(endpoints, Trim(key & '="' & this.reportingEndpoints.get(key) & '"'))>
			</cfloop>

			<cfset arguments.response.appendHeader("Reporting-Endpoints", ArrayToList(endpoints, ", "))>
			<cfset this.reportingEndpoints = "">
		</cfif>

		<cfif ArrayLen(this.tempHeaders) GT 0>
			<cfif this.upgradeInsecureRequests_>
				<cfset ArrayAppend(this.tempHeaders, "upgrade-insecure-requests")>
			</cfif>

			<cfset arguments.response.appendHeader("Content-Security-Policy", ArrayToList(this.tempHeaders, "; "))>
			<cfset this.tempHeaders = ArrayNew(1)>
		</cfif>

		<cfif ArrayLen(this.reportOnlyHeaders) GT 0>
			<cfset arguments.response.appendHeader("Content-Security-Policy-Report-Only", ArrayToList(this.reportOnlyHeaders, "; "))>
			<cfset this.reportOnlyHeaders = ArrayNew(1)>
		</cfif>
	</cffunction>

	<!---
	 * Adds a directive and its sources to the text of the headers, for the
	 * header of the policy and for the header of the report only policy.
	 *
	 * @param name   the name of the directive
	 * @param values a string, an empty list or a map of the source to the flag
	--->
	<cffunction name="addToHeader" access="private" returntype="void" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="values" type="any" required="yes">
		<cfset var sources = ArrayNew(1)>
		<cfset var reportSources = ArrayNew(1)>
		<cfset var keys = "">
		<cfset var value = "">
		<cfset var flag = "">
		<cfset var reportOnly = false>

		<cfif IsArray(arguments.values)>
			<!--- an empty list is null: nothing to add --->
			<cfreturn>
		</cfif>

		<cfif IsSimpleValue(arguments.values)>
			<cfset arguments.values = parseSourceList(arguments.values)>
		</cfif>

		<cfset keys = arguments.values.keySet().iterator()>

		<cfloop condition="keys.hasNext()">
			<cfset value = keys.next() & "">
			<cfset flag = arguments.values.get(JavaCast("string", value)) & "">

			<cfif ListFind(this.validSources, value) GT 0
				OR Compare(Left(value, 6), "nonce-") EQ 0
				OR Compare(Left(value, 7), "sha256-") EQ 0
				OR Compare(Left(value, 7), "sha384-") EQ 0
				OR Compare(Left(value, 7), "sha512-") EQ 0>
				<cfset value = "'" & value & "'">
			</cfif>

			<cfif flag EQ "">
				<cfset reportOnly = this.reportOnly_>
			<cfelse>
				<cfset reportOnly = (Val(flag) NEQ 0)>
			</cfif>

			<cfif reportOnly>
				<cfset ArrayAppend(reportSources, value)>
			<cfelse>
				<cfset ArrayAppend(sources, value)>
			</cfif>
		</cfloop>

		<cfif ArrayLen(sources) GT 0>
			<cfif ArrayLen(sources) GT 1>
				<cfset sources = withoutEmpty_(sources)>
			</cfif>

			<cfset ArrayAppend(this.tempHeaders, Trim(arguments.name & " " & ArrayToList(sources, " ")))>
		</cfif>

		<cfif ArrayLen(reportSources) GT 0>
			<cfif ArrayLen(reportSources) GT 1>
				<cfset reportSources = withoutEmpty_(reportSources)>
			</cfif>

			<cfset ArrayAppend(this.reportOnlyHeaders, Trim(arguments.name & " " & ArrayToList(reportSources, " ")))>
		</cfif>
	</cffunction>

	<!---
	 * Splits a source list text on whitespace: a map of each source to a
	 * null flag. An empty text is the one empty source.
	--->
	<cffunction name="parseSourceList" access="private" returntype="any" output="no">
		<cfargument name="values" type="string" required="yes">
		<cfset var valueStr = Trim(arguments.values)>

		<cfif valueStr EQ "">
			<cfreturn stringToMap_("")>
		</cfif>

		<cfreturn listToMap_(ListToArray(REReplace(valueStr, "[[:space:]]+", " ", "all"), " "))>
	</cffunction>

	<!---
	 * A map (source to a null flag) of one source.
	--->
	<cffunction name="stringToMap_" access="private" returntype="any" output="no">
		<cfargument name="source" type="string" required="yes">
		<cfset var map = CreateObject("java", "java.util.LinkedHashMap").init()>

		<cfset map.put(JavaCast("string", arguments.source), "")>

		<cfreturn map>
	</cffunction>

	<!---
	 * A map (source to a null flag) of a list of sources (array_fill_keys).
	--->
	<cffunction name="listToMap_" access="private" returntype="any" output="no">
		<cfargument name="list" type="array" required="yes">
		<cfset var map = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(arguments.list)#" index="i">
			<cfset map.put(JavaCast("string", arguments.list[i] & ""), "")>
		</cfloop>

		<cfreturn map>
	</cffunction>

	<!---
	 * Whether a source list is [] (an empty list or map).
	--->
	<cffunction name="isEmptyList_" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfif IsArray(arguments.value)>
			<cfreturn ArrayLen(arguments.value) EQ 0>
		</cfif>

		<cfif IsStruct(arguments.value)>
			<cfreturn arguments.value.isEmpty()>
		</cfif>

		<cfreturn false>
	</cffunction>

	<!---
	 * Whether a source list is one of '', null and [].
	--->
	<cffunction name="isBlank_" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfif IsSimpleValue(arguments.value)>
			<cfreturn arguments.value EQ "">
		</cfif>

		<cfreturn isEmptyList_(arguments.value)>
	</cffunction>

	<!---
	 * The items of a list that are not an empty string.
	--->
	<cffunction name="withoutEmpty_" access="private" returntype="array" output="no">
		<cfargument name="list" type="array" required="yes">
		<cfset var result = ArrayNew(1)>
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(arguments.list)#" index="i">
			<cfif arguments.list[i] NEQ "">
				<cfset ArrayAppend(result, arguments.list[i])>
			</cfif>
		</cfloop>

		<cfreturn result>
	</cffunction>

</cfcomponent>
