package gui_window::bayes_predict;
use base qw(gui_window);

use strict;
use Jcode;

#-------------#
#   GUI����   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt(kh_msg->get('win_title'))); # �ؽ���̤��Ѥ�����ưʬ��

	my $lf = $win->LabFrame(
		-label => 'Entry',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x');

	# ʬ��ñ�̤λ���
	my $f2 = $lf->Frame()->pack(-expand => 'y', -fill => 'x', -pady => 3);
	$f2->Label(
		-text => kh_msg->get('unit'), # ʬ���ñ�̡�
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');
	my %pack = (
			-anchor => 'e',
			-pady   => 1,
			-side   => 'left'
	);
	$self->{tani_obj} = gui_widget::tani->open(
		parent => $f2,
		pack   => \%pack
	);

	# �ե�����̾�λ���
	my $fra4e = $lf->Frame()->pack(-expand => 'y', -fill => 'x',-pady => 3);
	
	$fra4e->Label(
		-text => kh_msg->get('model_file'), # �ؽ���̥ե����롧
		-font => "TKFN",
	)->pack(-side => 'left');
	
	$fra4e->Button(
		-text    => kh_msg->gget('browse'), # ����
		-font    => "TKFN",
		-command => sub { $self->file; },
	)->pack(-side => 'left');
	
	$self->{entry} = $fra4e->Entry(
		-font  => "TKFN",
		-width => 20,
		-background => 'white'
	)->pack(-side => 'left',-padx => 2, -fill => 'x', -expand => 1);

	$self->{entry}->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $self->{entry},],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);
	

	# �ѿ�̾�λ���
	my $fra4g = $lf->Frame()->pack(-expand => 'y', -fill => 'x', -pady =>3);
	$fra4g->Label(
		-text => kh_msg->get('var_name'), # �ѿ�̾��
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');

	$self->{entry_ovn} = $fra4g->Entry(
		-font  => "TKFN",
		-width => 20,
		-background => 'white'
	)->pack(-padx => 2, -fill => 'x', -expand => 1);

	$self->{entry_ovn}->bind("<Key-Return>",sub{$self->_calc;});
	$self->{entry_ovn}->bind("<KP_Enter>",sub{$self->_calc;});

	$lf->Label(
		-text => kh_msg->get('var_desc'), #     ��ʬ��η�̤ϳ����ѿ��Ȥ�����¸����ޤ���
		-font => "TKFN"
	)->pack(-anchor => 'w');

	my $lff = $win->Frame()->pack(-fill => 'x', -expand => 0);
	$self->{chkw_savelog} = $lff->Checkbutton(
			-text     => kh_msg->get('save_log'), # ʬ�����ե��������¸
			-variable => \$self->{check_savelog},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	$win->Button(
		-text => kh_msg->gget('cancel'), # ����󥻥�
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->withd;}
	)->pack(-side => 'right',-padx => 2);

	$win->Button(
		-text => kh_msg->gget('ok'),
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->_calc;}
	)->pack(-side => 'right');
	
	return $self;
}

sub file{
	my $self = shift;

	my @types = (
		[ "KH Coder: Naive Bayes Moldels",[qw/.knb/] ],
		["All files",'*']
	);
	
	my $path = $self->win_obj->getOpenFile(
		-filetypes  => \@types,
		-title      => $self->gui_jt(kh_msg->get('opening_model')), # �ؽ���̥ե���������򤷤Ƥ�������
		-initialdir => $self->gui_jchar($::config_obj->cwd),
	);
	if ($path){
		$path = $self->gui_jg_filename_win98($path);
		$path = $self->gui_jg($path);
		$self->{entry}->delete(0, 'end');
		$self->{entry}->insert('0',$self->gui_jchar("$path"));
	}
	return 1;
}

sub start{
	my $self = shift;

	# Window���Ĥ���ݤΥХ����
	$self->win_obj->bind(
		'<Control-Key-q>',
		sub{ $self->withd; }
	);
	$self->win_obj->bind(
		'<Key-Escape>',
		sub{ $self->withd; }
	);
	$self->win_obj->protocol('WM_DELETE_WINDOW', sub{ $self->withd; });
}

#----------------#
#   �����μ¹�   #

sub _calc{
	my $self = shift;

	# ���ϥ����å�
	my $path_i = $self->gui_jg( $self->{entry}->get );
	$path_i= $::config_obj->os_path($path_i);
	unless (-e $path_i ){
		gui_errormsg->open(
			type   => 'msg',
			msg    => kh_msg->get('er_no_such_file'), # �ե���������������ꤷ�Ʋ�������
			window => \$self->{win_obj},
		);
		return 0;
	}
	
	unless ( length( $self->gui_jg($self->{entry_ovn}->get) ) ){
		gui_errormsg->open(
			type   => 'msg',
			msg    => kh_msg->get('er_specify_name'), # �ѿ�̾����ꤷ�Ʋ�������
			window => \$self->{win_obj},
		);
		return 0;
	}
	
	my $var_new = $self->gui_jg($self->{entry_ovn}->get);
	
	my $chk = mysql_outvar::a_var->new($var_new);
	if ( defined($chk->{id}) ){
		gui_errormsg->open(
			type   => 'msg',
			msg    => kh_msg->get('er_exists'), # ���ꤵ�줿̾�����ѿ������Ǥ�¸�ߤ��ޤ���
			window => \$self->{win_obj},
		);
		return 0;
	}

	# ��¸��λ���
	my $path;
	if ($self->{check_savelog}) {
		my @types = (
			[ "KH Coder: Naive Bayes logs",[qw/.nbl/] ],
			["All files",'*']
		);

		$path = $self->win_obj->getSaveFile(
			-defaultextension => '.nbl',
			-filetypes        => \@types,
			-title            =>
				$self->gui_jt(kh_msg->get('saving_log')), # ʬ�����ե��������¸
			-initialdir       => $self->gui_jchar($::config_obj->cwd),
		);
	}
	if ($path){
		$path = gui_window->gui_jg_filename_win98($path);
		$path = gui_window->gui_jg($path);
		$path = $::config_obj->os_path($path);
	}

	my $ans = $self->win_obj->messageBox(
		-message => kh_msg->gget('cont_big_pros'),
		-icon    => 'question',
		-type    => 'OKCancel',
		-title   => 'KH Coder'
	);
	unless ($ans =~ /ok/i){ return 0; }

	my $wait_window = gui_wait->start;

	use kh_nbayes;

	kh_nbayes->predict(
		path      => $path_i,
		tani      => $self->tani,
		outvar    => $var_new,
		save_log  => $self->{check_savelog},
		save_path => $path,
	);

	$wait_window->end(no_dialog => 1);

	# �ֳ����ѿ��ꥹ�ȡפ򳫤�
	my $win_list = gui_window::outvar_list->open;
	$win_list->_fill;

	$self->withd;
}



#--------------#
#   ��������   #


sub tani{
	my $self = shift;
	return $self->{tani_obj}->tani;
}

sub win_name{
	return 'w_bayes_predict';
}

1;
