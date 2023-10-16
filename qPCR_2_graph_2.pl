use strict;
use warnings;
use Excel::Writer::XLSX;
use Spreadsheet::ParseExcel::Utility 'int2col';
use Spreadsheet::ParseExcel::Utility 'col2int';
use Statistics::TTest;

###############################################################################################
## CREDITS ####################################################################################
# Created by : TOURNAYRE Jérémy				                                                  #
# Subject : Do my qPCR calculations				                                              #
# Industry : INRA Clermont-Ferrand / Theix --- Team iMPROVINg                                 #
# Colleagues : Matthieu Reichstadt, Laurent Parry, Pierre Fafournoux, Céline Jousse           #
###############################################################################################
###############################################################################################

#Function to calculate the log2
sub log2 {
	my $n = shift(@_);
	if ($n == 0){
		$n = '0.5';
	}
	my $t = log($n)/log(2);
	return($t);
}

#Excel or Text file test
my $text_or_excel="txt";
open (F,"upload/".$ARGV[0]);
my $test=<F>;
if ($test=~m/^PK/){
  $text_or_excel="xls";
}
close(F);
#If the file is in Excel format: conversion to .txt
my $in="upload/".$ARGV[0];
if ($text_or_excel eq "xls"){
  $in="upload/".$ARGV[0];
  my $out="upload/".$ARGV[0].".txt";
  `ssconvert -O 'separator="	" format=raw quote=""' $in $out`;
  $in=$out;
}

my $methode_Livak=$ARGV[1];

open (F,$in);
my %group2s;
my %efficiency;
my %header;
my %headers;
my %header_norma;
my $header_norma_val;
my $bool_get_headernorma=0;
my $bool_get_group2=0;
my $group2_control;
my %data;
my $max=0;
my @list_add_genes;
my %average_A;
my %order_group2;
my $nb_group2=0;
my %list_sample;
my $group2_control_choose="";
my %header_norma_val_choose;
#Reading the file

while (<F>){
	chomp($_);
	if ($_=~m/^\s+$/ || $_=~m/^\s*\t/){
	  next;
	}
	
	my @tab=split("\t",$_);
	#Suppression of spaces in values
	my @tab2;
	foreach (@tab){
		if ($_ =~m/^(\s*|\t*)$/){
		    $_="<<NA>>";
		}
		$_=~s/\s/_/g;
		push (@tab2,$_);
	}
	@tab=@tab2;
	#Reading options: the first 2 lines and headers (3rd line)
	unshift(@tab,1);
	if ($_=~m/^Group/i){
		my $i=0;
		%header=();
		shift(@tab);shift(@tab);shift(@tab);
	
		foreach (@tab){	
		      if ($_ eq "<<NA>>"){
		      
		       }
			else{
			  $header{$i}=$_;
			  $header{$i}=uc($header{$i});
			  $headers{$header{$i}}=1;
			  if ($bool_get_headernorma==0){
				  $header_norma_val=$header{$i};
				  $header_norma{$header{$i}}=1;
				  $bool_get_headernorma=1;
				  
			  }	
			}
			$i++;
		}
		$max=$i+3;
		my $tmp=$#tab+1;
	}
	elsif ($_=~m/^Control/i){
	  my @split=split("\t",$_);
	  $group2_control_choose=$split[1];
	  my $max=$#split;
	  if ($max <3){
	    $max=3;
	  }
	  for (my $j=3;$j<=$max;$j++){
	    if (!defined($split[$j])){
	      $header_norma_val_choose{""}=1;
	    }	    
	    else{
	      $header_norma_val_choose{uc($split[$j])}=1;
	    }
	  }
	}
	elsif ($_=~m/^qPCR efficiency/i){
		my $i=0;
		shift(@tab);shift(@tab);shift(@tab);
		foreach (@tab){
			$_=~s/,/\./g;
			if ($_ =~ /^[0-9,.E]+$/){
			  $efficiency{$i}=$_;  
			}
			$i++;
		}
	}
	#Retrieving the names of samples and cq
	elsif ($#tab+1==$max && $tab[0] ne ""){		
		my $group=shift(@tab);
		$group =~ s/\s/_/g;
		$group=uc($group);
		my $group2=shift(@tab);
		$group2 =~ s/\s/_/g;
		$group2=uc($group2);
		if (!defined($group2s{$group2})){
			$order_group2{$nb_group2}=$group2;
			$nb_group2++;
		}

		$group2s{$group2}=1;
		if ($bool_get_group2==0 && ($group2_control_choose eq "" || $group2_control_choose eq $group2)){
			$group2_control=$group2;
			$bool_get_group2=1;
		}		
		my $mouse=shift(@tab);
		$mouse =~ s/\s/_/g;
		$mouse=uc($mouse);
		my $tmp_mouse=uc($mouse);
		#If the sample name already exists, add "_ number"
		my $i=1;
		while (1){
		  $i++;
		  if (defined($list_sample{$tmp_mouse})){
		    $tmp_mouse=$mouse."_".$i;
		  }
		  else{
		    last;
		  }
		}
		$mouse=$tmp_mouse;
		$list_sample{$mouse}=1;
		for (my $i=0;$i<=($#tab+1);$i++){
			my $option="";
			my $header_nooption="";
			if (defined($header{$i}) && $header{$i} ne "<<NA>>"){
				if ($option eq ""){
					$header_nooption=$header{$i};
				}
				$header_nooption =~ s/^\s+//;$header_nooption =~ s/\s+$//;
				$header_nooption =~    s/[\W]+//g;
				$option =~ s/\s+/_/g;

				if ($tab[$i] ne "" && $tab[$i] =~ m/-?\d+\.?,?\d*/){
					$data{$header_nooption}{$group2}{$group}{$mouse}{$option}{"Ct"}=$tab[$i];
					if ($group2 eq $group2_control){
						if (!defined($average_A{$header_nooption}{$group}{$option}{"tot"})){
							$average_A{$header_nooption}{$group}{$option}{"tot"}=0;
						}
						if (!defined($average_A{$header_nooption}{$group}{$option}{"nb"})){
							$average_A{$header_nooption}{$group}{$option}{"nb"}=0;
						}					
						$average_A{$header_nooption}{$group}{$option}{"tot"}+=$tab[$i];
						$average_A{$header_nooption}{$group}{$option}{"nb"}++;					
					}
				}
				else{
					$data{$header_nooption}{$group2}{$group}{$mouse}{$option}{"Ct"}="NA";	
				}				

				push (@list_add_genes,$header_nooption);
			}
		}
	}
}
close(F);

my $add_name="";
if ($methode_Livak==1){
	$add_name="_Livak";
}
my $workbook  = Excel::Writer::XLSX->new("download/".$ARGV[0].$add_name."-dmqc.xlsx");
my $worksheet;

if ($bool_get_group2 == 0){
  my $row=0;
  my $col=0;
  $worksheet = $workbook->add_worksheet("Error");	
  $worksheet->write( $row, $col, "No group named: ".$group2_control_choose);$col++;
  exit;
}


foreach (keys %efficiency){
  my $i=$_;
  $efficiency{$header{$i}}=$efficiency{$i};
}


#Test if the user's choices exist
if (defined($group2s{$group2_control_choose})){
  $group2_control=$group2_control_choose;
}
my $bool_efface_header_norma=0;
my $multiple_header_norma=0;
foreach (keys %header_norma_val_choose){
  my $a_header_norma_val_choose=$_;
  if (defined($headers{$a_header_norma_val_choose}) || ($a_header_norma_val_choose eq "NONE")){
    if ($bool_efface_header_norma == 0){
      %header_norma=();
      $bool_efface_header_norma=1;
    }  
    $header_norma_val=$a_header_norma_val_choose;
    $header_norma{$header_norma_val}=1;
    $multiple_header_norma++;
  }
}

if ($multiple_header_norma>=1 && defined( $header_norma{"NONE"})){
  %header_norma=();
  $header_norma_val="NONE";
  $header_norma{"NONE"}=1;
  $multiple_header_norma=-1;
}

if ($methode_Livak==1 && $multiple_header_norma <0){
  my $row=0;
  my $col=0;
  $worksheet = $workbook->add_worksheet("Error");	
  $worksheet->write( $row, $col, "There is no reference gene");$col++;
  exit;
}

#calculation of the CT delta and the qty
foreach (sort keys %data){
	my $header_nooption=$_;
	foreach (sort  keys %{$data{$header_nooption}}){
		my $group2=$_;
		foreach (sort keys %{$data{$header_nooption}{$group2}}){
			my $group=$_;
			foreach (sort keys %{$data{$header_nooption}{$group2}{$group}}){
				my $mouse=$_;
				foreach (sort keys %{$data{$header_nooption}{$group2}{$group}{$mouse}}){
					my $option=$_;
					
					if ( $data{$header_nooption}{$group2}{$group}{$mouse}{$option}{"Ct"} eq "NA"){next;}
					if (!defined($average_A{$header_nooption}{$group}{$option}{"nb"})){
						my $row=0;
						my $col=0;
						$worksheet = $workbook->add_worksheet("Error");	
						$worksheet->write( $row, $col, "No control : ".$group2_control." for the gene ".$header_nooption);$col++;	
						exit;
					}


if ($methode_Livak==0){

					my $delta_ct=(($average_A{$header_nooption}{$group}{$option}{"tot"}/$average_A{$header_nooption}{$group}{$option}{"nb"})-$data{$header_nooption}{$group2}{$group}{$mouse}{$option}{"Ct"});
					$data{$header_nooption}{$group2}{$group}{$mouse}{$option}{"delta_ct"}=$delta_ct;					
					my $qty=0;
					if (defined($efficiency{$header_nooption})){
					  $qty=$efficiency{$header_nooption}**$delta_ct;
					}
					else{
					  $qty=1.85**$delta_ct;
					}
# 					print '$data{'.$header_nooption.'}{'.$group2.'}{'.$group.'}{'.$mouse.'}{'.$option.'}{"Qty"}'.'='.$qty."\n";
					$data{$header_nooption}{$group2}{$group}{$mouse}{$option}{"Qty"}=$qty;
					
					if (defined($header_norma{$header_nooption})){
					
					  if (!defined($data{"average"}{$group2}{$group}{$mouse}{$option}{"nb"})){
					    $data{"average"}{$group2}{$group}{$mouse}{$option}{"nb"}=0;
					    $data{"average"}{$group2}{$group}{$mouse}{$option}{"add"}=0;
					  }
					  $data{"average"}{$group2}{$group}{$mouse}{$option}{"add"}+=$qty;
					  $data{"average"}{$group2}{$group}{$mouse}{$option}{"nb"}++;
					}
}else{
					#Method Livak
					my $tot=0;
					my $nb=0;
					foreach (keys %header_norma){
						$tot+=$data{$_}{$group2}{$group}{$mouse}{$option}{"Ct"};
						$nb++;
					}
					my $Li_delta_ct=($data{$header_nooption}{$group2}{$group}{$mouse}{$option}{"Ct"}-($tot/$nb));
					$data{$header_nooption}{$group2}{$group}{$mouse}{$option}{"Li_delta_ct"}=$Li_delta_ct;	

					if ($group2 eq $group2_control){
						if (!defined($data{$header_nooption}{"average"}{$group}{$option}{"nb"})){
							$data{$header_nooption}{"average"}{$group}{$option}{"nb"}=0;
							$data{$header_nooption}{"average"}{$group}{$option}{"add"}=0;
						}
						$data{$header_nooption}{"average"}{$group}{$option}{"add"}+=$Li_delta_ct;
						$data{$header_nooption}{"average"}{$group}{$option}{"nb"}++;
						
						# print   '$data{"average"}{'.$group.'}{'.$option.'}{"add"}+='.$Li_delta_ct."\n";
					}
}
				}
			}					
		}			
	}	
}
####average des gènes de références
if ($methode_Livak==0){
	foreach (keys %{$data{"average"}}){
		my $group2=$_;
		foreach (keys %{$data{"average"}{$group2}}){
			my $group=$_;
			foreach (keys %{$data{"average"}{$group2}{$group}}){
			my $mouse=$_;
			$data{"average"}{$group2}{$group}{$mouse}{""}{"Qty"}=$data{"average"}{$group2}{$group}{$mouse}{""}{"add"}/$data{"average"}{$group2}{$group}{$mouse}{""}{"nb"};
			}
		}
	}
}
# else{
# ####Method Livak : average des gènes de références
# 	foreach (keys %{$data{"average"}}){
# 		my $group2=$_;
# 		foreach (keys %{$data{"average"}{$group2}}){
# 			my $group=$_;
# 			foreach (keys %{$data{"average"}{$group2}{$group}}){
# 			my $mouse=$_;
# 			$data{"average"}{$group2}{$group}{$mouse}{""}{"Li_delta_ct"}=$data{"average"}{$group2}{$group}{$mouse}{""}{"add"}/$data{"average"}{$group2}{$group}{$mouse}{""}{"nb"};
# 			}
# 		}
# 	}
# }

# Creating colors for histograms based on the number of groups:

my $darken=0;
my $rgb=1;
my $nb=0;
my $direction=0;
my $bool_direction=0;
my $div=2;
my $nb_inter=0;
foreach (keys %group2s){
  $nb_inter++;
}
my @color;
for (my $i = 1; $i <= $nb_inter; $i++)
	{
	my $r=0;
	my $g=0;
	my $b=0;
	#Change the 20 to decide when to darken.
	if ($rgb==0 && $i%20==0) { $darken=$darken+50; $rgb=1;}
	
	if ($rgb==1) { $r=254-$darken; $rgb=2;}
	elsif ($rgb==2) { $g=254-$darken;	$rgb=3;}
	elsif ($rgb==3) {	$b=254-$darken;	$rgb=4;}
	elsif ($rgb==4) {	$r=254-$darken;	$g=254-$darken;	$rgb=5;}
	elsif ($rgb==5) {	$g=254-$darken;	$b=254-$darken;	$rgb=6;}
	elsif ($rgb==6) {	$r=254-$darken;	$b=254-$darken;	$rgb=0;	$nb=0; $bool_direction=0; $div=2;}
	else
		{
		if ($nb==0) { $r=254-$darken; $g=((254/$div)+$direction)-$darken; $nb++;}
		elsif ($nb==1) { $g=254-$darken; $b=((254/$div)+$direction)-$darken; $nb++;}
		elsif ($nb==2) { $b=254-$darken; $r=((254/$div)+$direction)-$darken; $nb++;}
		elsif ($nb==3) { $g=254-$darken; $r=((254/$div)+$direction)-$darken; $nb++;}
		elsif ($nb==4) { $b=254-$darken; $g=((254/$div)+$direction)-$darken; $nb++;}
		else
			{
			$r=254-$darken;
			$b=((254/$div)+$direction)-$darken;
			$nb=0;
# 			Exception
			if ($bool_direction==0) { $direction=(254/($div*2)); $bool_direction=1;}
			else { $div=$div*2; $direction=0;}
			}
		}
	
	$r=int($r + 0.99);
	$g=int($g + 0.99);
	$b=int($b + 0.99);
	my $temp_color="$r,$g,$b";
	#convert RGB to hexadecimal
	my @temp_color = split(",",$temp_color);
	my $hex_RGB="";
	foreach(@temp_color )
		{
		my $value=$_;
		my $hex_value = sprintf "%x", $value;
		if(length($hex_value)<2) { $hex_value="0".$hex_value;}
		$hex_RGB.=$hex_value;
		}
	push(@color,"#".$hex_RGB);
	}
$nb=0;


my $i_group2=0;
my %colors;
foreach (sort keys %group2s){
  $nb_inter++;
  $colors{$_}=$color[$i_group2];
  $i_group2++;
}

#Writing data in an Excel file + calculation 
my %list_header=%header;
foreach (sort {$a <=> $b} keys %list_header){
      if ($list_header{$_} eq "<<NA>>"){

	next;
      }
	my $row=0;
	my $col=0;	
	my $row2=0;
	my $col2=0;		
	my $header=$list_header{$_};

	my $tmp_header=$header;
	$tmp_header =~ s/\s+/_/g;	
	$worksheet = $workbook->add_worksheet($tmp_header);	
	$worksheet->write( $row, $col, "group");$col++;	
	$worksheet->write( $row, $col, "name");$col++;							
	$worksheet->write( $row, $col, $tmp_header." Quantification Cycle (Cq)");$col++;
	if ($methode_Livak==0){
		$worksheet->write( $row, $col, "Average ".$group2_control." Cq");$col++;							
		$worksheet->write( $row, $col, "delta Cq");$col++;
		my $eff="";
		if (defined($efficiency{$header})){
		$eff=$efficiency{$header};
		}
		else{
		$eff=1.85;
		}
		$worksheet->write( $row, $col, "Quantification (efficiency: ".$eff.")");$col++;
		if (defined($header_norma{$header})){
		$worksheet->write( $row, $col, "This is a reference gene");$col++;
		}
		elsif ($multiple_header_norma <0){
		$worksheet->write( $row, $col, "There is no reference gene");$col++;
		}	
		elsif ($multiple_header_norma <=1){
		$worksheet->write( $row, $col, "Normalization by ".$header_norma_val);$col++;
		}
		else{
		$worksheet->write( $row, $col, "Normalization by the average of the reference genes");$col++;
		}
		$worksheet->write( $row, $col, "Log2");$col++;	
	}else{
		my $eff="";
		if (defined($efficiency{$header})){
		$eff=$efficiency{$header};
		}
		else{
		$eff=1.85;
		}
		if ($multiple_header_norma <0){
			$worksheet->write( $row, $col, "There is no reference gene");$col++;
		}	
		else{
			$worksheet->write( $row, $col, "delta Cq by ".$header_norma_val);$col++;
		}
		$worksheet->write( $row, $col, "Average ".$group2_control." delta Cq");$col++;							
		$worksheet->write( $row, $col, "delta delta Cq");$col++;							
		$worksheet->write( $row, $col, "fold change (".$eff."^-delta delta Ct)");$col++;	
		$worksheet->write( $row, $col, "Log2");$col++;							
	}
	$row++;	$col=0;
	my $chart     = $workbook->add_chart( embedded => 1  ,type => 'column' );
	$chart->show_blanks_as( 'span' );
	$chart->set_y_axis( name => 'Normalized quantification log2' );
	$chart->set_x_axis( name => 'Sample' );	
	my $string=' [ ';
	my $string2=' [ ';
	my %average;
	my %average_grp;
	my %list_val_group2;
	foreach (sort {$a <=> $b} keys %order_group2){
		my $group2=$order_group2{$_};
		my @totsquare;
		my @totsquarelog2;

		my $deb_row_group2=$row;
		$header=$tmp_header;
		foreach (sort keys %{$data{$tmp_header}{$group2}}){
			my $group=$_;
			my @totsquare_group;
			my @totsquare_grouplog2;
			foreach (sort keys %{$data{$header}{$group2}{$group}}){
				my $mouse=$_;
				foreach (sort keys %{$data{$header}{$group2}{$group}{$mouse}}){
					my $option=$_;		
					foreach (sort keys %{$data{$header}{$group2}{$group}{$mouse}}){
						my $option=$_;	
					}
					foreach (sort keys %header_norma){
						my $the_header_norma=$_;
						if (defined($data{"average"})){
						    $the_header_norma="average";
						}
						my $normalisation;
						my $pre_normalisation;
						if (defined($header_norma{$header})){
							if ($methode_Livak==0){
								$normalisation=$data{$header}{$group2}{$group}{$mouse}{$option}{"Qty"};
							}else{
								$pre_normalisation=$data{$header}{$group2}{$group}{$mouse}{$option}{"Li_delta_ct"};
							}
							$the_header_norma="";
						}
						if ( defined($data{$header}{"average"}{$group}{$option}) ||$header_norma_val eq "NONE" || defined($header_norma{$header}) || (defined($data{$the_header_norma}) 
							&& defined($data{$the_header_norma}{$group2}) 
							&& defined($data{$the_header_norma}{$group2}{$group}) 
							&& defined($data{$the_header_norma}{$group2}{$group}{$mouse})
							&& defined($data{$the_header_norma}{$group2}{$group}{$mouse}{""})
							&& (defined($data{$the_header_norma}{$group2}{$group}{$mouse}{""}{"Qty"}) ))){

							my $tmp_normalisation="";
							if ( $data{$header}{$group2}{$group}{$mouse}{$option}{"Ct"} eq "NA"){
								$normalisation="NA";
								$normalisation="NA";
								$worksheet->write( $row, $col, $group2);$col++;
								$worksheet->write( $row, $col, $mouse);$col++;							
								$worksheet->write( $row, $col,"NA");$col++;
								$worksheet->write( $row, $col,"NA");$col++;
								my $average_A_delta_ct="NA";
								$worksheet->write( $row, $col, "NA");$col++;							
								$worksheet->write( $row, $col, "NA");$col++;
								$worksheet->write( $row, $col, "NA");$col++;
								$worksheet->write( $row, $col, "NA");$col++;
								$row++;	$col=0;
								$string.='{ fill => { color => \''.$colors{$group2}.'\' }},';	
							}	
							else{	
								if ($header_norma_val eq "NONE"){
									if ($methode_Livak==0){
										$normalisation=$data{$header}{$group2}{$group}{$mouse}{$option}{"Qty"};
									}else{
										$pre_normalisation=$data{$header}{$group2}{$group}{$mouse}{$option}{"Li_delta_ct"};
									}	
								}
								elsif (!defined($header_norma{$header})){			

									if ($methode_Livak==0){
										$normalisation=$data{$header}{$group2}{$group}{$mouse}{$option}{"Qty"}/$data{$the_header_norma}{$group2}{$group}{$mouse}{""}{"Qty"};
									}else{
										$pre_normalisation=$data{$header}{$group2}{$group}{$mouse}{$option}{"Li_delta_ct"}-($data{$header}{"average"}{$group}{$option}{"add"}/$data{$header}{"average"}{$group}{$option}{"nb"});
									}
								}
								if ($methode_Livak==0){
									$tmp_normalisation=$normalisation;						
									$normalisation=log2($normalisation);
								}
								else{
									# $normalisation= 2 ** -$pre_normalisation;
									if (defined($efficiency{$header})){
										$normalisation=$efficiency{$header}**-$pre_normalisation;
									}
									else{
										$normalisation=1.85**-$pre_normalisation;
									}									
									$tmp_normalisation=$normalisation;						
									$normalisation=log2($normalisation);
								}
								$string.='{ fill => { color => \''.$colors{$group2}.'\' }},';							
								my $tmp_option=$option;
								$worksheet->write( $row, $col, $group2);$col++;
								$worksheet->write( $row, $col, $mouse);$col++;							
								$data{$header}{$group2}{$group}{$mouse}{$tmp_option}{"Ct"}=~s/,/\./g;
								$worksheet->write_number( $row, $col, $data{$header}{$group2}{$group}{$mouse}{$tmp_option}{"Ct"});$col++;
								if ($methode_Livak==0){
									my $average_A_delta_ct=($average_A{$header}{$group}{$tmp_option}{"tot"}/$average_A{$header}{$group}{$tmp_option}{"nb"});
									$worksheet->write( $row, $col, $average_A_delta_ct);$col++;			
									$worksheet->write( $row, $col, $data{$header}{$group2}{$group}{$mouse}{$tmp_option}{"delta_ct"});$col++;
									$worksheet->write( $row, $col, $data{$header}{$group2}{$group}{$mouse}{$tmp_option}{"Qty"});$col++;
									$worksheet->write( $row, $col, $tmp_normalisation);$col++;
									$worksheet->write( $row, $col, $normalisation);$col++;
								}else{
									$worksheet->write( $row, $col, $data{$header}{$group2}{$group}{$mouse}{$tmp_option}{"Li_delta_ct"});$col++;
# print $data{"average"}{$group}{$tmp_option}{"add"}."\n";
									$worksheet->write( $row, $col, ($data{$header}{"average"}{$group}{$tmp_option}{"add"}/$data{$header}{"average"}{$group}{$tmp_option}{"nb"}));$col++;


									$worksheet->write( $row, $col, $pre_normalisation);$col++;
									$worksheet->write( $row, $col, $tmp_normalisation);$col++;
									$worksheet->write( $row, $col, $normalisation);$col++;

								}			

								$row++;	$col=0;
								$option=$tmp_option;
								$string2.='{ fill => { color => \''.$colors{$group2}.'\' }},';							
								$row2++;	$col2=0;								
								if (!defined($average{"all"}{$group2}{"nb"})){
									$average{"all"}{$group2}{"nb"}=0;
								}
								if (!defined($average{"all"}{$group2}{"tot"})){
									$average{"all"}{$group2}{"tot"}=0;
								}
								if (!defined($average{$group}{$group2}{"nb"})){
									$average{$group}{$group2}{"nb"}=0;
								}
								if (!defined($average{$group}{$group2}{"tot"})){
									$average{$group}{$group2}{"tot"}=0;
								}								
								$average{"all"}{$group2}{"nb"}++;
								$average{"all"}{$group2}{"tot"}+=$tmp_normalisation;
								push(@totsquare,$tmp_normalisation);		
								$average{$group}{$group2}{"nb"}++;
								$average{$group}{$group2}{"tot"}+=$tmp_normalisation;								
								push(@totsquare_group,$tmp_normalisation);	

								if (!defined($average{"all"}{$group2}{"nblog2"})){
									$average{"all"}{$group2}{"nblog2"}=0;
								}
								if (!defined($average{"all"}{$group2}{"totlog2"})){
									$average{"all"}{$group2}{"totlog2"}=0;
								}
								if (!defined($average{$group}{$group2}{"nblog2"})){
									$average{$group}{$group2}{"nblog2"}=0;
								}
								if (!defined($average{$group}{$group2}{"totlog2"})){
									$average{$group}{$group2}{"totlog2"}=0;
								}								
								$average{"all"}{$group2}{"nblog2"}++;
								$average{"all"}{$group2}{"totlog2"}+=$normalisation;
								push(@totsquarelog2,$normalisation);		
								$average{$group}{$group2}{"nblog2"}++;
								$average{$group}{$group2}{"totlog2"}+=$normalisation;								
								push(@totsquare_grouplog2,$normalisation);	
							}
						}
						if (defined($header_norma{$header})){
							last;
						}	
						if (defined($data{"average"})){
							last;
						}				
						if (defined($data{$header}{"average"}{$group}{$option}) ){
							last;
						}
					}
				}	
			}	
			my $valsquare=0;
			my $moy;
			if (!defined($average{$group}) || !defined($average{$group}{$group2}) || !defined($average{$group}{$group2}{"nb"})){
				$moy=0;
			}
			else{
				$moy=$average{$group}{$group2}{"tot"}/$average{$group}{$group2}{"nb"};				
			}
			
			foreach (@totsquare_group){
				$valsquare+=($_-$moy)*($_-$moy);
			}			
			$average{$group}{$group2}{"valsquare"}=$valsquare;	

			my $valsquarelog2=0;
			my $moylog2;
			if (!defined($average{$group}) || !defined($average{$group}{$group2}) || !defined($average{$group}{$group2}{"nblog2"})){
				$moylog2=0;
			}
			else{
				$moylog2=$average{$group}{$group2}{"totlog2"}/$average{$group}{$group2}{"nblog2"};				
			}
			
			foreach (@totsquare_grouplog2){
				$valsquarelog2+=($_-$moylog2)*($_-$moylog2);
			}		

			$average{$group}{$group2}{"valsquarelog2"}=$valsquarelog2;		
		}	
		my $valsquare=0;
		my $moy;
		if (!defined($average{"all"}) || !defined($average{"all"}{$group2}) || !defined($average{"all"}{$group2}{"nb"})){
			$moy=0;
		}
		else{		
			$moy=$average{"all"}{$group2}{"tot"}/$average{"all"}{$group2}{"nb"};
		}
		foreach (@totsquare){
			$valsquare+=($_-$moy)*($_-$moy);
		}		
		$average{"all"}{$group2}{"valsquare"}=$valsquare;	
		push(@{$list_val_group2{"all"}{$group2}{"qty"}}, @totsquare);

		my $moylog2;	
		my $valsquarelog2=0;
		if (!defined($average{"all"}) || !defined($average{"all"}{$group2}) || !defined($average{"all"}{$group2}{"nblog2"})){
			$moylog2=0;
		}
		else{		
			$moylog2=$average{"all"}{$group2}{"totlog2"}/$average{"all"}{$group2}{"nblog2"};
		}
		foreach (@totsquarelog2){
			$valsquarelog2+=($_-$moylog2)*($_-$moylog2);
		}		
		push(@{$list_val_group2{"all"}{$group2}{"log2"}}, @totsquarelog2);
		$average{"all"}{$group2}{"valsquarelog2"}=$valsquarelog2;			
	}
	my $ttest = new Statistics::TTest;  
	my @array1=@{$list_val_group2{"all"}{$group2_control}{"qty"}};

		foreach (keys %{$list_val_group2{"all"}}){
			if ($_ eq $group2_control){
				next;
			}

			my @array2=@{$list_val_group2{"all"}{$_}{"qty"}};
			if ($#array2<=0 || $#array1<=0){
			  $average{"all"}{$_}{"pvalue_qty"}="NA";
			}
			else{
				if ($multiple_header_norma<=1 && $methode_Livak==1 && defined($header_norma{$header})){
					$average{"all"}{$_}{"pvalue_qty"}="NA";
				}else{
					$ttest->load_data(\@array1,\@array2);  
					my $pvalue=$ttest->t_prob;
					$average{"all"}{$_}{"pvalue_qty"}=$pvalue;
				}
			}
		}

		@array1=@{$list_val_group2{"all"}{$group2_control}{"log2"}};

		foreach (keys %{$list_val_group2{"all"}}){
			if ($_ eq $group2_control){
				next;
			}

			my @array2=@{$list_val_group2{"all"}{$_}{"log2"}};
		
			if ($#array2<=0 || $#array1<=0){
			  $average{"all"}{$_}{"pvalue_log2"}="NA";
			}
			else{
				if ($multiple_header_norma<=1 && $methode_Livak==1 && defined($header_norma{$header})){
					$average{"all"}{$_}{"pvalue_log2"}="NA";
				}else{
					$ttest->load_data(\@array1,\@array2);  
					my $pvalue=$ttest->t_prob;
					$average{"all"}{$_}{"pvalue_log2"}=$pvalue;
				}				
			 }
		}
	
	chop($string);
	$string.=' ] ';
	my @list;

	eval '@list = ( '.$string.');';
		$chart->add_series(
			categories => '='.$tmp_header.'!$B$2:$B$'.($row),
			values     => '='.$tmp_header.'!$H$2:$H$'.($row),
			points => @list
		);		
	
	$chart->set_legend( none => 1 );
	$worksheet->insert_chart( 'I1', $chart, 3, 5, ($row/18), 3 );


	$chart     = $workbook->add_chart( embedded => 1  ,type => 'column' );
	$chart->show_blanks_as( 'span' );
	$chart->set_y_axis( name => 'Normalized quantification' );
	$chart->set_x_axis( name => 'Sample' );
		$chart->add_series(
			categories => '='.$tmp_header.'!$B$2:$B$'.($row),
			values     => '='.$tmp_header.'!$G$2:$G$'.($row),
			points => @list
		);		
	
	$chart->set_legend( none => 1 );
	$worksheet->insert_chart( 'A'.($row+1), $chart, 3, 5, ($row/18), 3 );

	chop($string2);
	$string2.=' ] ';
	my @list2;
	eval '@list2 = ( '.$string2.');';
	my @split_tmp=split(" ",$header);
	my $tmp=$split_tmp[0];
	my $string3=' [ ';
	foreach (sort keys %average){
		my $group=$_;
		if ($group eq "1"){
			next;
		}
		#Average
		$worksheet = $workbook->add_worksheet($tmp_header.'_Average');	
		$chart     = $workbook->add_chart( embedded => 1  ,type => 'column' );
		$chart->show_blanks_as( 'span' );
		$chart->set_y_axis( name => 'Normalized quantification' );
		$chart->set_x_axis( name => 'Group' );
		$row=0;$col=0;		
		$worksheet->write( $row, $col, "Group");$col++;	
		$worksheet->write( $row, $col, $tmp_header." Average");$col++;
		$worksheet->write( $row, $col, "SEM");$col++;
		$worksheet->write( $row, $col, "pvalue");$col++;
		$worksheet->write( $row, $col, "Average Log2");$col++;	
		$worksheet->write( $row, $col, "SEM Log2");$col++;
		$worksheet->write( $row, $col, "pvalue Log2");$col++;
		$row++;$col=0;
		foreach (sort {$a <=> $b} keys %order_group2){
			my $group2=$order_group2{$_};
			my $tot=$average{$group}{$group2}{"tot"};
			my $nb;
			my $moy;
			if (!defined($average{$group}) || !defined($average{$group}{$group2}) || !defined($average{$group}{$group2}{"nb"})){
				$nb=0;
				$moy=0;
			}
			else{
				$nb=$average{$group}{$group2}{"nb"};
				$moy=($tot/$nb);
			}

			my $totlog2=$average{$group}{$group2}{"totlog2"};
			my $nblog2;
			my $moylog2;
			if (!defined($average{$group}) || !defined($average{$group}{$group2}) || !defined($average{$group}{$group2}{"nblog2"})){
				$nblog2=0;
				$moylog2=0;
			}
			else{
				$nblog2=$average{$group}{$group2}{"nblog2"};
				$moylog2=($totlog2/$nblog2);
			}
			my $valsquare=$average{$group}{$group2}{"valsquare"};
			my $ecart_type =0;
			my $er_type;
			my $valsquarelog2=$average{$group}{$group2}{"valsquarelog2"};
			my $ecart_typelog2 =0;
			my $er_typelog2;

			if ($nb!=0){
				if ($nb-1!=0){
				  $ecart_type = sqrt ( $valsquare/ ($nb-1));
				}
				$er_type = $ecart_type/ sqrt ($nb);

				if ($nblog2-1!=0){
				  $ecart_typelog2 = sqrt ( $valsquarelog2/ ($nblog2-1));
				}
				$er_typelog2= $ecart_typelog2/ sqrt ($nblog2);		

				$worksheet->write( $row, $col, $group2);$col++;							
				$worksheet->write( $row, $col, $moy);$col++;
				$worksheet->write( $row, $col, $er_type);$col++;	
				my $format = $workbook->add_format();
				if (defined($average{$group}{$group2}{"pvalue_qty"}) && $average{$group}{$group2}{"pvalue_qty"} ne "" && $average{$group}{$group2}{"pvalue_qty"} ne "NA" && $average{$group}{$group2}{"pvalue_qty"}<=0.05){
				  $format->set_bg_color( 'green' );	
				  $format->set_color( 'white' );	
				}
				$worksheet->write( $row, $col, $average{$group}{$group2}{"pvalue_qty"},$format);$col++;
	
				$worksheet->write( $row, $col, $moylog2);$col++;
				$worksheet->write( $row, $col, $er_typelog2);$col++;
				$worksheet->write( $row, $col, $average{$group}{$group2}{"pvalue_log2"});$col++;									
			}
			else{
				$worksheet->write( $row, $col, $group2);$col++;							
				$worksheet->write( $row, $col, "NA");$col++;
				$worksheet->write( $row, $col, "NA");$col++;					
				$worksheet->write( $row, $col, "NA");$col++;		
				$worksheet->write( $row, $col, "NA");$col++;					
				$worksheet->write( $row, $col, "NA");$col++;
				$worksheet->write( $row, $col, "NA");$col++;								
			}
			$row++;	$col=0;
			$string3.='{ fill => { color => \''.$colors{$group2}.'\' }},';
		}
		chop($string3);
		$string3.=' ] ';		
		my @list;
		eval '@list = ( '.$string3.');';		
		$chart->add_series(
		    categories => '='.$tmp_header.'_Average!$A$2:$A$'.($row),
		    values     => '='.$tmp_header.'_Average!$B$2:$B$'.($row),
			y_error_bars => {
			    type         => 'custom',
				plus_values  => '='.$tmp_header.'_Average!$C$2:$C$'.($row),
			    minus_values => '='.$tmp_header.'_Average!$C$2:$C$'.($row),
			},
			points => 
			 @list
	    );	
	    $chart->set_legend( none => 1 );
	    if ($row+1<=20){
		$worksheet->insert_chart( 'A20', $chart, 2, 3, 2, 2 ); 	    
	    }
	    else{
		$worksheet->insert_chart( 'A'.($row+1), $chart, 2, 3, 2, 2 ); 	    
	    }	    
	    $chart     = $workbook->add_chart( embedded => 1  ,type => 'column' );
	    $chart->show_blanks_as( 'span' );
	    $chart->set_y_axis( name => 'Normalized quantification log2' );
	    $chart->set_x_axis( name => 'Group' );	
	    $chart->add_series(
	      categories => '='.$tmp_header.'_Average!$A$2:$A$'.($row),
	      data_labels => {value => 0},
	      values     => '='.$tmp_header.'_Average!$E$2:$E$'.($row),
	      y_error_bars => {
		  type         => 'custom',
		      plus_values  => '='.$tmp_header.'_Average!$F$2:$F$'.($row),
		  minus_values => '='.$tmp_header.'_Average!$F$2:$F$'.($row),
	      },
	      points => 
	      @list
	    );	
	    $chart->set_legend( none => 1 );
	    $worksheet->insert_chart( 'H1', $chart, 2, 3, 2, 2 ); 
	}  
}
