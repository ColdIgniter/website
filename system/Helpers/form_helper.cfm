<!---
 * ColdIgniter Form Helpers
 *
 * Attributes, options and hidden data are a map made with array_() (the
 * attributes keep their order that way), or a string where the original
 * takes one. A list of values (selected, the options of a list, the
 * options of a datalist) is a CFML array. A struct also works, but it has
 * no order.
 *
 * Differs from the original: the original passes arrays by value. Here a
 * map that a function changes is copied first, so the caller's map is
 * never changed.
 *
 * Differs from the original: a null cannot be stored, so an empty string
 * stands for it (an old or posted value that is empty reads as "not
 * set"), and a boolean attribute needs a real boolean, such as
 * JavaCast("boolean", true) (see is_bool()), as the text "true" is text.
 *
 * A function here has no guard against a second definition (the original
 * checks function_exists): helper() keeps the first definition of a name.
--->

<!---
 * Form Declaration
 *
 * Creates the opening portion of the form.
 *
 * @param action     The URI segments of the form destination
 * @param attributes A key/value pair of attributes (a map), or string representation
 * @param hidden     A key/value pair hidden data (a map)
--->
<cffunction name="form_open" returntype="string" output="no" hint="Form Declaration">
	<cfargument name="action" type="string" required="no" default="">
	<cfargument name="attributes" type="any" required="no" default="">
	<cfargument name="hidden" type="any" required="no" default="">
	<cfset var csrfId = "">
	<cfset var attributeString = "">
	<cfset var appConfig = "">
	<cfset var form_ = "">
	<cfset var filters = "">
	<cfset var before = "">
	<cfset var key = "">

	<!--- If no action is provided then set to the current url --->
	<cfif Compare(arguments.action, "") EQ 0>
		<cfset arguments.action = current_url(true).__toString()>
	<!--- If an action is not a full URL then turn it into one --->
	<cfelseif Find("://", arguments.action) EQ 0>
		<!--- If an action has {locale} --->
		<cfif Find("{locale}", arguments.action) GT 0>
			<cfset arguments.action = Replace(arguments.action, "{locale}", service("request").getLocale_(), "all")>
		</cfif>

		<cfset arguments.action = site_url(arguments.action)>
	</cfif>

	<cfif IsStruct(arguments.attributes) AND array_key_exists("csrf_id", arguments.attributes)>
		<cfset arguments.attributes = array_merge(arguments.attributes)>
		<cfset csrfId = arguments.attributes["csrf_id"]>
		<cfset arguments.attributes.remove(JavaCast("string", "csrf_id"))>
	</cfif>

	<cfset attributeString = stringify_attributes(arguments.attributes)>

	<cfif FindNoCase("method=", attributeString) EQ 0>
		<cfset attributeString = attributeString & " method=""post""">
	</cfif>
	<cfif FindNoCase("accept-charset=", attributeString) EQ 0>
		<cfset appConfig = config("Config\App")>
		<cfset attributeString = attributeString & " accept-charset=""" & LCase(appConfig.charset) & """">
	</cfif>

	<cfset form_ = "<form action=""" & arguments.action & """" & attributeString & ">" & Chr(10)>

	<!--- Add CSRF field if enabled, but leave it out for GET requests and requests to external websites --->
	<cfset filters = service("filters").getFilters()>
	<cfset before = filters["before"]>

	<cfif (in_array("csrf", before, true) OR array_key_exists("csrf", before)) AND Find(base_url(), arguments.action) GT 0 AND FindNoCase("method=""get""", form_) EQ 0>
		<cfset form_ = form_ & csrf_field(csrfId)>
	</cfif>

	<cfif IsStruct(arguments.hidden)>
		<cfloop collection="#arguments.hidden#" item="key">
			<cfset form_ = form_ & form_hidden(key, arguments.hidden[key])>
		</cfloop>
	</cfif>

	<cfreturn form_>
</cffunction>

<!---
 * Form Declaration - Multipart type
 *
 * Creates the opening portion of the form, but with "multipart/form-data".
 *
 * @param action     The URI segments of the form destination
 * @param attributes A key/value pair of attributes (a map), or the same as a string
 * @param hidden     A key/value pair hidden data (a map)
--->
<cffunction name="form_open_multipart" returntype="string" output="no" hint="Form Declaration - Multipart type">
	<cfargument name="action" type="string" required="no" default="">
	<cfargument name="attributes" type="any" required="no" default="">
	<cfargument name="hidden" type="any" required="no" default="">

	<!--- An empty string is the empty array of the original --->
	<cfif IsSimpleValue(arguments.attributes) AND NOT is_null(arguments.attributes)>
		<cfset arguments.attributes = arguments.attributes & " enctype=""" & esc("multipart/form-data") & """">
	<cfelse>
		<cfif is_null(arguments.attributes)>
			<cfset arguments.attributes = array_()>
		<cfelse>
			<cfset arguments.attributes = array_merge(arguments.attributes)>
		</cfif>
		<cfset arguments.attributes["enctype"] = "multipart/form-data">
	</cfif>

	<cfreturn form_open(arguments.action, arguments.attributes, arguments.hidden)>
</cffunction>

<!---
 * Hidden Input Field
 *
 * Generates hidden fields. You can pass a simple key/value string or
 * a map with multiple values.
 *
 * Differs from the original: the static variable of the original is
 * kept in the request scope.
 *
 * @param name      Field name or a map to create multiple fields
 * @param value     Field value (a string, a list or a map)
 * @param recursing
--->
<cffunction name="form_hidden" returntype="string" output="no" hint="Hidden Input Field">
	<cfargument name="name" type="any" required="yes">
	<cfargument name="value" type="any" required="no" default="">
	<cfargument name="recursing" type="boolean" required="no" default="false">
	<cfset var key = "">
	<cfset var k = "">
	<cfset var i = 0>

	<cfif NOT arguments.recursing>
		<cfset request.ColdIgniter["form_hidden"] = Chr(10)>
	</cfif>

	<cfif IsStruct(arguments.name)>
		<cfloop collection="#arguments.name#" item="key">
			<cfset form_hidden(key, arguments.name[key], true)>
		</cfloop>

		<cfreturn request.ColdIgniter["form_hidden"]>
	</cfif>

	<cfif NOT is_array(arguments.value)>
		<cfset request.ColdIgniter["form_hidden"] = request.ColdIgniter["form_hidden"] & form_input(arguments.name, arguments.value, "", "hidden")>
	<cfelseif IsArray(arguments.value)>
		<cfloop from="1" to="#ArrayLen(arguments.value)#" index="i">
			<!--- the key of a list is an integer --->
			<cfset form_hidden(arguments.name & "[]", arguments.value[i], true)>
		</cfloop>
	<cfelse>
		<cfloop collection="#arguments.value#" item="key">
			<cfset k = key>
			<cfif REFind("^(0|-?[1-9][0-9]*)$", k) GT 0>
				<cfset k = "">
			</cfif>
			<cfset form_hidden(arguments.name & "[" & k & "]", arguments.value[key], true)>
		</cfloop>
	</cfif>

	<cfreturn request.ColdIgniter["form_hidden"]>
</cffunction>

<!---
 * Text Input Field. If 'type' is passed in the type field, it will be
 * used as the input type, for making 'email', 'phone', etc input fields.
 *
 * @param data  A string (the name), or a map
 * @param extra A string, or a map
--->
<cffunction name="form_input" returntype="string" output="no" hint="Text Input Field">
	<cfargument name="data" type="any" required="no" default="">
	<cfargument name="value" type="string" required="no" default="">
	<cfargument name="extra" type="any" required="no" default="">
	<cfargument name="type" type="string" required="no" default="text">
	<cfset var defaultName = arguments.data>
	<cfset var defaults = "">

	<cfif is_array(arguments.data)>
		<cfset defaultName = "">
	</cfif>

	<cfset defaults = array_("type", arguments.type, "name", defaultName, "value", arguments.value)>

	<cfreturn "<input " & parse_form_attributes(arguments.data, defaults) & stringify_attributes(arguments.extra) & _solidus() & ">" & Chr(10)>
</cffunction>

<!---
 * Password Field
 *
 * Identical to the input function but adds the "password" type
 *
 * @param data  A string (the name), or a map
 * @param extra A string, or a map
--->
<cffunction name="form_password" returntype="string" output="no" hint="Password Field">
	<cfargument name="data" type="any" required="no" default="">
	<cfargument name="value" type="string" required="no" default="">
	<cfargument name="extra" type="any" required="no" default="">

	<cfif NOT is_array(arguments.data)>
		<cfset arguments.data = array_("name", arguments.data)>
	<cfelse>
		<cfset arguments.data = array_merge(arguments.data)>
	</cfif>
	<cfset arguments.data["type"] = "password">

	<cfreturn form_input(arguments.data, arguments.value, arguments.extra)>
</cffunction>

<!---
 * Upload Field
 *
 * Identical to the input function but adds the "file" type
 *
 * @param data  A string (the name), or a map
 * @param extra A string, or a map
--->
<cffunction name="form_upload" returntype="string" output="no" hint="Upload Field">
	<cfargument name="data" type="any" required="no" default="">
	<cfargument name="value" type="string" required="no" default="">
	<cfargument name="extra" type="any" required="no" default="">
	<cfset var defaults = array_("type", "file", "name", "")>

	<cfif NOT is_array(arguments.data)>
		<cfset arguments.data = array_("name", arguments.data)>
	<cfelse>
		<cfset arguments.data = array_merge(arguments.data)>
	</cfif>

	<cfset arguments.data["type"] = "file">

	<cfreturn "<input " & parse_form_attributes(arguments.data, defaults) & stringify_attributes(arguments.extra) & _solidus() & ">" & Chr(10)>
</cffunction>

<!---
 * Textarea field
 *
 * @param data  A string (the name), or a map
 * @param extra A string, or a map
--->
<cffunction name="form_textarea" returntype="string" output="no" hint="Textarea field">
	<cfargument name="data" type="any" required="no" default="">
	<cfargument name="value" type="string" required="no" default="">
	<cfargument name="extra" type="any" required="no" default="">
	<cfset var defaultName = arguments.data>
	<cfset var defaults = "">
	<cfset var val = "">

	<cfif is_array(arguments.data)>
		<cfset defaultName = "">
	</cfif>

	<cfset defaults = array_("name", defaultName, "cols", "40", "rows", "10")>

	<cfif NOT IsStruct(arguments.data) OR NOT StructKeyExists(arguments.data, "value")>
		<cfset val = arguments.value>
	<cfelse>
		<cfset arguments.data = array_merge(arguments.data)>
		<cfset val = arguments.data["value"]>
		<cfset arguments.data.remove(JavaCast("string", "value"))> <!--- textareas don't use the value attribute --->
	</cfif>

	<!--- Unsets default rows and cols if defined in extra field as array or string. --->
	<cfif (IsStruct(arguments.extra) AND array_key_exists("rows", arguments.extra)) OR (IsSimpleValue(arguments.extra) AND Find("rows=", LCase(preg_replace("/\s+/", "", arguments.extra))) GT 0)>
		<cfset defaults.remove(JavaCast("string", "rows"))>
	</cfif>

	<cfif (IsStruct(arguments.extra) AND array_key_exists("cols", arguments.extra)) OR (IsSimpleValue(arguments.extra) AND Find("cols=", LCase(preg_replace("/\s+/", "", arguments.extra))) GT 0)>
		<cfset defaults.remove(JavaCast("string", "cols"))>
	</cfif>

	<!--- htmlspecialchars() of the original also changes the single quote --->
	<cfreturn "<textarea " & RTrim(parse_form_attributes(arguments.data, defaults)) & stringify_attributes(arguments.extra) & ">" & Replace(HTMLEditFormat(val), "'", "&##039;", "all") & "</textarea>" & Chr(10)>
</cffunction>

<!---
 * Multi-select menu
 *
 * @param name     A string, or a map
 * @param options  A map of strings, or of maps of strings (the groups)
 * @param selected A list of keys
 * @param extra    A string, or a map
--->
<cffunction name="form_multiselect" returntype="string" output="no" hint="Multi-select menu">
	<cfargument name="name" type="any" required="no" default="">
	<cfargument name="options" type="any" required="no" default="#ArrayNew(1)#">
	<cfargument name="selected" type="any" required="no" default="#ArrayNew(1)#">
	<cfargument name="extra" type="any" required="no" default="">

	<cfset arguments.extra = stringify_attributes(arguments.extra)>

	<cfif FindNoCase("multiple", arguments.extra) EQ 0>
		<cfset arguments.extra = arguments.extra & " multiple=""multiple""">
	</cfif>

	<cfreturn form_dropdown(arguments.name, arguments.options, arguments.selected, arguments.extra)>
</cffunction>

<!---
 * Drop-down Menu
 *
 * A list of options (a CFML array) is read as a map with the keys 0, 1, ...
 *
 * @param data     A string (the name), or a map
 * @param options  A map of strings, or of maps of strings (the groups), or a list
 * @param selected A string, or a list of keys
 * @param extra    A string, or a map
--->
<cffunction name="form_dropdown" returntype="string" output="no" hint="Drop-down Menu">
	<cfargument name="data" type="any" required="no" default="">
	<cfargument name="options" type="any" required="no" default="#ArrayNew(1)#">
	<cfargument name="selected" type="any" required="no" default="#ArrayNew(1)#">
	<cfargument name="extra" type="any" required="no" default="">
	<cfset var defaults = array_()>
	<cfset var superglobals = "">
	<cfset var postValue = "">
	<cfset var standard = ArrayNew(1)>
	<cfset var optionMap = "">
	<cfset var groupMap = "">
	<cfset var multiple = "">
	<cfset var form_ = "">
	<cfset var key = "">
	<cfset var val = "">
	<cfset var optgroupKey = "">
	<cfset var sel = "">
	<cfset var item = "">
	<cfset var i = 0>
	<cfset var nl = Chr(10)>

	<cfif IsStruct(arguments.data)>
		<cfset arguments.data = array_merge(arguments.data)>

		<cfif StructKeyExists(arguments.data, "selected")>
			<cfset arguments.selected = arguments.data["selected"]>
			<cfset arguments.data.remove(JavaCast("string", "selected"))> <!--- select tags don't have a selected attribute --->
		</cfif>
		<cfif StructKeyExists(arguments.data, "options")>
			<cfset arguments.options = arguments.data["options"]>
			<cfset arguments.data.remove(JavaCast("string", "options"))> <!--- select tags don't use an options attribute --->
		</cfif>
	<cfelse>
		<cfset defaults = array_("name", arguments.data)>
	</cfif>

	<cfif NOT is_array(arguments.selected)>
		<cfset item = arguments.selected>
		<cfset arguments.selected = ArrayNew(1)>
		<cfset ArrayAppend(arguments.selected, item)>
	</cfif>
	<cfif NOT is_array(arguments.options)>
		<cfset item = arguments.options>
		<cfset arguments.options = ArrayNew(1)>
		<cfset ArrayAppend(arguments.options, item)>
	</cfif>

	<!--- If no selected state was submitted we will attempt to set it automatically --->
	<cfif (IsArray(arguments.selected) AND ArrayLen(arguments.selected) EQ 0) OR (IsStruct(arguments.selected) AND StructCount(arguments.selected) EQ 0)>
		<cfset superglobals = service("superglobals")>
		<cfif IsStruct(arguments.data)>
			<cfif StructKeyExists(arguments.data, "name")>
				<cfset postValue = superglobals.post(arguments.data["name"])>
				<cfif NOT is_null(postValue)>
					<cfset arguments.selected = ArrayNew(1)>
					<cfset ArrayAppend(arguments.selected, postValue)>
				</cfif>
			</cfif>
		<cfelse>
			<cfset postValue = superglobals.post(arguments.data)>
			<cfif NOT is_null(postValue)>
				<cfset arguments.selected = ArrayNew(1)>
				<cfset ArrayAppend(arguments.selected, postValue)>
			</cfif>
		</cfif>
	</cfif>

	<!--- Standardize selected as strings, like the option keys will be --->
	<cfif IsStruct(arguments.selected)>
		<cfloop collection="#arguments.selected#" item="key">
			<cfset ArrayAppend(standard, arguments.selected[key] & "")>
		</cfloop>
	<cfelse>
		<cfloop from="1" to="#ArrayLen(arguments.selected)#" index="i">
			<cfset ArrayAppend(standard, arguments.selected[i] & "")>
		</cfloop>
	</cfif>

	<cfset arguments.extra = stringify_attributes(arguments.extra)>
	<cfif ArrayLen(standard) GT 1 AND FindNoCase("multiple", arguments.extra) EQ 0>
		<cfset multiple = " multiple=""multiple""">
	</cfif>
	<cfset form_ = "<select " & RTrim(parse_form_attributes(arguments.data, defaults)) & arguments.extra & multiple & ">" & nl>

	<!--- a list of options has the keys 0, 1, ... --->
	<cfif IsArray(arguments.options)>
		<cfset optionMap = array_()>
		<cfloop from="1" to="#ArrayLen(arguments.options)#" index="i">
			<cfset key = "" & (i - 1)>
			<cfset optionMap[key] = arguments.options[i]>
		</cfloop>
	<cfelse>
		<cfset optionMap = arguments.options>
	</cfif>

	<cfloop collection="#optionMap#" item="key">
		<!--- Keys should always be strings for strict comparison --->
		<cfset val = optionMap[key]>

		<cfif is_array(val)>
			<cfif IsArray(val)>
				<cfset groupMap = array_()>
				<cfloop from="1" to="#ArrayLen(val)#" index="i">
					<cfset optgroupKey = "" & (i - 1)>
					<cfset groupMap[optgroupKey] = val[i]>
				</cfloop>
			<cfelse>
				<cfset groupMap = val>
			</cfif>

			<cfif StructCount(groupMap) GT 0>
				<cfset form_ = form_ & "<optgroup label=""" & key & """>" & nl>

				<cfloop collection="#groupMap#" item="optgroupKey">
					<!--- Keys should always be strings for strict comparison --->
					<cfif in_array(optgroupKey, standard, true)>
						<cfset sel = " selected=""selected""">
					<cfelse>
						<cfset sel = "">
					</cfif>
					<cfset form_ = form_ & "<option value=""" & Replace(HTMLEditFormat(optgroupKey), "'", "&##039;", "all") & """" & sel & ">" & groupMap[optgroupKey] & "</option>" & nl>
				</cfloop>

				<cfset form_ = form_ & "</optgroup>" & nl>
			</cfif>
		<cfelse>
			<cfif in_array(key, standard, true)>
				<cfset sel = " selected=""selected""">
			<cfelse>
				<cfset sel = "">
			</cfif>
			<cfset form_ = form_ & "<option value=""" & Replace(HTMLEditFormat(key), "'", "&##039;", "all") & """" & sel & ">" & val & "</option>" & nl>
		</cfif>
	</cfloop>

	<cfreturn form_ & "</select>" & nl>
</cffunction>

<!---
 * Checkbox Field
 *
 * Differs from the original: a checked attribute that is the text "true"
 * or "false" counts as that boolean (a literal is text here).
 *
 * @param data  A string (the name), or a map
 * @param extra A string, or a map
--->
<cffunction name="form_checkbox" returntype="string" output="no" hint="Checkbox Field">
	<cfargument name="data" type="any" required="no" default="">
	<cfargument name="value" type="string" required="no" default="">
	<cfargument name="checked" type="boolean" required="no" default="false">
	<cfargument name="extra" type="any" required="no" default="">
	<cfset var defaultName = arguments.data>
	<cfset var defaults = "">
	<cfset var checkedValue = "">
	<cfset var isFalse = false>
	<cfset var isTrue = arguments.checked>

	<cfif is_array(arguments.data)>
		<cfset defaultName = "">
	</cfif>

	<cfset defaults = array_("type", "checkbox", "name", defaultName, "value", arguments.value)>

	<cfif IsStruct(arguments.data) AND array_key_exists("checked", arguments.data)>
		<cfset arguments.data = array_merge(arguments.data)>
		<cfset checkedValue = arguments.data["checked"]>

		<cfif IsSimpleValue(checkedValue)>
			<cfset isFalse = (is_bool(checkedValue) AND NOT checkedValue) OR Compare(checkedValue, "false") EQ 0>
			<cfset isTrue = (is_bool(checkedValue) AND checkedValue) OR Compare(checkedValue, "true") EQ 0>
		<cfelse>
			<cfset isTrue = false>
		</cfif>

		<cfif isFalse>
			<cfset arguments.data.remove(JavaCast("string", "checked"))>
		<cfelse>
			<cfset arguments.data["checked"] = "checked">
		</cfif>
	</cfif>

	<cfif isTrue>
		<cfset defaults["checked"] = "checked">
	</cfif>

	<cfreturn "<input " & parse_form_attributes(arguments.data, defaults) & stringify_attributes(arguments.extra) & _solidus() & ">" & Chr(10)>
</cffunction>

<!---
 * Radio Button
 *
 * @param data  A string (the name), or a map
 * @param extra A string, or a map
--->
<cffunction name="form_radio" returntype="string" output="no" hint="Radio Button">
	<cfargument name="data" type="any" required="no" default="">
	<cfargument name="value" type="string" required="no" default="">
	<cfargument name="checked" type="boolean" required="no" default="false">
	<cfargument name="extra" type="any" required="no" default="">

	<cfif NOT is_array(arguments.data)>
		<cfset arguments.data = array_("name", arguments.data)>
	<cfelse>
		<cfset arguments.data = array_merge(arguments.data)>
	</cfif>
	<cfset arguments.data["type"] = "radio">

	<cfreturn form_checkbox(arguments.data, arguments.value, arguments.checked, arguments.extra)>
</cffunction>

<!---
 * Submit Button
 *
 * @param data  A string (the name), or a map
 * @param extra A string, or a map
--->
<cffunction name="form_submit" returntype="string" output="no" hint="Submit Button">
	<cfargument name="data" type="any" required="no" default="">
	<cfargument name="value" type="string" required="no" default="">
	<cfargument name="extra" type="any" required="no" default="">

	<cfreturn form_input(arguments.data, arguments.value, arguments.extra, "submit")>
</cffunction>

<!---
 * Reset Button
 *
 * @param data  A string (the name), or a map
 * @param extra A string, or a map
--->
<cffunction name="form_reset" returntype="string" output="no" hint="Reset Button">
	<cfargument name="data" type="any" required="no" default="">
	<cfargument name="value" type="string" required="no" default="">
	<cfargument name="extra" type="any" required="no" default="">

	<cfreturn form_input(arguments.data, arguments.value, arguments.extra, "reset")>
</cffunction>

<!---
 * Form Button
 *
 * @param data  A string (the name), or a map
 * @param extra A string, or a map
--->
<cffunction name="form_button" returntype="string" output="no" hint="Form Button">
	<cfargument name="data" type="any" required="no" default="">
	<cfargument name="content" type="string" required="no" default="">
	<cfargument name="extra" type="any" required="no" default="">
	<cfset var defaultName = arguments.data>
	<cfset var defaults = "">

	<cfif is_array(arguments.data)>
		<cfset defaultName = "">
	</cfif>

	<cfset defaults = array_("name", defaultName, "type", "button")>

	<cfif IsStruct(arguments.data) AND StructKeyExists(arguments.data, "content")>
		<cfset arguments.data = array_merge(arguments.data)>
		<cfset arguments.content = arguments.data["content"]>
		<cfset arguments.data.remove(JavaCast("string", "content"))> <!--- content is not an attribute --->
	</cfif>

	<cfreturn "<button " & parse_form_attributes(arguments.data, defaults) & stringify_attributes(arguments.extra) & ">" & arguments.content & "</button>" & Chr(10)>
</cffunction>

<!---
 * Form Label Tag
 *
 * @param labelText  The text to appear onscreen
 * @param id         The id the label applies to
 * @param attributes Additional attributes (a map)
--->
<cffunction name="form_label" returntype="string" output="no" hint="Form Label Tag">
	<cfargument name="labelText" type="string" required="no" default="">
	<cfargument name="id" type="string" required="no" default="">
	<cfargument name="attributes" type="any" required="no" default="">
	<cfset var label = "<label">
	<cfset var key = "">

	<cfif Compare(arguments.id, "") NEQ 0>
		<cfset label = label & " for=""" & arguments.id & """">
	</cfif>

	<cfif IsStruct(arguments.attributes)>
		<cfloop collection="#arguments.attributes#" item="key">
			<cfset label = label & " " & key & "=""" & arguments.attributes[key] & """">
		</cfloop>
	</cfif>

	<cfreturn label & ">" & arguments.labelText & "</label>">
</cffunction>

<!---
 * Datalist
 *
 * The <datalist> element specifies a list of pre-defined options for an <input> element.
 * Users will see a drop-down list of pre-defined options as they input data.
 * The list attribute of the <input> element, must refer to the id attribute of the <datalist> element.
 *
 * @param options A list of strings
--->
<cffunction name="form_datalist" returntype="string" output="no" hint="Datalist">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="value" type="string" required="yes">
	<cfargument name="options" type="array" required="yes">
	<cfset var data = array_("type", "text", "name", arguments.name, "list", arguments.name & "_list", "value", arguments.value)>
	<cfset var out = "">
	<cfset var i = 0>

	<cfset out = form_input(data) & Chr(10)>

	<cfset out = out & "<datalist id='" & arguments.name & "_list'>">

	<cfloop from="1" to="#ArrayLen(arguments.options)#" index="i">
		<cfset out = out & "<option value='" & arguments.options[i] & "'>" & Chr(10)>
	</cfloop>

	<cfreturn out & "</datalist>" & Chr(10)>
</cffunction>

<!---
 * Fieldset Tag
 *
 * Used to produce <fieldset><legend>text</legend>.  To close fieldset
 * use form_fieldset_close()
 *
 * @param legendText The legend text
 * @param attributes Additional attributes (a map)
--->
<cffunction name="form_fieldset" returntype="string" output="no" hint="Fieldset Tag">
	<cfargument name="legendText" type="string" required="no" default="">
	<cfargument name="attributes" type="any" required="no" default="">
	<cfset var fieldset = "<fieldset" & stringify_attributes(arguments.attributes) & ">" & Chr(10)>

	<cfif Compare(arguments.legendText, "") NEQ 0>
		<cfreturn fieldset & "<legend>" & arguments.legendText & "</legend>" & Chr(10)>
	</cfif>

	<cfreturn fieldset>
</cffunction>

<!---
 * Fieldset Close Tag
--->
<cffunction name="form_fieldset_close" returntype="string" output="no" hint="Fieldset Close Tag">
	<cfargument name="extra" type="string" required="no" default="">

	<cfreturn "</fieldset>" & arguments.extra>
</cffunction>

<!---
 * Form Close Tag
--->
<cffunction name="form_close" returntype="string" output="no" hint="Form Close Tag">
	<cfargument name="extra" type="string" required="no" default="">

	<cfreturn "</form>" & arguments.extra>
</cffunction>

<!---
 * Grabs a value from the POST array for the specified field so you can
 * re-populate an input field or textarea
 *
 * Differs from the original: a default that is not a list or a map is a
 * string already.
 *
 * @param field      Field name
 * @param default    Default value (a string or a list)
 * @param htmlEscape Whether to escape HTML special characters or not
 *
 * @return A list or a string
--->
<cffunction name="set_value" returntype="any" output="no" hint="Grabs a value from the POST array for the specified field">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="default" type="any" required="no" default="">
	<cfargument name="htmlEscape" type="boolean" required="no" default="true">
	<cfset var request_obj = service("request")>
	<cfset var value = request_obj.getOldInput(arguments.field)>

	<cfif is_null(value)>
		<cfset value = request_obj.getPost(arguments.field)>
	</cfif>
	<cfif is_null(value)>
		<cfset value = arguments.default>
	</cfif>

	<cfif arguments.htmlEscape>
		<cfreturn esc(value)>
	</cfif>

	<cfreturn value>
</cffunction>

<!---
 * Set Select
 *
 * Let's you set the selected value of a <select> menu via data in the POST array.
--->
<cffunction name="set_select" returntype="string" output="no" hint="Let's you set the selected value of a select menu via data in the POST array">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="value" type="string" required="no" default="">
	<cfargument name="default" type="boolean" required="no" default="false">
	<cfset var request_obj = service("request")>
	<cfset var input = "">
	<cfset var v = "">
	<cfset var i = 0>

	<!--- Try any old input data we may have first --->
	<cfset input = request_obj.getOldInput(arguments.field)>

	<cfif is_null(input)>
		<cfset input = request_obj.getPost(arguments.field)>
	</cfif>

	<cfif is_null(input)>
		<cfif arguments.default>
			<cfreturn " selected=""selected""">
		</cfif>

		<cfreturn "">
	</cfif>

	<cfif is_array(input)>
		<!--- Note: in_array('', array(0)) returns TRUE, do not use it --->
		<cfif IsStruct(input)>
			<cfloop collection="#input#" item="i">
				<cfif IsSimpleValue(input[i]) AND Compare(arguments.value, input[i]) EQ 0>
					<cfreturn " selected=""selected""">
				</cfif>
			</cfloop>
		<cfelse>
			<cfloop from="1" to="#ArrayLen(input)#" index="i">
				<cfif IsSimpleValue(input[i]) AND Compare(arguments.value, input[i]) EQ 0>
					<cfreturn " selected=""selected""">
				</cfif>
			</cfloop>
		</cfif>

		<cfreturn "">
	</cfif>

	<cfif Compare(input, arguments.value) EQ 0>
		<cfreturn " selected=""selected""">
	</cfif>

	<cfreturn "">
</cffunction>

<!---
 * Set Checkbox
 *
 * Let's you set the selected value of a checkbox via the value in the POST array.
 *
 * Differs from the original: an empty input counts as null, so it is
 * never equal to a value.
--->
<cffunction name="set_checkbox" returntype="string" output="no" hint="Let's you set the selected value of a checkbox via the value in the POST array">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="value" type="string" required="no" default="">
	<cfargument name="default" type="boolean" required="no" default="false">
	<cfset var request_obj = service("request")>
	<cfset var input = "">
	<cfset var sessionObj = "">
	<cfset var hasOldInput = false>
	<cfset var post = "">
	<cfset var i = 0>

	<!--- Try any old input data we may have first --->
	<cfset input = request_obj.getOldInput(arguments.field)>

	<cfif is_null(input)>
		<cfset input = request_obj.getPost(arguments.field)>
	</cfif>

	<cfif is_array(input)>
		<!--- Note: in_array('', array(0)) returns TRUE, do not use it --->
		<cfif IsStruct(input)>
			<cfloop collection="#input#" item="i">
				<cfif IsSimpleValue(input[i]) AND Compare(arguments.value, input[i]) EQ 0>
					<cfreturn " checked=""checked""">
				</cfif>
			</cfloop>
		<cfelse>
			<cfloop from="1" to="#ArrayLen(input)#" index="i">
				<cfif IsSimpleValue(input[i]) AND Compare(arguments.value, input[i]) EQ 0>
					<cfreturn " checked=""checked""">
				</cfif>
			</cfloop>
		</cfif>

		<cfreturn "">
	</cfif>

	<cfset sessionObj = service("session")>
	<cfset hasOldInput = sessionObj.has("_ci_old_input")>
	<cfset post = request_obj.getPost()>

	<!--- Unchecked checkbox and radio inputs are not even submitted by browsers ... --->
	<cfif Compare(input, "0") EQ 0 OR (IsStruct(post) AND StructCount(post) GT 0) OR hasOldInput>
		<cfif NOT is_null(input) AND Compare(input, arguments.value) EQ 0>
			<cfreturn " checked=""checked""">
		</cfif>

		<cfreturn "">
	</cfif>

	<cfif arguments.default>
		<cfreturn " checked=""checked""">
	</cfif>

	<cfreturn "">
</cffunction>

<!---
 * Set Radio
 *
 * Let's you set the selected value of a radio field via info in the POST array.
--->
<cffunction name="set_radio" returntype="string" output="no" hint="Let's you set the selected value of a radio field via info in the POST array">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="value" type="string" required="no" default="">
	<cfargument name="default" type="boolean" required="no" default="false">
	<cfset var request_obj = service("request")>
	<cfset var oldInput = "">
	<cfset var postInput = "">
	<cfset var input = "">
	<cfset var i = 0>

	<!--- Try any old input data we may have first --->
	<cfset oldInput = request_obj.getOldInput(arguments.field)>

	<cfset postInput = request_obj.getPost(arguments.field)>

	<cfset input = oldInput>
	<cfif is_null(input)>
		<cfset input = postInput>
	</cfif>
	<cfif is_null(input)>
		<cfset input = arguments.default>
	</cfif>

	<cfif is_array(input)>
		<!--- Note: in_array('', array(0)) returns TRUE, do not use it --->
		<cfif IsStruct(input)>
			<cfloop collection="#input#" item="i">
				<cfif IsSimpleValue(input[i]) AND Compare(arguments.value, input[i]) EQ 0>
					<cfreturn " checked=""checked""">
				</cfif>
			</cfloop>
		<cfelse>
			<cfloop from="1" to="#ArrayLen(input)#" index="i">
				<cfif IsSimpleValue(input[i]) AND Compare(arguments.value, input[i]) EQ 0>
					<cfreturn " checked=""checked""">
				</cfif>
			</cfloop>
		</cfif>

		<cfreturn "">
	</cfif>

	<!--- Unchecked checkbox and radio inputs are not even submitted by browsers ... --->
	<cfif NOT is_null(oldInput) OR NOT is_null(postInput)>
		<cfif Compare(input, arguments.value) EQ 0>
			<cfreturn " checked=""checked""">
		</cfif>

		<cfreturn "">
	</cfif>

	<cfif arguments.default>
		<cfreturn " checked=""checked""">
	</cfif>

	<cfreturn "">
</cffunction>

<!---
 * Returns the validation errors.
 *
 * First, checks the validation errors that are stored in the session.
 * To store the errors in the session, you need to use `withInput()` with `redirect()`.
 *
 * The returned map should be in the following format:
 *     field1 => error message
 *     field2 => error message
 *
 * Not ported yet: is_cli(). The context is always web, so the errors of
 * the session are always used.
 *
 * @return A map of strings
--->
<cffunction name="validation_errors" returntype="any" output="no" hint="Returns the validation errors">
	<cfset var errors = session_("_ci_validation_errors")>
	<cfset var validation = "">

	<!---
	 Check the session to see if any were
	 passed along from a redirect withErrors() request.
	--->
	<cfif NOT is_null(errors)>
		<cfreturn errors>
	</cfif>

	<cfset validation = service("validation")>

	<cfreturn validation.getErrors()>
</cffunction>

<!---
 * Returns the rendered HTML of the validation errors.
 *
 * See Validation::listErrors()
--->
<cffunction name="validation_list_errors" returntype="string" output="no" hint="Returns the rendered HTML of the validation errors">
	<cfargument name="template" type="string" required="no" default="list">
	<cfset var validationConfig = config("Config\Validation")>
	<cfset var renderer = service("renderer")>

	<cfif NOT array_key_exists(arguments.template, validationConfig.templates)>
		<cfset static_("ColdIgniter\Validation\Exceptions\ValidationException").forInvalidTemplate(arguments.template)>
	</cfif>

	<cfreturn renderer.setVar("errors", validation_errors()).render(validationConfig.templates[arguments.template])>
</cffunction>

<!---
 * Returns a single error for the specified field in formatted HTML.
 *
 * See Validation::showError()
 *
 * Differs from the original: the keys are compared with a pattern that
 * ends in \z (a true end), and the pattern is run through preg_match(),
 * so a key longer than the limit of regex_guard_() is refused.
--->
<cffunction name="validation_show_error" returntype="string" output="no" hint="Returns a single error for the specified field in formatted HTML">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="template" type="string" required="no" default="single">
	<cfset var validationConfig = config("Config\Validation")>
	<cfset var renderer = service("renderer")>
	<cfset var allErrors = validation_errors()>
	<cfset var errors = ArrayNew(1)>
	<cfset var search = ArrayNew(1)>
	<cfset var replace = ArrayNew(1)>
	<cfset var pattern = "">
	<cfset var keys = array_keys(allErrors)>
	<cfset var i = 0>

	<cfset ArrayAppend(search, "\.\*")>
	<cfset ArrayAppend(search, "\*\.")>
	<cfset ArrayAppend(replace, "\..+")>
	<cfset ArrayAppend(replace, ".+\.")>

	<cfset pattern = "/^" & str_replace(search, replace, preg_quote(arguments.field)) & "\z/">

	<cfloop from="1" to="#ArrayLen(keys)#" index="i">
		<cfif preg_match(pattern, keys[i]) EQ 1>
			<cfset ArrayAppend(errors, allErrors[keys[i]])>
		</cfif>
	</cfloop>

	<cfif ArrayLen(errors) EQ 0>
		<cfreturn "">
	</cfif>

	<cfif NOT array_key_exists(arguments.template, validationConfig.templates)>
		<cfset static_("ColdIgniter\Validation\Exceptions\ValidationException").forInvalidTemplate(arguments.template)>
	</cfif>

	<cfreturn renderer.setVar("error", implode(Chr(10), errors)).render(validationConfig.templates[arguments.template])>
</cffunction>

<!---
 * Parse the form attributes
 *
 * Helper function used by some of the form helpers
 *
 * @internal
 *
 * @param attributes List of attributes (a map, or a string that is ignored)
 * @param default    Default values (a map)
--->
<cffunction name="parse_form_attributes" returntype="string" output="no" hint="Parse the form attributes">
	<cfargument name="attributes" type="any" required="yes">
	<cfargument name="default" type="any" required="yes">
	<cfset var defaults = array_merge(arguments.default)>
	<cfset var attrs = "">
	<cfset var keys = "">
	<cfset var lastKey = "">
	<cfset var att = "">
	<cfset var key = "">
	<cfset var val = "">
	<cfset var skip = false>
	<cfset var i = 0>

	<cfif IsStruct(arguments.attributes)>
		<cfset attrs = array_merge(arguments.attributes)>
		<cfset keys = array_keys(defaults)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset key = keys[i]>
			<cfif StructKeyExists(attrs, key)>
				<cfset defaults[key] = attrs[key]>
				<cfset attrs.remove(JavaCast("string", key))>
			</cfif>
		</cfloop>
		<cfif StructCount(attrs) GT 0>
			<cfset defaults = array_merge(defaults, attrs)>
		</cfif>
	</cfif>

	<cfset keys = array_keys(defaults)>
	<cfif ArrayLen(keys) GT 0>
		<cfset lastKey = keys[ArrayLen(keys)]>
	</cfif>

	<cfloop from="1" to="#ArrayLen(keys)#" index="i">
		<cfset key = keys[i]>
		<cfset val = defaults[key]>
		<cfset skip = false>

		<cfif NOT is_bool(val)>
			<cfif Compare(key, "value") EQ 0>
				<cfset val = esc(val)>
			<cfelseif Compare(key, "name") EQ 0 AND Compare(defaults["name"], "") EQ 0>
				<!--- continue --->
				<cfset skip = true>
			</cfif>

			<cfif NOT skip>
				<cfif Compare(key, lastKey) EQ 0>
					<cfset att = att & key & "=""" & val & """">
				<cfelse>
					<cfset att = att & key & "=""" & val & """ ">
				</cfif>
			</cfif>
		<cfelse>
			<cfset att = att & key & " ">
		</cfif>
	</cfloop>

	<cfreturn att>
</cffunction>
