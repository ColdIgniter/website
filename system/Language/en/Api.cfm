<!---
 * API language settings
 *
 * A language file is included by the Language component, and has to
 * set the variable "lines" to a map (see array_()); that stands in for
 * the "return [...]" of the original. The keys keep their order.
--->
<cfset lines = array_()>

<cfset lines["invalidFields"] = "Invalid field requested: {0}">
<cfset lines["invalidIncludes"] = "Invalid include requested: {0}">
<cfset lines["missingInclude"] = "Missing include method for: {0}">
<cfset lines["transformerNotFound"] = "Transformer class '{0}' not found.">
<cfset lines["invalidTransformer"] = "Transformer class '{0}' must implement TransformerInterface.">
