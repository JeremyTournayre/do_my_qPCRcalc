<html>
<style>
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

.myLabel {
  text-align:center;
  padding:10px;
}


.maDiv {
  margin:0 auto;padding-top:20px;max-width: 1000px;min-width:600px;
}

*{margin:0; padding:0}
label{
    padding: 20px ;
    display: inline-block;
    font: 400 15px Arial;    
 }

</style>

<button style='padding:10px;' class="button" type="submit" id="template" name= "template">Template</button><span class="line-separator "></span ><label class="myLabel button" for="file-upload" >Input file (.tsv, .xlsx, .ods)</label><input id="file-upload" type="file" name="qPCRfile" style="display:none;"><span  class="line-separator "></span ><button class="button" type="submit" style='padding:10px;'>Submit</button>
</br>VERSUS :</br>
<button style='padding:10px;' class="button" type="submit" id="template" name= "template">Template</button>
<span class="line-separator "></span >
<label class="myLabel button" for="file-upload" >Input file (.tsv, .xlsx, .ods)</label>
<input id="file-upload" type="file" name="qPCRfile" style="display:none;">
<span  class="line-separator "></span >
<button class="button" type="submit" style='padding:10px;'>Submit</button>
</html>
