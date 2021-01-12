Include Anonymizer.Web.Helper

Class Anonymizer.Web.Loader
{

ClassMethod CheckColumns(filename As %String = "", ByRef sc As %Status) As %DynamicObject
{
    set response = {}
    set response.status = $$$OK
    set response.filepath = filename
    try {
        set file = ##class(%File).%New(filename)
        do file.Open("RS")
        set header = $ZCONVERT(file.ReadLine(),"I","UTF8")
        kill file
        set ^zrenan = header
        set headerList = $$CSVtoList^%occLibrary(header)

        set col = ""
        set it = 0
        set cols = []
        while $listnext(headerList,it,col) {      
            do cols.%Push(col)
        }
        set response.columns = cols
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus)
    }
    set response.status = sc
    return response
}

ClassMethod AnonymizeStart(filename As %String = "", ignore As %String = "") As %String
{
    set response = {}
    set response.status = $$$OK
    set sc = $$$OK
    try {
        set ignore = $replace(ignore,"[",",")
        set ignore = $replace(ignore,"]",",")
        kill ^AnonymizerCtrl($job)
        set ^AnonymizerCtrl($job) = 0
        set response.job = $job
        set response.total = $$$GetFileSize(filename)

        job ##class(Anonymizer.Web.Loader).AnonymizeJob(filename,ignore,$job)
    } catch (err) {
        set sc = $$$ADDSC(sc,err.AsStatus)
    }
    set response.status = sc
    return response.%ToJSON()
}

ClassMethod AnonymizeJob(filename As %String = "", ignore As %String = "", job As %Integer)
{
    try {
        set name = $piece(filename,$$$OSDelimiter,*)
        set anonfile = $replace(filename,name,"anonymous-"_name)
        set anon = ##class(%File).%New(anonfile)
        do anon.Open("WNS")
        set file = ##class(%File).%New(filename)
        do file.Open("RS")
        set header = 1
        while 'file.AtEnd {
            set line = $ZCONVERT(file.ReadLine(),"I","UTF8")
            set lineList = $$CSVtoList^%occLibrary(line)
            set it = 0
            set value = ""
            set pos = 0
            set newLineList = "" 
            while $listnext(lineList,it,value) {
                set pos = $increment(pos) 
                if ignore[$$$FormatText(",""%1"",",pos) {
                    set newValue = value
                } else {
                    set newValue = ..Randomize(value)
                }
                if newValue["," set newValue = """"_newValue_""""
                set newLineList = $listupdate(newLineList,pos,newValue)
            }
            if header {
                do anon.WriteLine(line)
                set header = 0
            } else {
                do anon.WriteLine($listtostring(newLineList,","))
            }
            set ^AnonymizerCtrl(job) = $increment(AnonymizerCtrl(job))
        }
        kill anon
        kill file
        do ##class(%File).Delete(filename)
        set ^AnonymizerCtrl(job,"file") = anonfile
 } catch (err) {
        set ^AnonymizerCtrl(job) = -1
    }
}

ClassMethod Randomize(string As %String) As %String
{
    set response = ""
    try {
        for pos=1:1:$length(string) {
            set char = $extract(string,pos)
            set ascii = $ascii(char)
            if ((ascii>=32)&&(ascii<=126)) {            // latin
                if ((ascii>=48)&&(ascii<=57)) {         //  - number
                    do { set newAscii = $random(9)+48 } while (newAscii=char)
                } elseif (((ascii>=65)&&(ascii<=90))||((ascii>=97)&&(ascii<=122))) {   //  - letter (uppercase and lowercase)
                    kill newAscii
                    do { set newAscii(0) = $random(25)+65 } while (newAscii(0)=char)
                    do { set newAscii(1) = $random(25)+97 } while (newAscii(1)=char)
                    set newAscii = newAscii($random(2))
                } else {                                //  - symbols
                    kill newAscii
                    do { set newAscii(0) = $random(15)+32 } while (newAscii(0)=char)
                    do { set newAscii(1) = $random(6)+58 } while (newAscii(1)=char)
                    do { set newAscii(2) = $random(6)+91 } while (newAscii(2)=char)
                    do { set newAscii(3) = $random(4)+123 } while (newAscii(3)=char)
                    set newAscii = newAscii($random(4))
                }
            } elseif ((ascii>=1537)&&(ascii<=1791)) {   // arabic
                do { set newAscii = $random(254)+1537 } while (newAscii=char)
            } else {
                set newAscii = $ascii("*")
            }
            set response = response_$char(newAscii)
        }
    } catch (err) {
        set response = "ERROR: "_$System.Status.GetErrorText(err.AsStatus())
    }
    return response
}

ClassMethod CheckProgress(job As %Integer) As %Integer
{
    return +$get(^AnonymizerCtrl(job))
}

ClassMethod GetFile(job As %Integer) As %String
{
    return $get(^AnonymizerCtrl(job,"file"))
}

ClassMethod GetFileSize(filename As %String = "") As %Integer
{
    set size = 0
    try {
        set rt = $$$RunOSCommand($$$FormatText("grep """" -c %1",$replace(filename," ","\ ")),1)
        open $$$TempFile:"RS":5
        use $$$TempFile
        try { for i=1:1:100000 { read size quit:size'="" } } catch {}
		close $$$TempFile
		$$$DeleteTempFile
        set size = size-1
    } catch {
        set size = -1
    }
    return size
}

}
