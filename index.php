<?php
  //Getting of the file sent by the user,
  // launch the perl script to compute and create the Excel file containing the results,
  // send the Excel file to the user  
  
  
  
  function generateRandomString($length = 10) {
      $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
      $charactersLength = strlen($characters);
      $randomString = '';
      for ($i = 0; $i < $length; $i++) {
	  $randomString .= $characters[rand(0, $charactersLength - 1)];
      }
      return $randomString;
  }

  
  $bool_ok=0;
  $filename="";
   if($_POST['action'] == 'in' && isset($_POST['txt']) && $_POST['txt'] != ""){
      $filename="dmcq.xlsx";
      $randomstring=generateRandomString();
      $file_upload='upload/'.$randomstring;
      $fichier=fopen($file_upload,'w+');
      $texte=$_POST['txt'];
      fwrite($fichier,$texte);
      fclose($fichier);
       $file_name = $randomstring;
      $bool_ok=1;
	  
   }
   if(isset($_POST['example']) || isset($_POST['template']) || isset($_POST['exampods']) || isset($_POST['exampxlsx'])){
	if(isset($_POST['example'])){
	  $file="example.tsv";
	}
	else if(isset($_POST['template'])){
	  $file="template.tsv";
	}
	else if(isset($_POST['exampods'])){
	  $file="example.ods";
	}
	else if(isset($_POST['exampxlsx'])){
	  $file="example.xlsx";
	}	
	else{
	  exit;
	}
	$length   = sprintf("%u", filesize($file));
	$basename_file=basename($file);
	header('Content-Description: File Transfer');
	header('Content-Type: application/octet-stream');
	header('Content-Disposition: attachment; filename="' . $basename_file . '"');
	header('Content-Transfer-Encoding: binary');
	header('Connection: Keep-Alive');
	header('Expires: 0');
	header('Cache-Control: must-revalidate, post-check=0, pre-check=0');
	header('Pragma: public');
	header('Content-Length: ' . $length);
	set_time_limit(0);
	readfile($file);
   }
   else if($_POST['action'] == 'file' && isset($_FILES['qPCRfile']) && isset( $_FILES['qPCRfile']['name']) &&  $_FILES['qPCRfile']['name']!=""){
	  $file_name = $_FILES['qPCRfile']['name'];
	
	  $errors= array();
	
	  $explod=explode('.',$file_name);
	  $new_file_name="";
	  for ($i = 0; $i < (count($explod)-1); $i++) {
	      $new_file_name=$new_file_name.$explod[$i].'.';
	  }
	  substr($new_file_name, 0, -1);
	
	  if ($new_file_name == ""){
	    $new_file_name=$file_name;
	  }
	  $file_name=$new_file_name;
	  $file_name=preg_replace('/[^A-Za-z0-9\-]/', '', $file_name); // Removes special chars.

	  $file_size =$_FILES['qPCRfile']['size'];
	  $file_tmp =$_FILES['qPCRfile']['tmp_name'];
	  $file_type=$_FILES['qPCRfile']['type'];
	  $file_upload="upload/".$file_name;
	  $i=2;
	  $file_name_ori=$file_name;
	  $max_size=5000000;
	  $bool_ok=0;
	  if ($file_size>$max_size){
		print "file_size : ".$file_size." octets must be < max_size : ".$max_size." octets</br>";
		
	  }
	  while(file_exists($file_upload)){
	    $file_name=$file_name_ori."_".$i;
	    $file_upload="upload/".$file_name;
	    $i++;
	  }
      
	  if (!file_exists($file_upload)) {
	    move_uploaded_file($file_tmp,$file_upload);
	    $bool_ok=1;
	  }		  
	   
      }
      if ($bool_ok==1){
      //print $file_name;exit;
	    exec("perl qPCR_2_graph.pl $file_name");
	    $file="download/".$file_name."-dmqc.xlsx";
	    if (file_exists($file_upload)){
	      unlink($file_upload);
	    }
	    if (file_exists($file_upload.'.txt')){
	      unlink($file_upload.'.txt');
	    }
	    if (file_exists($file)) {
		  $length   = sprintf("%u", filesize($file));
		  if ($filename==""){
		    $filename=basename($file);
		  }
		  header('Content-Description: File Transfer');
		  header('Content-Type: application/octet-stream');
		  header('Content-Disposition: attachment; filename="' . $filename . '"');
		  header('Content-Transfer-Encoding: binary');
		  header('Connection: Keep-Alive');
		  header('Expires: 0');
		  header('Cache-Control: must-revalidate, post-check=0, pre-check=0');
		  header('Pragma: public');
		  header('Content-Length: ' . $length);
		  set_time_limit(0);
		  readfile($file);
		  unlink($file);

	    }
	    else{
		    echo "Failed";
	    }

      }
      else{
	$_POST = array();

?>
<html>
<head>
 <meta name="viewport" content="width=device-width, initial-scale=1">
<link href="./style.css" rel="stylesheet"/>
<script src="./jquery.min.js"></script>
 <script src="./jquery-csv-master/src/jquery.csv.js"></script>
  <script src="./jexcel-master/dist/js/jquery.jexcel.js"></script>
<link rel="stylesheet" href="./jexcel-master/dist/css/jquery.jexcel.css" type="text/css" />
</head>
<body>
  <div id='big_container'  style='transition:800ms ease all;border-bottom: 5px solid black;width:100%;min-width:400px;'>
  <div class="container" >
      <div style='  background-color:  #F78181' id="myBar0"><div id='a' style='transition:800ms ease all;background-color:red;font-size: 40px;;color:black'>Do</div></div>
      <div  style='background-color: #9FF781;left:25%'  id="myBar1"><div id='b' style='transition:800ms ease all;background-color:green;font-size: 40px;;color:black'>my</div></div>
      <div  style='background-color: #8181F7;left:50%'  id="myBar2"><div id='c' style='transition:800ms ease all;background-color:blue;font-size: 40px;;color:black'>qPCR</div></div>
      <div  style='background-color: #F3F781;left:75%'  id="myBar3"><div id='d' style='transition:800ms ease all;background-color:yellow;font-size: 20px;color:black'>calculations</div></div>
  </div>
  </div>

  <script>

  function move() {
    var nb=4;
    var i;
    var step=1;
     var height_final=[];
     var height=[];
     var min=45;
     var max_frame=100;
     var i_frame=0;
      var id = setInterval(frame, 35);
        for (i = 0; i < nb; i++) {
  	height_final[i]=Math.round(Math.random()*100);
  	if (height_final[i]<min){
  	  height_final[i]=min;
  	}
  	height[i]=min;
        }    
      function frame() {
        for (i = 0; i < nb; i++) {
  	var elem = document.getElementById("myBar"+i);     
  	if (height[i] < height_final[i]) {
  	  height[i]+=step; 
  	  elem.style.height = height[i] + 'px';
  	} else if (height[i] > height_final[i]) {
  	  height[i]-=step; 
  	  elem.style.height = height[i] + 'px'; 
  	}
  	else{
  	    height_final[i] = Math.round(Math.random()*100);
  	  if (height_final[i]<min){
  	    height_final[i]=min;
  	  }	    
  	}
        }
        i_frame++;
        if (i_frame==max_frame){
  	clearInterval(id);
  	var elem = document.getElementById("big_container");   
  	elem.style.background="black";
  	var elem = document.getElementById("a");   
  	elem.style.color="white";
  	var elem = document.getElementById("b");   
  	elem.style.color="white";
  	var elem = document.getElementById("c");   
  	elem.style.color="white";
  	var elem = document.getElementById("d");   
  	elem.style.color="black";	
        }
      }

  }
  move();


  </script>
  </br>
    "Do my qPCR calculation" can automatically process qPCR raw data (Cq) to get the data normalization and graphical representation of the different samples in an Excel file (readable via Microsoft Office, LibreOffice...). This tool is also available on Github for installation and local use with or without web interface at https://github.com/JeremyTournayre/do_my_qPCRcalc.
  <div class="maDiv">

    <form class="temp" action="" method="POST" enctype="multipart/form-data">
    <button style='padding:10px;' class="button" type="submit" id="template" name= "template">Template</button><span class="line-separator "></span ><button style='padding:10px;' class="button" type="submit" id="example" name= "example">Example.tsv</button>
    <button style='padding:10px;' class="button" type="submit" id="exampxlsx" name= "exampxlsx">Example.xlsx</button>
    <button style='padding:10px;' class="button" type="submit" id="exampods" name= "exampods">Example.ods</button><br><br>
  </form>
  <form class="temp" action="" method="POST" enctype="multipart/form-data">
<div class="form-group file-upload">
    
    <div class="cols-sm-9">
      <div class="input-group">
        
        <div class="form-control" data-message="Click to select file or drag and drop it here">
          <input  title="Click to select file or drag and drop it here" type="file" name="qPCRfile" id="document_file">
        </div>
        <button class="buttonred" type="submit" name="action" style='padding:10px;' value="file">Submit </br>file</button> 
      </div> 
    </div>    
  </div>
  </form> 
  </br>     
        <button class="buttonblue" name="action" style='padding:10px;' id="webform" name="webform" value="file">OR</br>Use the web form</button>

  

  </div>
</br>
  <div hidden id="webformdiv" name= "webformdiv"  >
  <div style="width:80%;margin:auto;padding-top:20px; border-bottom: 5px solid #000;"></div>
  <div class="maDivjexcel" >
  <form class="temp" action="" method="POST" enctype="multipart/form-data">
    Copy paste your data below and <button class="buttonblue" type="submit" id="submit" name="action" value="in" style='padding:10px;'>Submit table</button>
    
<button class='button' style="padding:10px" onclick="$('#my').jexcel('insertColumn'); event.preventDefault(); return false;">+ column</button >
<button class='button' style="padding:10px" onclick="$('#my').jexcel('insertRow'); event.preventDefault(); return false;">+ row</button >
  
<button class='button' style="padding:10px" onclick="loadtemplate();event.preventDefault(); return false;">Load template</button >
<button class='button' style="padding:10px" onclick="loadexample();event.preventDefault(); return false;">Load example</button >    
  </br>
    <div id="my"  class="jexcel" ></div>
    <textarea id='txt' name="txt" style='width:400px;height:120px;display:none;'></textarea>
  </form>
<script>



function loadtemplate() {
    $('#my').html("");
    $('#my').jexcel({
	csv:'./template.tsv',
	  csvHeaders:false,
	  separator:'\t',
	  delimiter:'\t',
	  colWidths: [150,200,200,200,100,100,100,100,100,100],
	  minDimensions:[10,5],
	  csvFileName:"dmcq.tsv",
	  style:[
	      { A1: 'font-weight: bold;background-color: orange; ' },
	      { B1: 'background-color: FFFDA5; ' },
	      { C1: 'font-weight: bold;background-color: orange; ' },
	      { D1: 'background-color: FFFDA5; ' },
	      { C2: 'background-color: FFFDA5; ' },
	      { D2: 'background-color: FFFDA5; ' },
	      { E2: 'background-color: FFFDA5; ' },
	      { A2: 'font-weight: bold;background-color: orange; ' },
	      { A3: 'font-weight: bold; background-color: orange; ' },
	      { B3: 'font-weight: bold; background-color: orange; ' }

	  ],
      });
}

function loadexample() {
   $('#my').html("");
    $('#my').jexcel({
      csv:'./example.tsv',
	csvHeaders:false,
	separator:'\t',
	delimiter:'\t',
	colWidths: [150,100,150,150,100,100,100,100,100,100],
	minDimensions:[10,5],
	csvFileName:"dmcq.tsv",
	style:[
	    { A1: 'font-weight: bold;background-color: orange; ' },
	    { B1: 'background-color: FFFDA5; ' },
	    { C1: 'font-weight: bold;background-color: orange; ' },
	    { D1: 'background-color: FFFDA5; ' },
	    { E2: 'background-color: FFFDA5; ' },
	    { A2: 'font-weight: bold;background-color: orange; ' },
	    { A3: 'font-weight: bold; background-color: orange; ' },
	    { B3: 'font-weight: bold; background-color: orange; ' }

	],
    });
}
loadexample();

$('#submit').on('click', function () {

  var data = $('#my').jexcel('getData');

  $('#txt').val($.csv.fromArrays(data,{separator:"\t",delimiter:"\t"}));
});
</script>
   
<p><button class="button" id='download'>Export this spreadsheet as TSV</button></p>

</div>
</div>
<script>
$('#download').on('click', function () {
    $('#my').jexcel('download');
});
</script>
    

    </form>
  </div>
   

  <script>
  $('#file-upload').change(function() {
    var i = $(this).prev('label').clone();
    var name=$('#file-upload')[0].files[0].name;
    if ( $('#file-upload')[0].files[0].name.length > 15){
      var res=name.split("");
      name="";
      for (i = 0; i < 11; i++) {
        name=name+res[i];
      }
      name=name+"...";
    }
    var file = name;
    $(this).prev('label').text(file);
  });
  </script>

  <div class="desc"  >
    <button style='padding:10px;' class='button' type="submit" id="help" name= "help">Description/Help</button>


    <button style='padding:10px;' class='button' type="submit" id="flowchart" name= "help">Flowchart/Methods</button></br>
  </div>
 
  <div hidden id="helpdiv" name= "helpdiv" >
    <div class="help">
    Description/Help)</br>
	  A) The input file has to be in .tsv, .xls, .xlsx. or .odt format. The first two lines are optional. The first defines the control group in B1 cell : the "A" group is choiced. The reference gene in D1 cell : the "RefGeneName" gene is selected. The second allows to define the qPCR efficiency for each gene written on the 3rd line. On the 3rd line there are 2 column headers : "Group" and "Sample" and then there are the genes: "RefGeneName", "TestGene1", "TestGene2". The other rows correspond to the data table : sample according to the Cq. Submitting this file to "do my qPCR calculation" allows you to obtain the result file in Excel format. B) The Excel file contains the normalized Cq for each sample with histograms. C) The Excel file also contains the average results and the student test for each experimental group between the control group.    
      <img class="center" src="img/help.jpg" > 
    </div>
  </div> 

   
 
  <div hidden id="flowchartdiv" name= "flowchartdiv" >
    <div class="flowchart">
      Flowchart/Methods)</br>
      <img class="center" src="img/pipeline.png" > 
    </div>
  </div>         
  <div style="padding-top:15px; border-bottom: 5px solid #000;"></div>
  <div style="margin: auto;width: 100%;text-align: center">
    
    Have a suggestion? <a href="mailto:jeremy.tournayre@inra.fr">Contact</a></br>
    This tool is developed and maintained by
    <a href="https://www6.clermont.inra.fr/unh_eng/Teams/PROSTEOSTASIS">Team Proteostasis</a><sup>1</sup> and
    <a href="http://147.99.156.182/Intranet/web/UMRH/en/show/30">Team PIGALE</a><sup>2</sup>
    <img src="img/logo_INRA.png" width="120" height="50"></br>
    </br>
    <sup>1</sup>Université Clermont Auvergne, INRA, UNH, Unité de Nutrition Humaine, CRNH Auvergne, Clermont-Ferrand, France</br>
    <sup>2</sup>Université Clermont Auvergne, VetAgro Sup, INRA, UMR1213, Unité Mixte de Recherche sur les Herbivores, Clermont-Ferrand, France

    
  </div>    
</body>
<script>
   
  $("#help").click(function(){
      $("#helpdiv").toggle( "slow" );
  });
     $("#flowchart").click(function(){
      $("#flowchartdiv").toggle( "slow" );
  });
</script>
  </br>
  <div class="desc" >
    <button style='padding:10px' class='button' type="submit" id="License" name= "License">License agreement</button></br>
  </div>
  <div hidden id="Licensediv" name= "Licensediv"  >
    <div class="License">
Do my qPCR calculations is distributed under <a href="https://www.gnu.org/copyleft/gpl.html">the GNU public license</a>
The source codes of Do my qPCR calculations will be freely available for non-commercial use on GitHub at <a href="https://github.com/JeremyTournayre/do_my_qPCRcalc">https://github.com/JeremyTournayre/do_my_qPCRcalc</a>, and are provided as-is without any warranty regarding reliability, accuracy and fitness for purpose. The user assumes the entire risk of the use of this program and the author can not be hold responsible of any kind of problems. 
    </div>  

    </div>
    <div style="padding-top:50px;">
   
    </div>    
<script>
   $("#webform").click(function(){
      $("#webformdiv").toggle( "slow" );
  });  
  $("#License").click(function(){
      $("#Licensediv").toggle( "slow" );
  });
    $('input[type="file"]').on('change', function(e){
    var fileName = e.target.files[0].name;
    if (fileName) {
      $(e.target).parent().attr('data-message', fileName);
    }
  });
  </script>
</html>
<?php
  }
?>