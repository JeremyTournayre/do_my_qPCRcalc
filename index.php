<?php
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
<style>
.line-separator{
    background:black;

    padding-left:5;
    padding-right:5;
    margin-right:5px;
    margin-left:5px;
}


.button{

font: 400 15px Arial;    
  background:#1AAB8A;
  color:#fff;
  border:none;
  position:relative;
  cursor:pointer;
  transition:800ms ease all;
  outline:none;
}

.buttonred{

font: 400 15px Arial;    
  background:#ff5050;
  color:#fff;
  border:none;
  position:relative;
  cursor:pointer;
  transition:800ms ease all;
  outline:none;
}

.myLabel {
  text-align:center;
  padding:10px;
}
.desc {
  padding-top:40px;
  margin: auto;
  width: 50%;
  text-align: center;
}

.temp
{

}


.maDiv {
 padding-top:10;
  margin:0 auto;width:800px;
    text-align:center;
}
@media screen and (max-width: 800px) {
  .button {
    width:100%;
    margin-bottom:15px;
    display: block;
    text-align: left;
    font-size:50px;
  }
    .buttonred {
    width:100%;
    margin-bottom:15px;
    display: block;
    text-align: left;
    font-size:50px;
  }

.exception{

}
  
.line-separator{
    background:black;
    margin:0;
    padding-top:15px;
    padding-bottom:5px;
    padding-left:400;
    padding-right:400;
 
}

  .titrebutton { 
      font-size:50px;
  }
  
.myLabel {
  text-align:left;
}

  .maDiv {
    max-width: 1000;
  }
  .desc {
    margin-top:130px;
    width:100%;
  }

  .temp {
    width:100%;
  }


}
*{margin:0; padding:0}
label{
    padding: 20px ;
    display: inline-block;
    font: 400 15px Arial;    
 }


.button:hover{
  background:#fff;
  color:#1AAB8A;
}
.button:before,.button:after{
  content:'';
  position:absolute;
  top:0;
  right:0;
  height:2px;
  width:0;
  background: #1AAB8A;
  transition:400ms ease all;
}
.button:after{
  right:inherit;
  top:inherit;
  left:0;
  bottom:0;
}
.button:hover:before,.button:hover:after{
  width:100%;
  transition:800ms ease all;
}

.buttonred:hover{
  background:#fff;
  color:#ff5050;
}
.buttonred:before,.buttonred:after{
  content:'';
  position:absolute;
  top:0;
  right:0;
  height:2px;
  width:0;
  background: #ff5050;
  transition:400ms ease all;
}
.buttonred:after{
  right:inherit;
  top:inherit;
  left:0;
  bottom:0;
}
.buttonred:hover:before,.buttonred:hover:after{
  width:100%;
  transition:800ms ease all;
}


form{
  margin-bottom: 0em;
}

.container{
  margin:0 auto;
  max-width: 600px;min-width:600px;
  position: relative;
  height: 100px;    
}


[id^=myBar] {
  width: 150px;
  height: 50px;
  position:absolute;
  bottom : 0;
  text-align: center;
  color: white;
}

.help {
  overflow-x: auto;
  white-space: nowrap;
}
</style>
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

  <div class="desc" >
    <button style='padding:10px' class='button' type="submit" id="help" name= "help">Description/Help</button></br>
  </div>
  <div hidden id="helpdiv" name= "helpdiv" >
    <div class="help">
      <img src="img/help.png" >
      <img src="img/help-2.png">   
      <img src="img/help-3.png">   
    </div>
  </div>     
  <div style="padding-top:40px;margin: auto;width: 50%;text-align: center">
    Have a suggestion? <a href="mailto:jeremy.tournayre@inra.fr">Contact</a></br>
    <img src="img/logo_INRA.png" width="144" height="59">
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
The source codes of Do my qPCR calculations will be freely available for non-commercial use on GitHub, and are provided as-is without any warranty regarding reliability, accuracy and fitness for purpose. The user assumes the entire risk of the use of this program and the author can not be hold responsible of any kind of problems. 
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