<?php
   if(isset($_POST['example']) || isset($_POST['template'])){
	if(isset($_POST['example'])){
	  $file="example.tsv";
	}
	else{
	  $file="template.tsv";
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
		      $file="download/".$file_name.".xlsx";
	 	      unlink($file_upload);
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

*{margin:0; padding:0}
label{
    padding: 20px ;
    display: inline-block;
    font: 400 15px Arial;    
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
  width:220px;
}

.myLabel {
  float:left;
  text-align:center;
  padding:10px;
  margin-right:10px;
}
.desc {
  padding-top:40px;
  margin: auto;
  width: 50%;
  text-align: center;
}

.temp
{
  float:left;
  margin-right:10px;
}


.maDiv {
  margin:0 auto;padding-top:20px;max-width: 1000px;min-width:600px;
}
@media screen and (max-width: 1000px) {
  .button {
    width:100%;
    margin-bottom:15px;
    display: block;
    text-align: left;
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
      <button style='padding:10px;' class="button" type="submit" id="example" name= "example">Example input file</button>
    </form>
    <form class="temp" action="" method="POST" enctype="multipart/form-data">  
      <button style='padding:10px;' class="button" type="submit" id="template" name= "template">Template</button>
    </form>
    <form action="" method="POST" enctype="multipart/form-data">
      <label class="myLabel button" for="file-upload" >Input file</label>
      <input id="file-upload" type="file" name="qPCRfile" style="display:none;">
      <button class="button" type="submit" style='padding:10px;'>Submit</button>
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

   <div style='font-size: 0;margin:0 auto;padding-top:20px;max-width: 600px;min-width:600px; height:50px;'>
<table style='width:100%'>
<tr>
<td  style='width:50%;text-align: center; '>
      <form style=' float:left;'  action="" method="POST" enctype="multipart/form-data">
         <button style='padding:10px;' class='button' type="submit" id="example" name= "example">Example input file</button>
         <button style='padding:10px;' class='button' type="submit" id="template" name= "template">Template</button>
      </form>
      </td>
      <td>
      <form  action="" method="POST" enctype="multipart/form-data">
<label style=' float:left; ' for="file-upload" class="button" >
   Input file
  </label>
  <input id="file-upload" type="file" name="qPCRfile" style="display:none;">
	</td>
	<td>
	  <button class='button' type="submit" style='padding:10px;'>Submit</button>
	  </td>
	
      </form>
    </tr>
</table>

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
    <div style="padding-top:40px;margin: auto;width: 50%;text-align: center">
              <button style='padding:10px;' class='button' type="submit" id="help" name= "help">Description/Help</button></br>
            
 
   </div>
   <div hidden id="helpdiv" name= "helpdiv" >
   
   <style>
   .help {
	overflow-x: auto;
	white-space: nowrap;
    }
   </style>
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

   </script>

</html>
<?php
  }
?>