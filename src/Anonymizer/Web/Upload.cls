Class Anonymizer.Web.Upload Extends %CSP.Page
{

Parameter PATH As STRING = "/tmp";

Parameter Supported As STRING = {$listbuild($listbuild("*","csv"))};

ClassMethod OnPage() As %Status
{
	set sc = $$$OK
	set response = {"status":1}
	try {
		set filename = $get(%request.Data("filename",1))
		#; check supported files
		set supported = 0	
		set it = 0
		set kind = ""
		while $listnext(..#Supported,it,kind) {
			set type = $listget(kind,1)
			set ext = $listget(kind,2)
			if ((($find(filename,type))||(type="*"))&&($find(filename,ext))) set supported = 1
		}
		if 'supported {
			set sc = $$$ERROR($$$GeneralError,"File type or extension not supported.")
			quit
		}
		
		#; save file
		set delim = $select($length(..#PATH,"/")>1:"/",1:"\")
		set file = ..#PATH_delim_filename
		set mime = %request.GetMimeData("ATT","",1)
		set att = ##class(%File).%New(file)
		set sc = $$$ADDSC(sc,att.Open("WNS"))
		set sc = $$$ADDSC(sc,att.CopyFrom(mime))
		do att.%Save()
		kill att
		#; callback server side
		#; - the method must receive filepath as parameter and status as reference 
		#; - the method must return a %DynamicObject
		if $get(%request.Data("callback",1))=1 {
			set class = $get(%request.Data("class",1))
			set method = $get(%request.Data("method",1))
			quit:class=""
			quit:method=""
			set callbackResponse = $$$ADDSC(sc,$classmethod(class,method,file,.sc))
			do response.%Set("callbackResponse",callbackResponse) 
		}
	} catch (err) {
		set sc = $$$ADDSC(sc,err.AsStatus())
	}
	if $$$ISERR(sc) {
		do response.%Set("status",0)
		do $System.Status.DecomposeStatus(sc,.errorList)
		set errors = []
		set errorMessage = "Impossible to upload."_$char(13)
		for i=1:1:errorList {
			set error = {}
			do error.%Set("code",errorList(i,"code"))
			do error.%Set("message",$piece(errorList(i),": ",2,*))
			do errors.%Push(error)
			set errorMessage = errorMessage_$char(13)_"- "_error.%Get("message")
		}
		do response.%Set("error",errors)
		do response.%Set("errorMessage",errorMessage)
	}
	do response.%ToJSON()
	return $$$OK
}

}
