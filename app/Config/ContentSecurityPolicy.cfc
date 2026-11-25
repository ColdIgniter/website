<!---
 * Stores the default settings for the ContentSecurityPolicy, if you
 * choose to use it. The values here will be read in and set as defaults
 * for the site. If needed, they can be overridden on a page-by-page basis.
 *
 * Suggested reference for explanations:
 *
 * @see https://www.html5rocks.com/en/tutorials/security/content-security-policy/
 *
 * Difference: a directive is a string, a list (ArrayNew(1)) of strings, or an
 * empty list for null. The null of the original is an empty list here, as an
 * empty string is a value: a directive that is an empty string is sent
 * without sources (for example `sandbox`). The settings reportURI and
 * reportTo are an empty string when they are null.
--->
<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="Content Security Policy configuration">

	<!---
	 * -------------------------------------------------------------------------
	 * Broadbrush CSP management
	 * -------------------------------------------------------------------------
	 *
	 * Default CSP report context
	--->
	<cfset this.reportOnly = false>

	<!---
	 * Specifies a URL where a browser will send reports
	 * when a content security policy is violated.
	--->
	<cfset this.reportURI = "">

	<!---
	 * Specifies a reporting endpoint to which violation reports ought to be sent.
	--->
	<cfset this.reportTo = "">

	<!---
	 * Instructs user agents to rewrite URL schemes, changing
	 * HTTP to HTTPS. This directive is for websites with
	 * large numbers of old URLs that need to be rewritten.
	--->
	<cfset this.upgradeInsecureRequests = false>

	<!---
	 * -------------------------------------------------------------------------
	 * CSP DIRECTIVES SETTINGS
	 * NOTE: once you set a policy to 'none', it cannot be further restricted
	 * -------------------------------------------------------------------------
	 *
	 * Will default to `'self'` if not overridden
	 *
	 * @var list<string>|string
	--->
	<cfset this.defaultSrc = ArrayNew(1)>

	<!---
	 * Lists allowed scripts' URLs.
	 *
	 * @var list<string>|string
	--->
	<cfset this.scriptSrc = "self">

	<!---
	 * Specifies valid sources for JavaScript <script> elements.
	 *
	 * @var list<string>|string
	--->
	<cfset this.scriptSrcElem = "self">

	<!---
	 * Specifies valid sources for JavaScript inline event
	 * handlers and JavaScript URLs.
	 *
	 * @var list<string>|string
	--->
	<cfset this.scriptSrcAttr = "self">

	<!---
	 * Lists allowed stylesheets' URLs.
	 *
	 * @var list<string>|string
	--->
	<cfset this.styleSrc = "self">

	<!---
	 * Specifies valid sources for stylesheets <link> elements.
	 *
	 * @var list<string>|string
	--->
	<cfset this.styleSrcElem = "self">

	<!---
	 * Specifies valid sources for stylesheets inline
	 * style attributes and `<style>` elements.
	 *
	 * @var list<string>|string
	--->
	<cfset this.styleSrcAttr = "self">

	<!---
	 * Defines the origins from which images can be loaded.
	 *
	 * @var list<string>|string
	--->
	<cfset this.imageSrc = "self">

	<!---
	 * Restricts the URLs that can appear in a page's `<base>` element.
	 *
	 * Will default to self if not overridden
	 *
	 * @var list<string>|string
	--->
	<cfset this.baseURI = ArrayNew(1)>

	<!---
	 * Lists the URLs for workers and embedded frame contents
	 *
	 * @var list<string>|string
	--->
	<cfset this.childSrc = "self">

	<!---
	 * Limits the origins that you can connect to (via XHR,
	 * WebSockets, and EventSource).
	 *
	 * @var list<string>|string
	--->
	<cfset this.connectSrc = "self">

	<!---
	 * Specifies the origins that can serve web fonts.
	 *
	 * @var list<string>|string
	--->
	<cfset this.fontSrc = ArrayNew(1)>

	<!---
	 * Lists valid endpoints for submission from `<form>` tags.
	 *
	 * @var list<string>|string
	--->
	<cfset this.formAction = "self">

	<!---
	 * Specifies the sources that can embed the current page.
	 * This directive applies to `<frame>`, `<iframe>`, `<embed>`,
	 * and `<applet>` tags. This directive can't be used in
	 * `<meta>` tags and applies only to non-HTML resources.
	 *
	 * @var list<string>|string
	--->
	<cfset this.frameAncestors = ArrayNew(1)>

	<!---
	 * The frame-src directive restricts the URLs which may
	 * be loaded into nested browsing contexts.
	 *
	 * @var list<string>|string
	--->
	<cfset this.frameSrc = ArrayNew(1)>

	<!---
	 * Restricts the origins allowed to deliver video and audio.
	 *
	 * @var list<string>|string
	--->
	<cfset this.mediaSrc = ArrayNew(1)>

	<!---
	 * Allows control over Flash and other plugins.
	 *
	 * @var list<string>|string
	--->
	<cfset this.objectSrc = "self">

	<!---
	 * @var list<string>|string
	--->
	<cfset this.manifestSrc = ArrayNew(1)>

	<!---
	 * @var list<string>|string
	--->
	<cfset this.workerSrc = ArrayNew(1)>

	<!---
	 * Limits the kinds of plugins a page may invoke.
	 *
	 * @var list<string>|string
	--->
	<cfset this.pluginTypes = ArrayNew(1)>

	<!---
	 * List of actions allowed.
	 *
	 * @var list<string>|string
	--->
	<cfset this.sandbox = ArrayNew(1)>

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

</cfcomponent>
