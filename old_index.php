<?php
  //Getting of the file sent by the user,
  // launch the perl script to compute and create the Excel file containing the results,
  // send the Excel file to the user  
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
   else if(isset($_FILES['qPCRfile']) && isset( $_FILES['qPCRfile']['name']) &&  $_FILES['qPCRfile']['name']!=""){

	  $errors= array();
	  
	  $file_name = $_FILES['qPCRfile']['name'];
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
	  // print $file_name;
	  $file_size =$_FILES['qPCRfile']['size'];
	  $file_tmp =$_FILES['qPCRfile']['tmp_name'];
	  $file_type=$_FILES['qPCRfile']['type'];
	  $file_upload="upload/".$file_name;
	  $i=2;
	  $file_name_ori=$file_name;
	  $max_size=5000000;
	  if ($file_size>$max_size){
	  	print "file_size : ".$file_size." octets must be < max_size : ".$max_size." octets</br>";
	  }
	  else{
		  while(file_exists($file_upload)){
		  	$file_name=$file_name_ori."_".$i;
		  	$file_upload="upload/".$file_name;
		  	$i++;
		  }
		  if (!file_exists($file_upload)) {
		      move_uploaded_file($file_tmp,$file_upload);
		      exec("perl qPCR_2_graph.pl $file_name");
		      $file="download/".$file_name."-dmqc.xlsx";
		      unlink($file_upload);
		      unlink($file_upload.'.txt');
			if (file_exists($file)) {
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
			    unlink($file);

				}
				else{
					echo "Failed";
				}
			}
		}
	}
 	else{


?>
<html>

<link href="./style.css" rel="stylesheet"/>

<body style='margin: 0 auto;'>
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

  <div class="maDiv">
    
    <form class="temp" action="" method="POST" enctype="multipart/form-data">
    <button style='padding:10px;' class="button" type="submit" id="template" name= "template">Template</button><span class="line-separator "></span ><button style='padding:10px;' class="button" type="submit" id="example" name= "example">Example.tsv</button>
    <button style='padding:10px;' class="button" type="submit" id="exampxlsx" name= "exampxlsx">Example.xlsx</button>
    <button style='padding:10px;' class="button" type="submit" id="exampods" name= "exampods">Example.ods</button><br><br><label class="myLabel buttonred" for="file-upload" style='font-size:20px;' >Input file (.tsv, .xlsx, .ods)</label><input id="file-upload" type="file" name="qPCRfile" style="display:none;"><span  class="line-separator "></span ><button class="buttonred" type="submit" style='padding:10px;font-size:20px'>Submit</button>

    </form>
  </div>
   
  <script src="jquery.min.js"></script>
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

  <div class="desc" style="  padding-top:40px;" >
    <button style='padding:10px;' class='button' type="submit" id="help" name= "help">Description/Help</button></br>
  </div>
   
 
  <div hidden id="helpdiv" name= "helpdiv" >
    <div class="help">
	  A) The input file has to be in .tsv, .xls, .xlsx. or .odt format. The first two lines are optional. The first defines the control group in B1 cell : the "A" group is choiced. The reference gene in D1 cell : the "RefGeneName" gene is selected. The second allows to define the qPCR efficiency for each gene written on the 3rd line. On the 3rd line there are 2 column headers : "Group" and "Sample" and then there are the genes: "RefGeneName", "TestGene1", "TestGene2". The other rows correspond to the data table : sample according to the Cq. Submitting this file to "do my qPCR calculation" allows you to obtain the result file in Excel format. B) The Excel file contains the normalized Cq for each sample with histograms. C) The Excel file also contains the average results and the student test for each experimental group between the control group.    
      <img class="center" src="img/help.jpg" > 
    </div>
  </div>      
  <div style="padding-top:75px; border-bottom: 5px solid #000;"></div>
  <div style="margin: auto;width: 50%;text-align: center">
    
    Have a suggestion? <a href="mailto:jeremy.tournayre@inra.fr">Contact</a></br>
    <img src="img/logo_INRA.png" width="120" height="50">
    <a href="https://www6.clermont.inra.fr/unh_eng/Teams/PROSTEOSTASIS">Team Proteostasis</a>
    <a href="http://147.99.156.182/Intranet/web/UMRH/en/show/30">Team PIGALE</a></br>
  </div>    
</body>
<script>
   
  $("#help").click(function(){
      $("#helpdiv").toggle( "slow" );
  });
   
</script>
  <div class="desc" >
    <button style='padding:10px' class='button' type="submit" id="License" name= "License">License agreement</button></br>
  </div>
  <div hidden id="Licensediv" name= "Licensediv" >
    <div class="License">
Do my qPCR calculations is distributed under <a href="https://www.gnu.org/copyleft/gpl.html">the GNU public license</a>
The source codes of Do my qPCR calculations will be freely available for non-commercial use on GitHub at <a href="https://github.com/JeremyTournayre/do_my_qPCRcalc">https://github.com/JeremyTournayre/do_my_qPCRcalc</a>, and are provided as-is without any warranty regarding reliability, accuracy and fitness for purpose. The user assumes the entire risk of the use of this program and the author can not be hold responsible of any kind of problems. 
    </div>  
<script>
   
  $("#License").click(function(){
      $("#Licensediv").toggle( "slow" );
  });
   
</script>
	

</html>
<?php
  }
?>