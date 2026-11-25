<!---
 * Encryption language settings
 *
 * A language file is included by the Language component, and has to
 * set the variable "lines" to a map (see array_()); that stands in for
 * the "return [...]" of the original. The keys keep their order.
--->
<cfset lines = array_()>

<cfset lines["noDriverRequested"] = "No driver requested; Miss Daisy will be so upset!">
<cfset lines["noHandlerAvailable"] = "Unable to find an available ""{0}"" encryption handler.">
<cfset lines["unKnownHandler"] = """{0}"" cannot be configured.">
<cfset lines["starterKeyNeeded"] = "Encrypter needs a starter key.">
<cfset lines["authenticationFailed"] = "Decrypting: authentication failed.">
<cfset lines["encryptionFailed"] = "Encryption failed.">

<!--- Difference: not in the original, see EncryptionException.forUnlimitedStrengthNeeded() --->
<cfset lines["unlimitedStrengthNeeded"] = "The cipher ""{0}"" needs a key longer than 128 bits, and this JVM lacks the unlimited-strength policy files. Use a 128 bit cipher such as AES-128-CTR.">
