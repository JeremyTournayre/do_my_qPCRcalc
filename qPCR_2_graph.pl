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

open (F,$in);
my %lots;
my %efficiency;
my %entete;
my %entetes;
my %entete_norma;
my $entete_norma_val;
my $bool_recup_entetenorma=0;
my $bool_recup_lot=0;
my $lot_controle;
my %data;
my $max=0;
my @list_add_genes;
my %moyenne_A;
my %order_lot;
my $nb_lot=0;
my %list_sample;
my $lot_controle_choose="";
my $entete_norma_val_choose="";
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
		%entete=();
		shift(@tab);shift(@tab);shift(@tab);
	
		foreach (@tab){	
		      if ($_ eq "<<NA>>"){
		      
		       }
			else{
			  $entete{$i}=$_;
			  $entete{$i}=uc($entete{$i});
			  $entetes{$entete{$i}}=1;
			  if ($bool_recup_entetenorma==0){
				  $entete_norma_val=$entete{$i};
				  $entete_norma{$entete{$i}}=1;
				  $bool_recup_entetenorma=1;
			  }	
			}
			$i++;
		}
		$max=$i+3;
		my $tmp=$#tab+1;
	}
	elsif ($_=~m/^Control/i){
	  my @split=split("\t",$_);
	  $lot_controle_choose=$split[1];
	  $entete_norma_val_choose=uc($split[3]);
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
		my $groupe=shift(@tab);
		$groupe =~ s/\s/_/g;
		$groupe=uc($groupe);
		my $lot=shift(@tab);
		$lot =~ s/\s/_/g;
		$lot=uc($lot);
		if (!defined($lots{$lot})){
			$order_lot{$nb_lot}=$lot;
			$nb_lot++;
		}

		$lots{$lot}=1;
		if ($bool_recup_lot==0 && ($lot_controle_choose eq "" || $lot_controle_choose eq $lot)){
			$lot_controle=$lot;
			$bool_recup_lot=1;
		}		
		my $souris=shift(@tab);
		$souris =~ s/\s/_/g;
		$souris=uc($souris);
		my $tmp_souris=uc($souris);
		#If the sample name already exists, add "_ number"
		my $i=1;
		while (1){
		  $i++;
		  if (defined($list_sample{$tmp_souris})){
		    $tmp_souris=$souris."_".$i;
		  }
		  else{
		    last;
		  }
		}
		$souris=$tmp_souris;
		$list_sample{$souris}=1;
		for (my $i=0;$i<=($#tab+1);$i++){
			my $option="";
			my $entete_sansoption="";
			if (defined($entete{$i}) && $entete{$i} ne "<<NA>>"){
				if ($option eq ""){
					$entete_sansoption=$entete{$i};
				}
				$entete_sansoption =~ s/^\s+//;$entete_sansoption =~ s/\s+$//;
				$entete_sansoption =~    s/[\W]+//g;
				$option =~ s/\s+/_/g;

				if ($tab[$i] ne "" && $tab[$i] =~ m/-?\d+\.?,?\d*/){
					$data{$entete_sansoption}{$lot}{$groupe}{$souris}{$option}{"Ct"}=$tab[$i];
					if ($lot eq $lot_controle){
						if (!defined($moyenne_A{$entete_sansoption}{$groupe}{$option}{"tot"})){
							$moyenne_A{$entete_sansoption}{$groupe}{$option}{"tot"}=0;
						}
						if (!defined($moyenne_A{$entete_sansoption}{$groupe}{$option}{"nb"})){
							$moyenne_A{$entete_sansoption}{$groupe}{$option}{"nb"}=0;
						}					
						$moyenne_A{$entete_sansoption}{$groupe}{$option}{"tot"}+=$tab[$i];
						$moyenne_A{$entete_sansoption}{$groupe}{$option}{"nb"}++;					
					}
				}
				else{
					$data{$entete_sansoption}{$lot}{$groupe}{$souris}{$option}{"Ct"}="NA";	
				}				

				push (@list_add_genes,$entete_sansoption);
			}
		}
	}
}
close(F);


my $workbook  = Excel::Writer::XLSX->new("download/".$ARGV[0]."-dmqc.xlsx");
my $worksheet;

if ($bool_recup_lot == 0){
  my $row=0;
  my $col=0;
  $worksheet = $workbook->add_worksheet("Erreur");	
  $worksheet->write( $row, $col, "No group named: ".$lot_controle_choose);$col++;
  exit;
}


foreach (keys %efficiency){
  my $i=$_;
  $efficiency{$entete{$i}}=$efficiency{$i};
}


#Test if the user's choices exist
if (defined($lots{$lot_controle_choose})){
  $lot_controle=$lot_controle_choose;
}
if (defined($entetes{$entete_norma_val_choose})){
  $entete_norma_val=$entete_norma_val_choose;
  %entete_norma=();
  $entete_norma{$entete_norma_val}=1;
}



#calculation of the CT delta and the qty
foreach (sort keys %data){
	my $entete_sansoption=$_;
	foreach (sort  keys %{$data{$entete_sansoption}}){
		my $lot=$_;
		foreach (sort keys %{$data{$entete_sansoption}{$lot}}){
			my $groupe=$_;
			foreach (sort keys %{$data{$entete_sansoption}{$lot}{$groupe}}){
				my $souris=$_;
				foreach (sort keys %{$data{$entete_sansoption}{$lot}{$groupe}{$souris}}){
					my $option=$_;
					if ( $data{$entete_sansoption}{$lot}{$groupe}{$souris}{$option}{"Ct"} eq "NA"){next;}
					if (!defined($moyenne_A{$entete_sansoption}{$groupe}{$option}{"nb"})){
						my $row=0;
						my $col=0;
						$worksheet = $workbook->add_worksheet("Erreur");	
						$worksheet->write( $row, $col, "No control : ".$lot_controle." for the gene ".$entete_sansoption);$col++;	
						exit;
					}
					my $delta_ct=(($moyenne_A{$entete_sansoption}{$groupe}{$option}{"tot"}/$moyenne_A{$entete_sansoption}{$groupe}{$option}{"nb"})-$data{$entete_sansoption}{$lot}{$groupe}{$souris}{$option}{"Ct"});
					$data{$entete_sansoption}{$lot}{$groupe}{$souris}{$option}{"delta_ct"}=$delta_ct;					
					my $qte=0;
					if (defined($efficiency{$entete_sansoption})){
					  $qte=$efficiency{$entete_sansoption}**$delta_ct;
					}
					else{
					  $qte=1.85**$delta_ct;
					}
					$data{$entete_sansoption}{$lot}{$groupe}{$souris}{$option}{"Qté"}=$qte;
				}						
			}					
		}			
	}	
}



# Creating colors for histograms based on the number of groups:

my $Assomb=0;
my $rgb=1;
my $nb=0;
my $sens=0;
my $bool_sens=0;
my $div=2;
my $nb_inter=0;
foreach (keys %lots){
  $nb_inter++;
}
my @color;
for (my $i = 1; $i <= $nb_inter; $i++)
	{
	my $r=0;
	my $g=0;
	my $b=0;
	#Change the 20 to decide when to darken.
	if ($rgb==0 && $i%20==0) { $Assomb=$Assomb+50; $rgb=1;}
	
	if ($rgb==1) { $r=254-$Assomb; $rgb=2;}
	elsif ($rgb==2) { $g=254-$Assomb;	$rgb=3;}
	elsif ($rgb==3) {	$b=254-$Assomb;	$rgb=4;}
	elsif ($rgb==4) {	$r=254-$Assomb;	$g=254-$Assomb;	$rgb=5;}
	elsif ($rgb==5) {	$g=254-$Assomb;	$b=254-$Assomb;	$rgb=6;}
	elsif ($rgb==6) {	$r=254-$Assomb;	$b=254-$Assomb;	$rgb=0;	$nb=0; $bool_sens=0; $div=2;}
	else
		{
		if ($nb==0) { $r=254-$Assomb; $g=((254/$div)+$sens)-$Assomb; $nb++;}
		elsif ($nb==1) { $g=254-$Assomb; $b=((254/$div)+$sens)-$Assomb; $nb++;}
		elsif ($nb==2) { $b=254-$Assomb; $r=((254/$div)+$sens)-$Assomb; $nb++;}
		elsif ($nb==3) { $g=254-$Assomb; $r=((254/$div)+$sens)-$Assomb; $nb++;}
		elsif ($nb==4) { $b=254-$Assomb; $g=((254/$div)+$sens)-$Assomb; $nb++;}
		else
			{
			$r=254-$Assomb;
			$b=((254/$div)+$sens)-$Assomb;
			$nb=0;
# 			Exception
			if ($bool_sens==0) { $sens=(254/($div*2)); $bool_sens=1;}
			else { $div=$div*2; $sens=0;}
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


my $i_lot=0;
my %colors;
foreach (sort keys %lots){
  $nb_inter++;
  $colors{$_}=$color[$i_lot];
  $i_lot++;
}

#Writing data in an Excel file + calculation 
my %list_entete=%entete;
foreach (sort {$a <=> $b} keys %list_entete){
      if ($list_entete{$_} eq "<<NA>>"){

	next;
      }
	my $row=0;
	my $col=0;	
	my $row2=0;
	my $col2=0;		
	my $entete=$list_entete{$_};

	my $tmp_entete=$entete;
	$tmp_entete =~ s/\s+/_/g;	
	$worksheet = $workbook->add_worksheet($tmp_entete);	
	$worksheet->write( $row, $col, "group");$col++;	
	$worksheet->write( $row, $col, "name");$col++;							
	$worksheet->write( $row, $col, $tmp_entete." Quantification Cycle (Cq)");$col++;
	$worksheet->write( $row, $col, "Average ".$lot_controle." Cq");$col++;							
	$worksheet->write( $row, $col, "delta Cq");$col++;
	my $eff="";
	if (defined($efficiency{$entete})){
	  $eff=$efficiency{$entete};
	}
	else{
	  $eff=1.85;
	}
	$worksheet->write( $row, $col, "Quantification (efficiency: ".$eff.")");$col++;
	$worksheet->write( $row, $col, "Normalization by ".$entete_norma_val);$col++;
	$worksheet->write( $row, $col, "Log2");$col++;	
	$row++;	$col=0;
	my $chart     = $workbook->add_chart( embedded => 1  ,type => 'column' );
	$chart->show_blanks_as( 'span' );
	$chart->set_y_axis( name => 'Normalized quantification log2' );
	$chart->set_x_axis( name => 'Sample' );	
	my $string=' [ ';
	my $string2=' [ ';
	my %moyenne;
	my %moyenne_grp;
	my %list_val_lot;
	foreach (sort {$a <=> $b} keys %order_lot){
		my $lot=$order_lot{$_};
		my @totcarre;
		my @totcarrelog2;

		my $deb_row_lot=$row;
		$entete=$tmp_entete;
		foreach (sort keys %{$data{$tmp_entete}{$lot}}){
			my $groupe=$_;
			my @totcarre_group;
			my @totcarre_grouplog2;
			foreach (sort keys %{$data{$entete}{$lot}{$groupe}}){
				my $souris=$_;
				foreach (sort keys %{$data{$entete}{$lot}{$groupe}{$souris}}){
					my $option=$_;		
					my $bool_15_18=0;
					foreach (sort keys %{$data{$entete}{$lot}{$groupe}{$souris}}){
						my $option=$_;	
					}
					foreach (sort keys %entete_norma){
						my $the_entete_norma=$_;
						my $normalisation;
						if (defined($entete_norma{$entete})){
							$normalisation=$data{$entete}{$lot}{$groupe}{$souris}{$option}{"Qté"};
							$the_entete_norma="";
						}
						if (defined($entete_norma{$entete}) || (defined($data{$the_entete_norma}) 
							&& defined($data{$the_entete_norma}{$lot}) 
							&& defined($data{$the_entete_norma}{$lot}{$groupe}) 
							&& defined($data{$the_entete_norma}{$lot}{$groupe}{$souris})
							&& defined($data{$the_entete_norma}{$lot}{$groupe}{$souris}{""})
							&& defined($data{$the_entete_norma}{$lot}{$groupe}{$souris}{""}{"Qté"}))){

							my $tmp_normalisation="";
							if ( $data{$entete}{$lot}{$groupe}{$souris}{$option}{"Ct"} eq "NA"){
								$normalisation="NA";
								$worksheet->write( $row, $col, $lot);$col++;
								$worksheet->write( $row, $col, $souris);$col++;							
								$worksheet->write( $row, $col,"NA");$col++;
								$worksheet->write( $row, $col,"NA");$col++;
								my $moyenne_A_delta_ct="NA";
								$worksheet->write( $row, $col, "NA");$col++;							
								$worksheet->write( $row, $col, "NA");$col++;
								$worksheet->write( $row, $col, "NA");$col++;
								$worksheet->write( $row, $col, "NA");$col++;
								$row++;	$col=0;
								$string.='{ fill => { color => \''.$colors{$lot}.'\' }},';	
							}	
							else{						
								if (!defined($entete_norma{$entete})){											
									$normalisation=$data{$entete}{$lot}{$groupe}{$souris}{$option}{"Qté"}/$data{$the_entete_norma}{$lot}{$groupe}{$souris}{""}{"Qté"};
								}	
								$tmp_normalisation=$normalisation;						
								$normalisation=log2($normalisation);
							   
								$string.='{ fill => { color => \''.$colors{$lot}.'\' }},';							
								my $tmp_option=$option;
								$worksheet->write( $row, $col, $lot);$col++;
								$worksheet->write( $row, $col, $souris);$col++;							
								$data{$entete}{$lot}{$groupe}{$souris}{$tmp_option}{"Ct"}=~s/,/\./g;
								$worksheet->write_number( $row, $col, $data{$entete}{$lot}{$groupe}{$souris}{$tmp_option}{"Ct"});$col++;
								my $moyenne_A_delta_ct=($moyenne_A{$entete}{$groupe}{$tmp_option}{"tot"}/$moyenne_A{$entete}{$groupe}{$tmp_option}{"nb"});
								$worksheet->write( $row, $col, $moyenne_A_delta_ct);$col++;							
								$worksheet->write( $row, $col, $data{$entete}{$lot}{$groupe}{$souris}{$tmp_option}{"delta_ct"});$col++;
								$worksheet->write( $row, $col, $data{$entete}{$lot}{$groupe}{$souris}{$tmp_option}{"Qté"});$col++;
								$worksheet->write( $row, $col, $tmp_normalisation);$col++;
								$worksheet->write( $row, $col, $normalisation);$col++;
								$row++;	$col=0;
								$option=$tmp_option;
								$string2.='{ fill => { color => \''.$colors{$lot}.'\' }},';							
								$row2++;	$col2=0;								
								if (!defined($moyenne{"all"}{$lot}{"nb"})){
									$moyenne{"all"}{$lot}{"nb"}=0;
								}
								if (!defined($moyenne{"all"}{$lot}{"tot"})){
									$moyenne{"all"}{$lot}{"tot"}=0;
								}
								if (!defined($moyenne{$groupe}{$lot}{"nb"})){
									$moyenne{$groupe}{$lot}{"nb"}=0;
								}
								if (!defined($moyenne{$groupe}{$lot}{"tot"})){
									$moyenne{$groupe}{$lot}{"tot"}=0;
								}								
								$moyenne{"all"}{$lot}{"nb"}++;
								$moyenne{"all"}{$lot}{"tot"}+=$tmp_normalisation;
								push(@totcarre,$tmp_normalisation);		
								$moyenne{$groupe}{$lot}{"nb"}++;
								$moyenne{$groupe}{$lot}{"tot"}+=$tmp_normalisation;								
								push(@totcarre_group,$tmp_normalisation);	

								if (!defined($moyenne{"all"}{$lot}{"nblog2"})){
									$moyenne{"all"}{$lot}{"nblog2"}=0;
								}
								if (!defined($moyenne{"all"}{$lot}{"totlog2"})){
									$moyenne{"all"}{$lot}{"totlog2"}=0;
								}
								if (!defined($moyenne{$groupe}{$lot}{"nblog2"})){
									$moyenne{$groupe}{$lot}{"nblog2"}=0;
								}
								if (!defined($moyenne{$groupe}{$lot}{"totlog2"})){
									$moyenne{$groupe}{$lot}{"totlog2"}=0;
								}								
								$moyenne{"all"}{$lot}{"nblog2"}++;
								$moyenne{"all"}{$lot}{"totlog2"}+=$normalisation;
								push(@totcarrelog2,$normalisation);		
								$moyenne{$groupe}{$lot}{"nblog2"}++;
								$moyenne{$groupe}{$lot}{"totlog2"}+=$normalisation;								
								push(@totcarre_grouplog2,$normalisation);	
							}
						}
						if (defined($entete_norma{$entete})){
							last;
						}						
					}
				}	
			}	
			my $valcarre=0;
			my $moy;
			if (!defined($moyenne{$groupe}) || !defined($moyenne{$groupe}{$lot}) || !defined($moyenne{$groupe}{$lot}{"nb"})){
				$moy=0;
			}
			else{
				$moy=$moyenne{$groupe}{$lot}{"tot"}/$moyenne{$groupe}{$lot}{"nb"};				
			}
			
			foreach (@totcarre_group){
				$valcarre+=($_-$moy)*($_-$moy);
			}			
			$moyenne{$groupe}{$lot}{"valcarre"}=$valcarre;	

			my $valcarrelog2=0;
			my $moylog2;
			if (!defined($moyenne{$groupe}) || !defined($moyenne{$groupe}{$lot}) || !defined($moyenne{$groupe}{$lot}{"nblog2"})){
				$moylog2=0;
			}
			else{
				$moylog2=$moyenne{$groupe}{$lot}{"totlog2"}/$moyenne{$groupe}{$lot}{"nblog2"};				
			}
			
			foreach (@totcarre_grouplog2){
				$valcarrelog2+=($_-$moylog2)*($_-$moylog2);
			}		

			$moyenne{$groupe}{$lot}{"valcarrelog2"}=$valcarrelog2;		
		}	
		my $valcarre=0;
		my $moy;
		if (!defined($moyenne{"all"}) || !defined($moyenne{"all"}{$lot}) || !defined($moyenne{"all"}{$lot}{"nb"})){
			$moy=0;
		}
		else{		
			$moy=$moyenne{"all"}{$lot}{"tot"}/$moyenne{"all"}{$lot}{"nb"};
		}
		foreach (@totcarre){
			$valcarre+=($_-$moy)*($_-$moy);
		}		
		$moyenne{"all"}{$lot}{"valcarre"}=$valcarre;	
		push(@{$list_val_lot{"all"}{$lot}{"qte"}}, @totcarre);

		my $moylog2;	
		my $valcarrelog2=0;
		if (!defined($moyenne{"all"}) || !defined($moyenne{"all"}{$lot}) || !defined($moyenne{"all"}{$lot}{"nblog2"})){
			$moylog2=0;
		}
		else{		
			$moylog2=$moyenne{"all"}{$lot}{"totlog2"}/$moyenne{"all"}{$lot}{"nblog2"};
		}
		foreach (@totcarrelog2){
			$valcarrelog2+=($_-$moylog2)*($_-$moylog2);
		}		
		push(@{$list_val_lot{"all"}{$lot}{"log2"}}, @totcarrelog2);
		$moyenne{"all"}{$lot}{"valcarrelog2"}=$valcarrelog2;			
	}
	my $ttest = new Statistics::TTest;  
	my @array1=@{$list_val_lot{"all"}{$lot_controle}{"qte"}};

		foreach (keys %{$list_val_lot{"all"}}){
			if ($_ eq $lot_controle){
				next;
			}

			my @array2=@{$list_val_lot{"all"}{$_}{"qte"}};
			if ($#array2<=0 || $#array1<=0){
			  $moyenne{"all"}{$_}{"pvalue_qte"}="NA";
			}
			else{

			  $ttest->load_data(\@array1,\@array2);  
			  my $pvalue=$ttest->t_prob;
			  $moyenne{"all"}{$_}{"pvalue_qte"}=$pvalue;
			}
		}

		@array1=@{$list_val_lot{"all"}{$lot_controle}{"log2"}};

		foreach (keys %{$list_val_lot{"all"}}){
			if ($_ eq $lot_controle){
				next;
			}

			my @array2=@{$list_val_lot{"all"}{$_}{"log2"}};
		
			if ($#array2<=0 || $#array1<=0){
			  $moyenne{"all"}{$_}{"pvalue_log2"}="NA";
			}
			else{
			  $ttest->load_data(\@array1,\@array2);  
			  my $pvalue=$ttest->t_prob;
			  $moyenne{"all"}{$_}{"pvalue_log2"}=$pvalue;
			 }
		}
	
	chop($string);
	$string.=' ] ';
	my @list;

	eval '@list = ( '.$string.');';
	$chart->add_series(
	    categories => '='.$tmp_entete.'!$B$2:$B$'.($row),
	    values     => '='.$tmp_entete.'!$H$2:$H$'.($row),
  		points => @list
	);		
	$chart->set_legend( none => 1 );
	$worksheet->insert_chart( 'I1', $chart, 3, 5, ($row/18), 3 );


	$chart     = $workbook->add_chart( embedded => 1  ,type => 'column' );
	$chart->show_blanks_as( 'span' );
	$chart->set_y_axis( name => 'Normalized quantification' );
	$chart->set_x_axis( name => 'Sample' );
	$chart->add_series(
	    categories => '='.$tmp_entete.'!$B$2:$B$'.($row),
	    values     => '='.$tmp_entete.'!$G$2:$G$'.($row),
  		points => @list
	);		
	$chart->set_legend( none => 1 );
	$worksheet->insert_chart( 'A'.($row+1), $chart, 3, 5, ($row/18), 3 );


	chop($string2);
	$string2.=' ] ';
	my @list2;
	eval '@list2 = ( '.$string2.');';
	my @split_tmp=split(" ",$entete);
	my $tmp=$split_tmp[0];
	my $string3=' [ ';
	foreach (sort keys %moyenne){
		my $groupe=$_;
		if ($groupe eq "1"){
			next;
		}
		#Average
		$worksheet = $workbook->add_worksheet($tmp_entete.'_Average');	
		$chart     = $workbook->add_chart( embedded => 1  ,type => 'column' );
		$chart->show_blanks_as( 'span' );
		$chart->set_y_axis( name => 'Normalized quantification' );
		$chart->set_x_axis( name => 'Group' );
		$row=0;$col=0;		
		$worksheet->write( $row, $col, "Group");$col++;	
		$worksheet->write( $row, $col, $tmp_entete." Average");$col++;
		$worksheet->write( $row, $col, "SEM");$col++;
		$worksheet->write( $row, $col, "pvalue");$col++;
		$worksheet->write( $row, $col, "Average Log2");$col++;	
		$worksheet->write( $row, $col, "SEM Log2");$col++;
		$worksheet->write( $row, $col, "pvalue Log2");$col++;
		$row++;$col=0;
		foreach (sort {$a <=> $b} keys %order_lot){
			my $lot=$order_lot{$_};
			my $tot=$moyenne{$groupe}{$lot}{"tot"};
			my $nb;
			my $moy;
			if (!defined($moyenne{$groupe}) || !defined($moyenne{$groupe}{$lot}) || !defined($moyenne{$groupe}{$lot}{"nb"})){
				$nb=0;
				$moy=0;
			}
			else{
				$nb=$moyenne{$groupe}{$lot}{"nb"};
				$moy=($tot/$nb);
			}

			my $totlog2=$moyenne{$groupe}{$lot}{"totlog2"};
			my $nblog2;
			my $moylog2;
			if (!defined($moyenne{$groupe}) || !defined($moyenne{$groupe}{$lot}) || !defined($moyenne{$groupe}{$lot}{"nblog2"})){
				$nblog2=0;
				$moylog2=0;
			}
			else{
				$nblog2=$moyenne{$groupe}{$lot}{"nblog2"};
				$moylog2=($totlog2/$nblog2);
			}
			my $valcarre=$moyenne{$groupe}{$lot}{"valcarre"};
			my $ecart_type =0;
			my $er_type;
			my $valcarrelog2=$moyenne{$groupe}{$lot}{"valcarrelog2"};
			my $ecart_typelog2 =0;
			my $er_typelog2;

			if ($nb!=0){
				if ($nb-1!=0){
				  $ecart_type = sqrt ( $valcarre/ ($nb-1));
				}
				$er_type = $ecart_type/ sqrt ($nb);

				if ($nblog2-1!=0){
				  $ecart_typelog2 = sqrt ( $valcarrelog2/ ($nblog2-1));
				}
				$er_typelog2= $ecart_typelog2/ sqrt ($nblog2);		

				$worksheet->write( $row, $col, $lot);$col++;							
				$worksheet->write( $row, $col, $moy);$col++;
				$worksheet->write( $row, $col, $er_type);$col++;	
				my $format = $workbook->add_format();
				if (defined($moyenne{$groupe}{$lot}{"pvalue_qte"}) && $moyenne{$groupe}{$lot}{"pvalue_qte"} ne "" && $moyenne{$groupe}{$lot}{"pvalue_qte"} ne "NA" && $moyenne{$groupe}{$lot}{"pvalue_qte"}<=0.05){
				  $format->set_bg_color( 'green' );	
				  $format->set_color( 'white' );	
				}
				$worksheet->write( $row, $col, $moyenne{$groupe}{$lot}{"pvalue_qte"},$format);$col++;
	
				$worksheet->write( $row, $col, $moylog2);$col++;
				$worksheet->write( $row, $col, $er_typelog2);$col++;
				$worksheet->write( $row, $col, $moyenne{$groupe}{$lot}{"pvalue_log2"});$col++;									
			}
			else{
				$worksheet->write( $row, $col, $lot);$col++;							
				$worksheet->write( $row, $col, "NA");$col++;
				$worksheet->write( $row, $col, "NA");$col++;					
				$worksheet->write( $row, $col, "NA");$col++;		
				$worksheet->write( $row, $col, "NA");$col++;					
				$worksheet->write( $row, $col, "NA");$col++;
				$worksheet->write( $row, $col, "NA");$col++;								
			}
			$row++;	$col=0;
			$string3.='{ fill => { color => \''.$colors{$lot}.'\' }},';
		}
		chop($string3);
		$string3.=' ] ';		
		my @list;
		eval '@list = ( '.$string3.');';		
		$chart->add_series(
		    categories => '='.$tmp_entete.'_Average!$A$2:$A$'.($row),
		    values     => '='.$tmp_entete.'_Average!$B$2:$B$'.($row),
			y_error_bars => {
			    type         => 'custom',
				plus_values  => '='.$tmp_entete.'_Average!$C$2:$C$'.($row),
			    minus_values => '='.$tmp_entete.'_Average!$C$2:$C$'.($row),
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
	      categories => '='.$tmp_entete.'_Average!$A$2:$A$'.($row),
	      data_labels => {value => 0},
	      values     => '='.$tmp_entete.'_Average!$E$2:$E$'.($row),
	      y_error_bars => {
		  type         => 'custom',
		      plus_values  => '='.$tmp_entete.'_Average!$F$2:$F$'.($row),
		  minus_values => '='.$tmp_entete.'_Average!$F$2:$F$'.($row),
	      },
	      points => 
	      @list
	    );	
	    $chart->set_legend( none => 1 );
	    $worksheet->insert_chart( 'H1', $chart, 2, 3, 2, 2 ); 
	}  
}
