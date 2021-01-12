Class Anonymizer.Web.Application Extends %CSP.Page
{

ClassMethod OnPage() As %Status
{
	&html<<!DOCTYPE html>
    <html lang="en" >
    <head>
    #(..HyperEventHead())# 
    <link rel="icon" href="https://www.intersystems.com/wp-content/uploads/2017/04/cropped-intersystems_favicon-100x100.png" sizes="32x32">
    <meta charset="UTF-8">
    <title>CSV Anonymizer</title>
    <style>
        body {
            background-color: rgba(0, 0, 0, 0.78);
            color: white;
            font-family: Arial;
        }
        a {
            color: #369;
        }
        .note {
            width: 500px;
            margin: 50px auto;
            font-size: 1.1em;
            color: #333;
            text-align: justify;
        }
        #drop-area, #text-area {
            border: 2px solid #ccc;
            border-radius: 20px;
            width: 480px;
            margin: 50px auto;
            padding: 20px;
        }
        #drop-area.highlight{
            border-color: #520505;
            background-color: rgb(85, 71, 71);
        }
        p {
            margin-top: 0;
        }
        .my-form {
            margin-bottom: 10px;
        }
        .button {
            display: inline-block;
            padding: 10px;
            background: #520505;
            cursor: pointer;
            border-radius: 5px;
            border: 1px solid #520505;
        }
        .button:hover {
            background: #670e0e;
        }
        #fileElem, #text-area, #anonymize, #reset, #file-path, #ig2, #anonymizing, #progress-bar, #btnDownload, #download, #download-frame {
            display: none;
        }
        form {
            text-align: center;
        }
        .cols:hover {
            background-color: #736e6d;
            border-radius: 20px;
        }
    </style>
    </head>
    <body translate="no" >
        <center><h1>CSV Anonymizer</h1></center>
        <div id="drop-area">
            <center><svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" viewBox="0 0 512 512"><path fill="#057212" d="M307.2 197.4h124.4V439c0 12.1-9.8 22-22 22H102.3c-12.1 0-22-9.8-22-22V73c0-12.1 9.8-22 22-22h183v124.4c0 12.2 9.8 22 21.9 22zm7.4-137.2c3.2 2.1 5.9 4.1 8.2 6.4l93.3 93.3c2.3 2.3 4.3 5 6.4 8.2h-108V60.2z"/><text transform="translate(121.053 364.272)" fill="#FFF" font-family="'Arial'" font-size="134.063">CSV</text></svg></center>
            <form class="my-form">
                <progress id="progress-bar" max=100 value=0></progress>
                <br/><br/>
                <p id="selText">Drag your CSV file for anonymization</p>
                <input type="file" id="fileElem" multiple="false" accept="text/csv" onchange="handleFiles(this.files)">
                <label class="button" for="fileElem" id="selFile">Select file</label>
            </form>
        </div>
        <div id="text-area" class="highlight">
            <div id="anonymizing" syle="margin-bottom: 20px;">
                <center>
                <div id="msg">Anonymizing</div>
                <progress id="anonymizing-bar" max=100 value=0></progress>
                </center>
            </div>
            <div>
                <div style="float: left;width: 50%;"><b>Column</b></div>
                <div id="ig1"><b>Ignore?</b></div>
                <div id="ig2"><b>Ignored</b></div>
            </div>
            <div id="content"></div>
            <div style="padding-top:20px;">
                <input type="input" id="file-path">
                <input type="button" id="download">
                <input type="button" id="anonymize" onclick="anonymize()">
                <input type="button" id="reset" onclick="location.reload();">
                <center>
                    <label class="button" for="download" id="btnDownload">Download</label>
                    <label class="button" for="anonymize" id="btnAnonymize">Anonymize</label>
                    <label class="button" for="reset" style="margin-left:10px;" id="btnReset">Reset</label>
                </center>
            </div>
        </div>
        <center>Powered by <a href="https://www.intersystems.com/products/intersystems-iris" target="_blank">InterSystems IRIS®</center>
        <iframe id="download-frame"></iframe>
        <script>
            // ************************ Drag and drop ***************** //
            let dropArea = document.getElementById("drop-area")

            // Prevent default drag behaviors
            ;['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
                dropArea.addEventListener(eventName, preventDefaults, false);
                document.body.addEventListener(eventName, preventDefaults, false);
            })

            // Highlight drop area when item is dragged over it
            ;['dragenter', 'dragover'].forEach(eventName => {
                dropArea.addEventListener(eventName, highlight, false);
            });

            ['dragleave', 'drop'].forEach(eventName => {
                dropArea.addEventListener(eventName, unhighlight, false);
            });

            // Handle dropped files
            dropArea.addEventListener('drop', handleDrop, false);

            function preventDefaults(e) {
                e.preventDefault();
                e.stopPropagation();
            }

            function highlight(e) {
                dropArea.classList.add('highlight');
            }

            function unhighlight(e) {
                dropArea.classList.remove('highlight');
            }

            function handleDrop(e) {
                var dt = e.dataTransfer;
                var files = dt.files;

                handleFiles(files);
            }

            let uploadProgress = [];
            let progressBar = document.getElementById('progress-bar');
            let anonymizingBar = document.getElementById("anonymizing-bar"); 

            function initializeProgress(numFiles) {
                progressBar.value = 0;
                uploadProgress = [];

                for (let i = numFiles; i > 0; i--) {
                    uploadProgress.push(0);
                }
            }

            function updateProgress(fileNumber, percent) {
                uploadProgress[fileNumber] = percent;
                let total = uploadProgress.reduce((tot, curr) => tot + curr, 0) / uploadProgress.length;
                //console.debug('update', fileNumber, percent, total);
                progressBar.value = total;
            }

            function handleFiles(files) {
                files = [...files];
                initializeProgress(files.length);
                files.forEach(uploadFile);
            }

            function uploadFile(file, i) {
                var filename = file.name;
                filename = filename.split(".");
                if (filename[filename.length-1]!="csv") {
                    alert(file.name+" has an unsupported file format.");
                    return false;
                }
                var url = 'Anonymizer.Web.Upload.zen';
                var xhr = new XMLHttpRequest();
                xhr.responseType = 'json';
                var formData = new FormData();
                xhr.open('POST', url, true);
                xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');

                // Update progress (can be used to show progress indicator)
                xhr.upload.addEventListener("progress", function (e) {
                    updateProgress(i, e.loaded * 100.0 / e.total || 100);
                });

                xhr.addEventListener('readystatechange', function (e) {
                    if (xhr.readyState == 4 && xhr.status == 200) {
                        updateProgress(i, 100); // <- Add this
                        var response = xhr.response;
                        if (response.status!=1) {
                            alert(response.errorMessage);
                            return false;
                        } else {
                            var div = document.getElementById("content");
                            for (var key in response.callbackResponse.columns) {
                                var col = response.callbackResponse.columns[key];
                                var id = parseInt(key)+1;
                                var item = "<div class='cols' style='padding-top:3px;'><div style='float: left;width: 50%; margin-left: 10px;'><label>"+col+"</label></div><div><input type='checkbox' id='idz"+id+"' name='columns' value='"+id+"'/></div></div>";
                                div.innerHTML += item;
                            }   
                            document.getElementById("file-path").value = response.callbackResponse.filepath;                       
                            document.getElementById("drop-area").style.display = "none";
                            document.getElementById("text-area").style.display = "block";
                        }
                    } else
                    if (xhr.readyState == 4 && xhr.status != 200) {
                    // Error. Inform the user
                    }
                });
                formData.append("ATT",file,file.name);
                formData.append("filename",file.name);

                // define callback
                formData.append("callback",1);
                formData.append("class","Anonymizer.Web.Loader");
                formData.append("method","CheckColumns");

                xhr.send(formData);
                document.getElementById("progress-bar").style.display = "inline";
                document.getElementById("selText").style.display = "none";
                document.getElementById("selFile").style.display = "none";
            }

            function anonymize() {
                try {
                    const checkboxes = document.querySelectorAll('input[name="columns"]');
                    let columns = [];
                    checkboxes.forEach((checkbox) => {
                        if (checkbox.checked) {
                            columns.push(checkbox.value);
                            checkbox.disabled = true;
                        } else {
                            checkbox.parentElement.parentElement.style.display = "none";
                        }
                    });
                    if (columns.length>0) {
                        document.getElementById("ig1").style.display = "none";
                        document.getElementById("ig2").style.display = "block";
                    } else {
                        document.getElementById("ig1").parentElement.style.display = "none";
                    }
                    document.getElementById("anonymizing").style.display = "block";
                    var filepath = document.getElementById("file-path").value;
                    var response = JSON.parse(#server(Anonymizer.Web.Loader.AnonymizeStart(filepath,JSON.stringify(columns)))#);
                    anonymizingBar.max = response.total;
                    setTimeout(function(){check(response.job,response.total)},500);
                    document.getElementById("btnAnonymize").style.display = "none";
                    document.getElementById("btnReset").style.display = "none";
                    return;
                } catch (err) {
                    console.log(err);
                }
                return
            }

            function check(job,total) {
                try {
                    var current = #server(Anonymizer.Web.Loader.CheckProgress(job))#
                    anonymizingBar.value = current;
                    if (current==-1) {
                        alert("Impossible to anomymize.");
                        document.getElementById("btnReset").style.display = "inline";
                    } else
                    if (current<total) {
                        setTimeout(function(){check(job,total)},500);
                    } else {
                        document.getElementById("download").onclick = (function(){
                            var file = #server(Anonymizer.Web.Loader.GetFile(job))#;
                            document.getElementById("download-frame").setAttribute('src', "Anonymizer.Web.Download.zen?file="+file+"&delete=1");
                        });
                        document.getElementById("btnDownload").style.display = "inline";
                        document.getElementById("btnReset").style.display = "inline";
                        document.getElementById("msg").innerText = "Done!";
                    }
                } catch (err) {
                    console.log(err);
                }
                return
            }
        </script>
    </body>
    </html>>
    quit $$$OK
}

}
