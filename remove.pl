#!/usr/bin/perl
use strict;
use warnings;
use Statistics::TTest;

# Données de l'échantillon 1 (à remplacer par vos propres données)
my @array1 =  (18, 19, 21, 20, 17, 22, 20, 19, 23, 20);

# Données de l'échantillon 2 (à remplacer par vos propres données)
my @array2 = (18, 19, 21, 20, 17, 22, 20, 19, 23, 20);

# Créer un objet Statistics::TTest
my $ttest = Statistics::TTest->new();

# Charger les données
$ttest->load_data(\@array1, \@array2);

# Effectuer le test t et obtenir la valeur p
my $pvalue = $ttest->t_prob();

# Afficher la valeur p
print "La valeur p est : $pvalue\n";