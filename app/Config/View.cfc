<cfcomponent output="no" parent="ColdIgniter\Config\View">

	<!---
	 * When false, the view method will clear the data between each
	 * call. This keeps your data safe and ensures there is no accidental
	 * leaking between calls, so you would need to explicitly pass the data
	 * to each view. You might prefer to have the data stick around between
	 * calls so that it is available to all views. If that is the case,
	 * set $saveData to true.
	--->
	<cfset this.saveData = true>

	<!---
	 * Parser Filters map a filter name with any callable. When the
	 * Parser prepares a variable for display, it will chain it
	 * through the filters in the order defined, inserting any parameters.
	 * To prevent potential abuse, all filters MUST be defined here
	 * in order for them to be available for use within the Parser.
	 *
	 * Examples:
	 *  { title|esc(js) }
	 *  { created_on|date(Y-m-d)|esc(attr) }
	--->
	<cfset this.filters = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Parser Plugins provide a way to extend the functionality provided
	 * by the core Parser by creating aliases that will be replaced with
	 * any callable. Can be single or tag pair.
	--->
	<cfset this.plugins = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * When true, Parser conditionals may only contain variables, literals,
	 * arithmetic, comparison and logical operators, and parentheses. Enable
	 * this when less-trusted users can edit Parser templates. Can be overridden per
	 * call with the `restrictConditionals` render option.
	--->
	<cfset this.restrictParserConditionals = false>

	<!---
	 * View Decorators are class methods that will be run in sequence to
	 * have a chance to alter the generated output just prior to caching
	 * the results.
	 *
	 * All classes must implement ColdIgniter\View\ViewDecoratorInterface
	--->
	<cfset this.decorators = ArrayNew(1)>

	<!---
	 * Subdirectory within app/Views for namespaced view overrides.
	 *
	 * Namespaced views will be searched in:
	 *
	 *   app/Views/{$appOverridesFolder}/{Namespace}/{view_path}.{cfm|html...}
	 *
	 * This allows application-level overrides for package or module views
	 * without modifying vendor source files.
	 *
	 * Examples:
	 *   'overrides' -> app/Views/overrides/Example/Blog/post/card.cfm
	 *   'vendor'    -> app/Views/vendor/Example/Blog/post/card.cfm
	 *   ''          -> app/Views/Example/Blog/post/card.cfm (direct mapping)
	--->
	<cfset this.appOverridesFolder = "overrides">

</cfcomponent>
