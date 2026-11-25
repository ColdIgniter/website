<!---
 * Cast language settings
 *
 * A language file is included by the Language component, and has to
 * set the variable "lines" to a map (see array_()); that stands in for
 * the "return [...]" of the original. The keys keep their order.
--->
<cfset lines = array_()>

<cfset lines["baseCastMissing"] = """{0}"" class must inherit the ""ColdIgniter\Entity\Cast\BaseCast"" class.">
<cfset lines["enumInvalidCaseName"] = "Invalid case name ""{0}"" for enum ""{1}"".">
<cfset lines["enumInvalidType"] = "Expected enum of type ""{1}"", but received ""{0}"".">
<cfset lines["enumInvalidValue"] = "Invalid value ""{1}"" for enum ""{0}"".">
<cfset lines["enumMissingClass"] = "Enum class must be specified for enum casting.">
<cfset lines["enumNotEnum"] = "The ""{0}"" is not a valid enum class.">
<cfset lines["invalidCastMethod"] = "The ""{0}"" is invalid cast method, valid methods are: [""get"", ""set""].">
<cfset lines["invalidTimestamp"] = "Type casting ""timestamp"" expects a correct timestamp.">
<cfset lines["jsonErrorCtrlChar"] = "Unexpected control character found.">
<cfset lines["jsonErrorDepth"] = "Maximum stack depth exceeded.">
<cfset lines["jsonErrorStateMismatch"] = "Underflow or the modes mismatch.">
<cfset lines["jsonErrorSyntax"] = "Syntax error, malformed JSON.">
<cfset lines["jsonErrorUnknown"] = "Unknown error.">
<cfset lines["jsonErrorUtf8"] = "Malformed UTF-8 characters, possibly incorrectly encoded.">
