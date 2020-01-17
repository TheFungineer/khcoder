package kh_morpho::perl::stemming::fr;
use strict;
use base qw( kh_morpho::perl::stemming );

sub init{
	my $self = shift;
	
	$self->{splitter} = Lingua::Sentence->new('fr');
	$self->{stemmer}  = Lingua::Stem::Snowball->new(
		lang     => 'fr',
		encoding => 'UTF-8'
	);
	
	return $self;
}

sub tokenize{
	my $self = shift;
	my $t    = shift;

	# ʸ������
	$t =~ s/(.+)(["|''|']{0,1}[\.|\!+|\?+|\!+\?|\?+\!+]["|''|']{0,1})\s*$/$1 $2/go;

	# �����
	$t =~ s/(\S),(\s|\Z)/$1 ,$2/go;

	# ���֥륯�����Ȥ䥫�å���
	$t =~ s/(''|``|"|\(|\)|\[|\]|\{|\})(\S)/$1 $2/go;
	$t =~ s/(\S)(''|``|"|\(|\)|\[|\]|\{|\})/$1 $2/go;

	# ���󥰥륯������
	$t =~ s/(\S)'(\s|\Z)/$1 '$2/go;
	$t =~ s/(\s|^)'(\S)/\$' $2/go;

	# �ե�󥹸���ͭ ��l'��ס�s'��ס�c'��ס�d'���
	$t =~ s/(\s|^)([l|s|c|d]')(\S)/$1$2 $3/gio;

	# ��ʣ���Ƥ��륹�ڡ�������
	$t =~ s/  */ /go;

	my @words_hyoso = split / /, $t;

	return(\@words_hyoso, undef);
}


1;
