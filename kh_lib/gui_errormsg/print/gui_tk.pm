package gui_errormsg::print::gui_tk;
use strict;
use base qw(gui_errormsg::print);

# ���������ܥå���ɽ��
sub print{
	use Tk;
	my $self = shift;

	# ��Window��¸�ߤ��뤫�ɤ������ǧ
	my $window;
	if (Exists(${$self->{window}})){
		$window = ${$self->{window}};
	}
	elsif (Exists($::main_gui->mw)) {
		$window = $::main_gui->mw;
	}
	
	if ($window){
		$window->messageBox(
			-icon => $self->icon,
			-type => 'OK',
			-title => 'KH Coder',
			-message => gui_window->gui_jchar("$self->{msg}"),
		);
	} else {
		# use Win32;
		# Win32::MsgBox("$self->{msg}",'16','KH Coder');
		print "$self->{msg}\n";
	}

}

# �ǥե���ȤΥ�����������

sub icon{
	my $self = shift;
	if ($self->{icon}){
		return $self->{icon};
	} else {
		return 'warning';
	}
}


1;
