package gui_errormsg::file;
use strict;
use base qw(gui_errormsg);

sub get_msg{
	my $self = shift;
	my $msg = kh_msg->get('could_not_open_the_file'); # �ե�����򳫤��ޤ���Ǥ�����\nKH Coder��λ���ޤ���\n*
	$msg .= gui_window->gui_jchar( $self->{thefile} );
	
	return $msg;
}

1;