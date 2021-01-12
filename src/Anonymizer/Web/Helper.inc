ROUTINE Anonymizer.Web.Helper [Type=INC]
#define GenericTempFile					$classname()_"."_$job_".env"
#define TempFile						$$$TempDir_$$$GenericTempFile
#define TempDir							##class(%SYS.System).TempDirectory()_$$$OSDelimiter
#define OSType							$select($$$isWINDOWS:"Windows",$$$isMACOSX:"macOS",$$$isUNIX:"Unix",1:"")
#define OSDelimiter						$select($$$OSType="Windows":"\",1:"/")
#define RunOSCommand(%command,%ver)		$select($select(%ver=1:$zf(-1,%command_" > "_$$$TempFile),1:$zf(-1,%command))=0:$$$OK,1:$$$ImpossibleToRunOSCommand(%command))
#define GetFileSize(%filename)          ##class(Anonymizer.Web.Loader).GetFileSize(%filename)
#define ImpossibleToRunOSCommand(%cmd)	$$$ERROR($$$GeneralError,$$$FormatText("Impossible to run OS command '%1'.",%cmd))
#define DeleteTempFile					do ##class(%File).Delete($$$TempFile)