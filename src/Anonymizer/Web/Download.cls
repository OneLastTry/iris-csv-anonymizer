Include Anonymizer.Web.Helper

Class Anonymizer.Web.Download Extends %CSP.Page
{

ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	set %response.Expires=""
	set %response.ContentType="application/octet-stream;"
	do %response.SetHeader("Content-Disposition","attachment;filename="_$piece($get(%request.Data("file",1)),$$$OSDelimiter,*))
	quit $$$OK
}

ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	set sc = $$$OK
	try {
		set filepath = $get(%request.Data("file",1))		
		set file = ##class(%File).%New(filepath)	
		set sc = $$$ADDSC(sc,file.Open("RUK\BIN\"))
		do file.OutputToDevice()
		kill file
		if ($get(%request.Data("delete",1))=1) set sc = ##class(%File).Delete(filepath,.ret)
	} catch (err) {
		set sc = $$$ADDSC(sc,err.AsStatus())
	}
	return sc
}

}
