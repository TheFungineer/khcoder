package gui_window::cod_out::tab;
use base qw(gui_window::cod_out);

use strict;

sub _save{
	my $self = shift;
	
	unless (-e $self->cfile){
		my $win = $self->win_obj;
		gui_errormsg->open(
			msg => kh_msg->get('gui_window::cod_count->error_cod_f'), #"�����ǥ��󥰡��롼�롦�ե����뤬���򤵤�Ƥ��ޤ���",
			window => \$win,
			type => 'msg',
		);
		return;
	}
	
	# ��¸��λ���
	my @types = (
		[ kh_msg->get('tab_delimited'),[qw/.txt/] ], # ���ֶ��ڤ�
		["All files",'*']
	);
	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.txt',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt(kh_msg->get('save_as')), # �����ǥ��󥰷�̡�̾�����դ�����¸
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);
	
	# ��¸��¹�
	if ($path){
		$path = gui_window->gui_jg_filename_win98($path);
		$path = gui_window->gui_jg($path);
		$path = $::config_obj->os_path($path);
		my $result;
		unless ( $result = kh_cod::func->read_file($self->cfile) ){
			return 0;
		}
		$result->cod_out_tab($self->tani,$path);
	}
	
	$self->close;
}

sub win_label{
	return kh_msg->get('win_title'); # �����ǥ��󥰷�̤ν��ϡ� ���ֶ��ڤ�
}

sub win_name{
	return 'w_cod_save_tab';
}
1;