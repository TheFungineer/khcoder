package kh_sysconfig::linux::chasen;
use strict;
use base qw(kh_sysconfig::linux);
use gui_errormsg;

sub config_morph{
	my $self = shift;
	
	# Grammer.cha�ե�������ѹ�

	unless (-e $self->grammarcha_path){
		return 0;
	}
	# �ɤ߹���
	my $grammercha = $self->grammarcha_path;
	my $temp = ''; my $khflg = 0;
	open (GRA,"$grammercha") or
		gui_errormsg->open(
			type    => 'file',
			thefile => $grammercha
		);
	while (<GRA>){
		chomp;
		if ($_ eq '; by KH Coder, start.'){
			$khflg = 1;
			next;
		}
		elsif ($_ eq '; by KH Coder, end.'){
			$khflg = 0;
			next;
		}
		if ($khflg){
			next;
		} else {
			$temp .= "$_\n";
		}
	}
	close (GRA);
	
	# �Խ�
	my $temp2 = '(ʣ��̾��)'."\n".'(����)'."\n";
#	Jcode::convert(\$temp2,'sjis','euc');
	$temp .= "\n".'; by KH Coder, start.'."\n"."$temp2".'; by KH Coder, end.';

	# �񤭽Ф�
	my $temp_file = 'temp.txt';
	while (-e $temp_file){
		$temp_file .= '.tmp';
	}
	open (GRAO,">$temp_file") or
		gui_errormsg->open(
			type    => 'file',
			thefile => "$temp_file"
		);
	print GRAO "$temp";
	close (GRAO);

	unlink $grammercha;
	rename ($temp_file,$grammercha);

	# chasen.rc�ե�������ѹ�
	
	unless (-e $self->chasenrc_path){
		return 0;
	}
	# �ɤ߹���
	my $chasenrc = $self->chasenrc_path;
	$temp = ''; $khflg = 0;
	open (GRA,"$chasenrc") or
		gui_errormsg->open(
			type    => 'file',
			thefile => "$chasenrc"
		);
	while (<GRA>){
		chomp;
		if ($_ eq '; by KH Coder, start.'){
			$khflg = 1;
			next;
		}
		elsif ($_ eq '; by KH Coder, end.'){
			$khflg = 0;
			next;
		}
		if ($khflg){
			next;
		} else {
			$temp .= "$_\n";
		}
	}
	close (GRA);
	
	# �Խ�
	$temp2 = '(��� (("<" ">") (����)) )'."\n";
	if ($self->{use_hukugo}){
		$temp2 .= $self->hukugo_chasenrc;
	}
#	Jcode::convert(\$temp2,'sjis','euc');
	$temp .= "\n".'; by KH Coder, start.'."\n"."$temp2".'; by KH Coder, end.';

	# �񤭽Ф�
	$temp_file = 'temp.txt';
	while (-e $temp_file){
		$temp_file .= '.tmp';
	}
	open (GRAO,">$temp_file") or
		gui_errormsg->open(
			type    => 'file',
			thefile => "$temp_file"
		);
	print GRAO "$temp";
	close (GRAO);
	unlink $chasenrc;
	rename ("$temp_file","$chasenrc");
}

sub path_check{
	my $self = shift;
	if (-e $self->chasenrc_path && -e $self->grammarcha_path){
		return 1;
	} else {
		return 0;
	}
}

1;
