#!/usr/local/bin/perl

use CGI;
use strict;
use utf8;
use Encode;

binmode STDOUT, ":utf8";

my $debug = 0;

my $q = new CGI; 

print
	$q->header(-charset => 'UTF-8'),
	$q->start_html('CiNii / Jstage Formatter'),
	$q->h1('CiNii / Jstage Formatter'),
	$q->h2('Description:'),
	$q->p(
		'CiNiiまたはJstageの論文URLを入力して実行すると、文献リスト掲載用のフォーマットに変換します。'
		.'<br>※現在は日本語文献にのみ対応。日本語文献でも未対応のパターンがあるかもしれません。'
	),

	$q->h2('Input:'),
	$q->start_form(),
	$q->textarea(
		-name=>'input',
		-default=>'',
		-rows=>10,
		-columns=>80
	),
	'<br>',

	$q->submit(
		-name=>'実行！',
		-value=>'実行！'
	),
	$q->end_form,
	'<div align="right"><a href="./">戻る</a></div>',
	<p>,
	$q->hr,
;

if ($q->param){
	print
		$q->h2('Output:')
	;
	
	my $output = '';
	
	use LWP::UserAgent;
	use HTTP::Request::Common;
	my $ua = LWP::UserAgent->new(
		agent      => 'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:39.0) Gecko/20100101 Firefox/39.0',
	);
	
	foreach my $i (split /\n/, $q->param('input')){
		chomp $i;
		$output .= "\nurl: $i\n" if $debug;;

		# CiNiiの場合
		if ( $i =~ /naid\/(\d+)/ ) {
			#$output .= "cinii\n";
			my $r = $ua->get("http://ci.nii.ac.jp/naid/$1.bib");
			$output .= &format( Encode::decode('UTF-8', $r->content) );
		}
		
		# CiNii Booksの場合
		if ( $i =~ /ncid\/BB(\d+)/ ) {
			$output .= "cinii books\n" if $debug;;
			my $r = $ua->get("http://ci.nii.ac.jp/ncid/BB$1.bib");
			$output .= Encode::decode('UTF-8', $r->content)."\n" if $debug;
			$output .= &format( Encode::decode('UTF-8', $r->content) );
		}
		
		# JSTAGEの場合
		if ($i =~ /jstage/ ) {
			$output .= "jstage\n"  if $debug;
			my $r = $ua->get($i);
			my $t = Encode::decode('UTF-8', $r->content);
			
			my $url = '';
			if ( $t =~ /<a href="(.+?)">BibTeX<\/a>/ ){
				$url = $1;
			} else {
				next;
			}
			
			$url =~ s/&amp;/&/g;
			$url =~ s/kijiLangKrke=en/kijiLangKrke=ja/;
			$url = 'http://www.jstage.jst.go.jp'.$url;
			
			my $r1 = $ua->get($url);
			$output .= &format( Encode::decode('UTF-8', $r1->content) );
		}
	}

	# 出力
	print $q->textarea(
		-name    =>'output',
		-default =>$output,
		-rows    =>10,
		-columns =>80
	),
}

sub format{
	my $t = shift;

	my $year     ;
	my $author   ;
	my $title    ;
	my $journal  ;
	my $vol      ;
	my $num      ;
	my $pages    ;
	my $doi      ;
	my $publisher;
	my $series   ;
	
	
	if ($t =~ /year\s*=\s*"(\d+)",/ || $t =~ /year=\{(\d+)\},/) {
		$year = $1;
	}
	if ($t =~ /author\s*=\s*"(.+?)",/ || $t =~ /author=\{(.+?)\},/) {
		$author = $1;
		$author =~ s/ and /・/g;
		$author =~ s/, //g;
		$author =~ s/ //g;
	}
	if ($t =~ /title\s*=\s*"(.+?)",/ || $t =~ /title=\{(.+?)\},/) {
		$title = $1;
		if ($title =~ /(.+) : (.+)/) {
			$title = $1.' ―'.$2.'―';
		}
		if ($title =~ /<b>(.+)<\/b>$/) {
			$title = $1;
		}
		if ($title =~ /(.+)\s$/) {
			$title = $1;
		}
	}
	if ($t =~ /journal\s*=\s*"(.+?)",/ || $t =~ /journal=\{(.+?)\},/) {
		$journal = $1;
		if ($journal =~ /(.+) = [a-zA-Z ]+/) {
			$journal = $1;
		}
		
	}
	if ($t =~ /volume\s*=\s*"(.+?)",/ || $t =~ /volume=\{(.+?)\},/) {
		$vol = $1;
	}
	if ($t =~ /number\s*=\s*"(.+?)",/ || $t =~ /number=\{(.+?)\},/) {
		$num = $1;
		if ($num eq ' ') {
			$num = '';
		}
		
	}
	if ($t =~ /pages\s*=\s*"(.+?)",/ || $t =~ /pages=\{(.+?)\},/) {
		$pages = $1;
	}
	if ($t =~ /doi\s*=\s*"(.+?)"/ || $t =~ /doi=\{(.+?)\}/) {
		$doi = $1;
	}
	if ($t =~ /publisher\s*=\s*"(.+?)"/ || $t =~ /publisher=\{(.+?)\}/) {
		$publisher = $1;
	}
	if ($t =~ /series\s*=\s*"(.+?)"/ || $t =~ /series=\{(.+?)\}/) {
		$series = $1;
	}
	
	
	my $mode = 'journal';
	if ( $title and not $journal ){
		$mode = 'book';
	}
	
	
	my $out = '';
	$out .= "$mode\n" if $debug;
	
	if ($mode eq 'journal'){
		$out .=
			"$author $year 「$title"
			."」 『$journal"
			."』 "
		;
		
		if ( $num and not $vol ) {
			$vol = $num;
			$num = '';
		}
		
		if ($vol) {
			$out .= $vol;
		}
		if ($num ) {
			$out .= "($num)";
		}
		if ($pages) {
			$out .= ": $pages";
		}
		if ($doi) {
			$out .= ", doi: $doi";
		}
	} else {
		$title .= '（'.$series.'）';
		$out .=
			"$author $year 『$title"
			."』 $publisher"
		;
	}

	$out .= "\n";
	return $out;
}