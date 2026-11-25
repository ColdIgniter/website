<!---
 * Class Pager
 *
 * The Pager class provides semi-automatic pagination links and data
 * for the pages of a model or of any list.
 *
 * Difference: an array of the original is a map (see array_()) or a list.
 * A group is a map, and the groups are a map of those. Null is an empty
 * string (the "only" list is an empty string until only() is called).
 *
 * Difference: the original clones the URI of the request; clone_() of the
 * URI makes the copy here.
 *
 * Difference: the arguments page of getPageURI(), perPage of store() and
 * makeLinks() that the original types as nullable are untyped; an empty
 * string is null.
--->
<cfcomponent output="no" extends="PagerInterface" hint="Pagination links and data">

	<!---
	 * The group data.
	 *
	 * @var array<string, array>
	--->
	<cfset this.groups = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * URI segment for page if page number is a segment variable.
	 *
	 * @var array<string, int>
	--->
	<cfset this.segment = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Our configuration instance.
	 *
	 * @var Config\Pager
	--->
	<cfset this.config = "">

	<!---
	 * The view engine.
	 *
	 * @var RendererInterface
	--->
	<cfset this.view = "">

	<!---
	 * List of only permitted GET variables
	 *
	 * @var list<string>|null
	--->
	<cfset this.only = "">

	<!---
	 * Constructor.
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="config" type="any" required="yes">
		<cfargument name="view" type="any" required="yes">

		<cfset this.config = arguments.config>
		<cfset this.view = arguments.view>

		<cfreturn this>
	</cffunction>

	<!---
	 * Handles creating and displaying the
	 * pagination links and data.
	 *
	 * @param template The output template alias to render.
	--->
	<cffunction name="links" access="public" returntype="string" output="no">
		<cfargument name="group" type="string" required="no" default="default">
		<cfargument name="template" type="string" required="no" default="default_full">

		<cfset ensureGroup(arguments.group)>

		<cfreturn displayLinks(arguments.group, arguments.template)>
	</cffunction>

	<!---
	 * Creates simple Next/Previous links, instead of full pagination.
	--->
	<cffunction name="simpleLinks" access="public" returntype="string" output="no">
		<cfargument name="group" type="string" required="no" default="default">
		<cfargument name="template" type="string" required="no" default="default_simple">

		<cfset ensureGroup(arguments.group)>

		<cfreturn displayLinks(arguments.group, arguments.template)>
	</cffunction>

	<!---
	 * Allows for a simple, manual, form of pagination where all of the data
	 * is provided by the user. The URL is the current URI.
	 *
	 * @param template The output template alias to render.
	 * @param segment  (whether page number is provided by URI segment)
	--->
	<cffunction name="makeLinks" access="public" returntype="string" output="no">
		<cfargument name="page" type="any" required="yes">
		<cfargument name="perPage" type="any" required="no" default="">
		<cfargument name="total" type="any" required="yes">
		<cfargument name="template" type="string" required="no" default="default_full">
		<cfargument name="segment" type="numeric" required="no" default="0">
		<cfargument name="group" type="string" required="no" default="default">

		<cfif arguments.group EQ "">
			<cfset arguments.group = "default">
		</cfif>

		<cfif is_null(arguments.perPage)>
			<cfset arguments.perPage = this.config.perPage>
		</cfif>

		<cfset store(arguments.group, arguments.page, arguments.perPage, arguments.total, arguments.segment)>

		<cfreturn displayLinks(arguments.group, arguments.template)>
	</cffunction>

	<!---
	 * Does the actual work of displaying the view file. Used internally
	 * by links(), simpleLinks(), and makeLinks().
	--->
	<cffunction name="displayLinks" access="private" returntype="string" output="no">
		<cfargument name="group" type="string" required="yes">
		<cfargument name="template" type="string" required="yes">
		<cfset var pager = "">

		<cfif NOT array_key_exists(arguments.template, this.config.templates)>
			<cfset static_("ColdIgniter\Pager\Exceptions\PagerException").forInvalidTemplate(arguments.template)>
		</cfif>

		<cfset pager = new_("ColdIgniter\Pager\PagerRenderer", getDetails(arguments.group))>

		<cfreturn this.view.setVar("pager", pager).render(this.config.templates[arguments.template])>
	</cffunction>

	<!---
	 * Stores a set of pagination data for later display. Most commonly used
	 * by the model to automate the process.
	 *
	 * @param perPage The number of items per page, an empty string for the default
	 *
	 * @return Pager
	--->
	<cffunction name="store" access="public" returntype="any" output="no">
		<cfargument name="group" type="string" required="yes">
		<cfargument name="page" type="any" required="yes">
		<cfargument name="perPage" type="any" required="no" default="">
		<cfargument name="total" type="any" required="yes">
		<cfargument name="segment" type="numeric" required="no" default="0">
		<cfset var pageCount = 0>
		<cfset var details = "">

		<cfif arguments.segment NEQ 0>
			<cfset setSegment(arguments.segment, arguments.group)>
		</cfif>

		<cfset ensureGroup(arguments.group, arguments.perPage)>
		<cfset details = this.groups[arguments.group]>

		<cfif arguments.segment GT 0 AND details["currentPage"] GT 0>
			<cfset arguments.page = details["currentPage"]>
		</cfif>

		<cfif is_null(arguments.perPage)>
			<cfset arguments.perPage = this.config.perPage>
		</cfif>

		<cfset pageCount = Ceiling(arguments.total / arguments.perPage)>

		<cfif arguments.page GT pageCount>
			<cfset details["currentPage"] = pageCount>
		<cfelse>
			<cfset details["currentPage"] = arguments.page>
		</cfif>

		<cfset details["perPage"] = arguments.perPage>
		<cfset details["total"] = arguments.total>
		<cfset details["pageCount"] = pageCount>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets segment for a group.
	 *
	 * @return Pager
	--->
	<cffunction name="setSegment" access="public" returntype="any" output="no">
		<cfargument name="number" type="numeric" required="yes">
		<cfargument name="group" type="string" required="no" default="default">

		<cfset this.segment[arguments.group] = arguments.number>

		<!--- Recalculate current page --->
		<cfset ensureGroup(arguments.group)>
		<cfset calculateCurrentPage(arguments.group)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the path that an aliased group of links will use.
	 *
	 * @return Pager
	--->
	<cffunction name="setPath" access="public" returntype="any" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfargument name="group" type="string" required="no" default="default">

		<cfset ensureGroup(arguments.group)>

		<cfset this.groups[arguments.group]["uri"].setPath(arguments.path)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Returns the total number of items in a group.
	--->
	<cffunction name="getTotal" access="public" returntype="any" output="no">
		<cfargument name="group" type="string" required="no" default="default">

		<cfset ensureGroup(arguments.group)>

		<cfreturn this.groups[arguments.group]["total"]>
	</cffunction>

	<!---
	 * Returns the total number of pages.
	--->
	<cffunction name="getPageCount" access="public" returntype="numeric" output="no">
		<cfargument name="group" type="string" required="no" default="default">

		<cfset ensureGroup(arguments.group)>

		<cfreturn this.groups[arguments.group]["pageCount"]>
	</cffunction>

	<!---
	 * Returns the number of the current page of results.
	--->
	<cffunction name="getCurrentPage" access="public" returntype="numeric" output="no">
		<cfargument name="group" type="string" required="no" default="default">
		<cfset var currentPage = 0>

		<cfset ensureGroup(arguments.group)>

		<cfset currentPage = this.groups[arguments.group]["currentPage"]>

		<cfif currentPage EQ 0>
			<cfreturn 1>
		</cfif>

		<cfreturn currentPage>
	</cffunction>

	<!---
	 * Tells whether this group of results has any more pages of results.
	--->
	<cffunction name="hasMore" access="public" returntype="boolean" output="no">
		<cfargument name="group" type="string" required="no" default="default">
		<cfset var details = "">

		<cfset ensureGroup(arguments.group)>

		<cfset details = this.groups[arguments.group]>

		<!--- no total yet (null) --->
		<cfif NOT IsNumeric(details["total"])>
			<cfreturn false>
		</cfif>

		<cfreturn details["currentPage"] * details["perPage"] LT details["total"]>
	</cffunction>

	<!---
	 * Returns the last page, if we have a total that we can calculate with.
	 *
	 * @return The page, or an empty string for null
	--->
	<cffunction name="getLastPage" access="public" returntype="any" output="no">
		<cfargument name="group" type="string" required="no" default="default">
		<cfset var details = "">

		<cfset ensureGroup(arguments.group)>

		<cfset details = this.groups[arguments.group]>

		<cfif NOT IsNumeric(details["total"]) OR NOT IsNumeric(details["perPage"])>
			<cfreturn "">
		</cfif>

		<cfreturn Ceiling(details["total"] / details["perPage"])>
	</cffunction>

	<!---
	 * Returns the first page.
	--->
	<cffunction name="getFirstPage" access="public" returntype="any" output="no">
		<cfargument name="group" type="string" required="no" default="default">

		<cfset ensureGroup(arguments.group)>

		<!--- @todo determine based on a 'surroundCount' value --->
		<cfreturn 1>
	</cffunction>

	<!---
	 * Returns the URI for a specific page for the specified group.
	 *
	 * @return A string, or a URI if returnObject is true
	--->
	<cffunction name="getPageURI" access="public" returntype="any" output="no">
		<cfargument name="page" type="any" required="no" default="">
		<cfargument name="group" type="string" required="no" default="default">
		<cfargument name="returnObject" type="boolean" required="no" default="false">
		<cfset var uri = "">
		<cfset var segment = 0>
		<cfset var details = "">
		<cfset var get = "">
		<cfset var query = "">
		<cfset var key = "">

		<cfset ensureGroup(arguments.group)>

		<cfset details = this.groups[arguments.group]>
		<cfset uri = details["uri"]>

		<cfif StructKeyExists(this.segment, arguments.group)>
			<cfset segment = this.segment[arguments.group]>
		</cfif>

		<cfif segment NEQ 0>
			<cfset uri.setSegment(segment, arguments.page)>
		<cfelse>
			<cfset uri.addQuery(details["pageSelector"], arguments.page)>
		</cfif>

		<cfif IsArray(this.only)>
			<cfset get = service("superglobals").getGetArray()>
			<cfset query = array_()>

			<!--- array_intersect_key(GET, array_flip(only)) --->
			<cfloop collection="#get#" item="key">
				<cfif in_array(key, this.only)>
					<cfset query[key] = get[key]>
				</cfif>
			</cfloop>

			<cfif segment EQ 0>
				<cfset query[details["pageSelector"]] = arguments.page>
			</cfif>

			<cfset uri.setQueryArray(query)>
		</cfif>

		<cfif arguments.returnObject>
			<cfreturn uri>
		</cfif>

		<cfreturn static_("ColdIgniter\HTTP\URI").createURIString(uri.getScheme(), uri.getAuthority(), uri.getPath(), uri.getQuery(), uri.getFragment())>
	</cffunction>

	<!---
	 * Returns the full URI to the next page of results, or null (an empty string).
	--->
	<cffunction name="getNextPageURI" access="public" returntype="any" output="no">
		<cfargument name="group" type="string" required="no" default="default">
		<cfargument name="returnObject" type="boolean" required="no" default="false">
		<cfset var last = "">
		<cfset var curr = 0>
		<cfset var page = "">

		<cfset ensureGroup(arguments.group)>

		<cfset last = getLastPage(arguments.group)>
		<cfset curr = getCurrentPage(arguments.group)>

		<!--- Last page --->
		<cfif last NEQ "" AND last NEQ 0 AND curr NEQ 0 AND last EQ curr>
			<cfreturn "">
		</cfif>

		<cfif last NEQ "" AND last GT curr>
			<cfset page = curr + 1>
		</cfif>

		<cfreturn getPageURI(page, arguments.group, arguments.returnObject)>
	</cffunction>

	<!---
	 * Returns the full URL to the previous page of results, or null (an empty string).
	--->
	<cffunction name="getPreviousPageURI" access="public" returntype="any" output="no">
		<cfargument name="group" type="string" required="no" default="default">
		<cfargument name="returnObject" type="boolean" required="no" default="false">
		<cfset var first = 0>
		<cfset var curr = 0>
		<cfset var page = "">

		<cfset ensureGroup(arguments.group)>

		<cfset first = getFirstPage(arguments.group)>
		<cfset curr = getCurrentPage(arguments.group)>

		<!--- First page --->
		<cfif first NEQ 0 AND curr NEQ 0 AND first EQ curr>
			<cfreturn "">
		</cfif>

		<cfif first LT curr>
			<cfset page = curr - 1>
		</cfif>

		<cfreturn getPageURI(page, arguments.group, arguments.returnObject)>
	</cffunction>

	<!---
	 * Returns the number of results per page that should be shown.
	--->
	<cffunction name="getPerPage" access="public" returntype="numeric" output="no">
		<cfargument name="group" type="string" required="no" default="default">

		<cfset ensureGroup(arguments.group)>

		<cfreturn Fix(this.groups[arguments.group]["perPage"])>
	</cffunction>

	<!---
	 * Returns an array with details about the results, including
	 * pagination and the URIs of the neighbouring pages. Does not include
	 * the actual data. This data is suitable for adding
	 * a 'pagination' section to the response of an API.
	 *
	 * @return A map (see array_())
	 *
	 * @throws PagerException
	--->
	<cffunction name="getDetails" access="public" returntype="any" output="no">
		<cfargument name="group" type="string" required="no" default="default">
		<cfset var newGroup = "">

		<cfif NOT array_key_exists(arguments.group, this.groups)>
			<cfset static_("ColdIgniter\Pager\Exceptions\PagerException").forInvalidPaginationGroup(arguments.group)>
		</cfif>

		<cfset newGroup = array_merge(this.groups[arguments.group])>

		<!--- Add the next/previous pages --->
		<cfset newGroup["next"] = getNextPageURI(arguments.group)>
		<cfset newGroup["previous"] = getPreviousPageURI(arguments.group)>
		<cfset newGroup["segment"] = 0>

		<cfif StructKeyExists(this.segment, arguments.group)>
			<cfset newGroup["segment"] = this.segment[arguments.group]>
		</cfif>

		<cfreturn newGroup>
	</cffunction>

	<!---
	 * Sets only allowed GET queries to be used for pagination
	 * links. The list of names is a list (ArrayNew).
	 *
	 * @return Pager
	--->
	<cffunction name="only" access="public" returntype="any" output="no">
		<cfargument name="queries" type="array" required="yes">

		<cfset this.only = arguments.queries>

		<cfreturn this>
	</cffunction>

	<!---
	 * Ensures that an array exists in $this->groups for the group specified.
	 * Can be used to add default values at a later date, etc.
	 *
	 * @param perPage The number of items per page, an empty string for the default
	--->
	<cffunction name="ensureGroup" access="private" returntype="void" output="no">
		<cfargument name="group" type="string" required="yes">
		<cfargument name="perPage" type="any" required="no" default="">
		<cfset var current = "">
		<cfset var get = "">
		<cfset var details = "">

		<cfif NOT array_key_exists(arguments.group, this.groups)>
			<cfif is_null(arguments.perPage)>
				<cfset arguments.perPage = this.config.perPage>
			</cfif>

			<cfset current = current_url(true)>

			<cfset details = array_("currentUri", current.clone_(), "uri", current.clone_(), "hasMore", false, "total", "", "perPage", arguments.perPage, "pageCount", 1, "pageSelector", "page")>

			<cfif arguments.group NEQ "default">
				<cfset details["pageSelector"] = "page_" & arguments.group>
			</cfif>

			<cfset this.groups[arguments.group] = details>

			<cfset calculateCurrentPage(arguments.group)>

			<cfset get = service("superglobals").getGetArray()>

			<cfif StructCount(get) GT 0>
				<cfset details["uri"] = details["uri"].setQueryArray(get)>
			</cfif>
		</cfif>
	</cffunction>

	<!---
	 * Calculates the current page for a group from the request, by the
	 * segment or by the query variable.
	--->
	<cffunction name="calculateCurrentPage" access="private" returntype="void" output="no">
		<cfargument name="group" type="string" required="yes">
		<cfset var details = this.groups[arguments.group]>
		<cfset var page = 1>

		<cfif StructKeyExists(this.segment, arguments.group)>
			<cftry>
				<cfset details["currentPage"] = Fix(Val(details["currentUri"].setSilent(false).getSegment(this.segment[arguments.group])))>

				<cfcatch type="ColdIgniter.HTTP.Exceptions.HTTPException">
					<cfset details["currentPage"] = 1>
				</cfcatch>
			</cftry>
		<cfelse>
			<cfset page = service("superglobals").get(details["pageSelector"], "1")>

			<!--- a variable that is a list or a map is an array in the original, and (int) of that is 1 --->
			<cfif IsSimpleValue(page)>
				<cfset page = Fix(Val(page))>
			<cfelse>
				<cfset page = 1>
			</cfif>

			<cfif page LT 1>
				<cfset page = 1>
			</cfif>

			<cfset details["currentPage"] = page>
		</cfif>
	</cffunction>

</cfcomponent>
