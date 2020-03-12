#!/usr/bin/env perl
use Mojo::Base - strict;
use Mojo::File 'path';
use Mojo::Util qw (decode encode);

#read the whole file
my $txt_file = shift;
my $all      = decode('utf8', path($txt_file)->slurp);

#split into pargraphs
my @para_all = split m|\n{2,}|xsm, $all;

#say $para_all[0];
#split the life description from the criticism
my ($zitie, $kritika, $split) = ([], [], 0);
for my $p (@para_all) {
  if ($p =~ /^ПРОСТРАННО/) {
    $split++;
  }
  if ($split == 1) {
    push @$zitie, $p;
  }
  elsif ($split == 2) {
    push @$kritika, $p;
  }
}

#say for '-' x 80, $/, $zitie->[0], $kritika->[0];
#to header and paragraphs
my $title = $zitie->[0];
$zitie->[0] = "$/<h1>$zitie->[0]</h1>$/";
for my $p (1 .. @$zitie - 1) {

#convert numbers into links to end-notes
  if (my @notes = $zitie->[$p] =~ /(\d{1,2})/g) {

    #replace notes with links to them
    for my $n (@notes) {
      $zitie->[$p] =~ s/$n/<sup><a href="#_$n">$n<\/a><\/sup>/;
      for my $t (1 .. @$kritika - 1) {
        if ($kritika->[$t] =~ /^$n\./) {
          $kritika->[$t] = qq|$/<p id="_$n">$kritika->[$t]</p>$/|;
        }
      }
    }
    $zitie->[$p] = "$/<p>$zitie->[$p]</p>$/";

  }
}

#to header and paragraphs
$kritika->[0] = "$/<h1>$kritika->[0]</h1>$/";
for my $t (1 .. @$kritika - 1) {
  $kritika->[$t] = "$/<p>$kritika->[$t]</p>$/" unless $kritika->[$t] =~ /^<p/;
}
my $html_file = path($txt_file)->basename('.txt') . '.html';

say "writing to $html_file";

#write the file to html
path($html_file)->spurt(
  encode 'utf8',
  qq|
<!DOCTYPE html><html lang="bg_BG">
    <head>
        <meta http-equiv="content-type" content="text/html; charset=utf-8">
        <title>$title</title>
    </head>
    <body>
@$zitie

@$kritika
    <body>
</html>
|
);

