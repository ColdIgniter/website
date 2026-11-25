<!---
 * Validation language settings
 *
 * A language file is included by the Language component, and has to
 * set the variable "lines" to a map (see array_()); that stands in for
 * the "return [...]" of the original. The keys keep their order.
--->
<cfset lines = array_()>

<!--- Core Messages --->
<cfset lines["noRuleSets"] = "No rule sets specified in Validation configuration.">
<cfset lines["ruleNotFound"] = """{0}"" is not a valid rule.">
<cfset lines["groupNotFound"] = """{0}"" is not a validation rules group.">
<cfset lines["groupNotArray"] = """{0}"" rule group must be an array.">
<cfset lines["invalidTemplate"] = """{0}"" is not a valid Validation template.">

<!--- Rule Messages --->
<cfset lines["alpha"] = "The {field} field may only contain alphabetical characters.">
<cfset lines["alpha_dash"] = "The {field} field may only contain alphanumeric, underscore, and dash characters.">
<cfset lines["alpha_numeric"] = "The {field} field may only contain alphanumeric characters.">
<cfset lines["alpha_numeric_punct"] = "The {field} field may contain only alphanumeric characters, spaces, and  ~ ! ## $ % & * - _ + = | : . characters.">
<cfset lines["alpha_numeric_space"] = "The {field} field may only contain alphanumeric and space characters.">
<cfset lines["alpha_space"] = "The {field} field may only contain alphabetical characters and spaces.">
<cfset lines["decimal"] = "The {field} field must contain a decimal number.">
<cfset lines["differs"] = "The {field} field must differ from the {param} field.">
<cfset lines["equals"] = "The {field} field must be exactly: {param}.">
<cfset lines["exact_length"] = "The {field} field must be exactly {param} characters in length.">
<cfset lines["field_exists"] = "The {field} field must exist.">
<cfset lines["greater_than"] = "The {field} field must contain a number greater than {param}.">
<cfset lines["greater_than_equal_to"] = "The {field} field must contain a number greater than or equal to {param}.">
<cfset lines["hex"] = "The {field} field may only contain hexadecimal characters.">
<cfset lines["in_list"] = "The {field} field must be one of: {param}.">
<cfset lines["integer"] = "The {field} field must contain an integer.">
<cfset lines["is_natural"] = "The {field} field must only contain digits.">
<cfset lines["is_natural_no_zero"] = "The {field} field must only contain digits and must be greater than zero.">
<cfset lines["is_not_unique"] = "The {field} field must contain a previously existing value in the database.">
<cfset lines["is_unique"] = "The {field} field must contain a unique value.">
<cfset lines["less_than"] = "The {field} field must contain a number less than {param}.">
<cfset lines["less_than_equal_to"] = "The {field} field must contain a number less than or equal to {param}.">
<cfset lines["matches"] = "The {field} field does not match the {param} field.">
<cfset lines["max_length"] = "The {field} field cannot exceed {param} characters in length.">
<cfset lines["min_length"] = "The {field} field must be at least {param} characters in length.">
<cfset lines["not_equals"] = "The {field} field cannot be: {param}.">
<cfset lines["not_in_list"] = "The {field} field must not be one of: {param}.">
<cfset lines["numeric"] = "The {field} field must contain only numbers.">
<cfset lines["regex_match"] = "The {field} field is not in the correct format.">
<cfset lines["required"] = "The {field} field is required.">
<cfset lines["required_with"] = "The {field} field is required when {param} is present.">
<cfset lines["required_without"] = "The {field} field is required when {param} is not present.">
<cfset lines["string"] = "The {field} field must be a valid string.">
<cfset lines["timezone"] = "The {field} field must be a valid timezone.">
<cfset lines["valid_base64"] = "The {field} field must be a valid base64 string.">
<cfset lines["valid_email"] = "The {field} field must contain a valid email address.">
<cfset lines["valid_emails"] = "The {field} field must contain all valid email addresses.">
<cfset lines["valid_ip"] = "The {field} field must contain a valid IP.">
<cfset lines["valid_url"] = "The {field} field must contain a valid URL.">
<cfset lines["valid_url_strict"] = "The {field} field must contain a valid URL.">
<cfset lines["valid_date"] = "The {field} field must contain a valid date.">
<cfset lines["valid_json"] = "The {field} field must contain a valid json.">

<!--- Credit Cards --->
<cfset lines["valid_cc_number"] = "{field} does not appear to be a valid credit card number.">

<!--- Files --->
<cfset lines["uploaded"] = "{field} is not a valid uploaded file.">
<cfset lines["max_size"] = "{field} is too large of a file.">
<cfset lines["is_image"] = "{field} is not a valid, uploaded image file.">
<cfset lines["mime_in"] = "{field} does not have a valid mime type.">
<cfset lines["ext_in"] = "{field} does not have a valid file extension.">
<cfset lines["max_dims"] = "{field} is either not an image, or it is too wide or tall.">
<cfset lines["min_dims"] = "{field} is either not an image, or it is not wide or tall enough.">
