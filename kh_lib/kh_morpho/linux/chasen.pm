package kh_morpho::linux::chasen;
use strict;
use base qw( kh_morpho::linux );

#--------------------#
#   ��䥤μ¹Դط�   #
#--------------------#

sub _run_morpho{
	my $self = shift;

	unless (-e $::config_obj->chasenrc_path){
		gui_errormsg->open(
			msg  => kh_msg->get('error_confg'),
			type => 'msg'
		);
		exit;
	}

	#print "ENV: $::ENV{DYLD_FALLBACK_LIBRARY_PATH}\n\n";
	#system "printenv";
	#print "\n\n";

	my $cmdline = "chasen -r ".$::config_obj->chasenrc_path." -o ".$self->output." ".$self->target;
	#print "$cmdline\n";

	system "$cmdline";

	return(1);
}

sub exec_error_mes{
	return kh_msg->get('error');
}


1;
