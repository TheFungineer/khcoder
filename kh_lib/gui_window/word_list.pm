package gui_window::word_list;
use base qw(gui_window);

use strict;
use kh_cod::pickup;

my $radio_type  = 'def';
my $radio_num   = 'tf';
my $radio_ftype = 'xls';

#-------------#
#   GUI����   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt( kh_msg->get('win_title') )); # '��и�ꥹ�� - ���ץ����'

	#--------------#
	#   ɽ�η���   #

	my $lf0 = $win->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x');

	$lf0->Label(
		-text => kh_msg->get('type'),#$self->gui_jchar('��и�ꥹ�Ȥη�����'),
		-font => "TKFN",
	)->pack(-anchor => 'w');

	my $f1 = $lf0->Frame->pack(-fill => 'x');
	
	$f1->Label(
		-text => '   ',
		-font => "TKFN",
	)->pack(-side => 'left', -padx => 2);

	$f1->Radiobutton(
		-text             => kh_msg->get('hinshi'),#$self->gui_jchar('�ʻ���'),
		-font             => "TKFN",
		-variable         => \$radio_type,
		-value            => 'def',
	)->pack(-side => 'left', -padx => 4);

	$f1->Radiobutton(
		-text             => kh_msg->get('top150'),#$self->gui_jchar('�ѽ�150��'),
		-font             => "TKFN",
		-variable         => \$radio_type,
		-value            => '150',
	)->pack(-side => 'left', -padx => 4);

	$f1->Radiobutton(
		-text             => kh_msg->get('single'),#$self->gui_jchar('1��'),
		-font             => "TKFN",
		-variable         => \$radio_type,
		-value            => '1c',
	)->pack(-side => 'left', -padx => 4);

	#----------#
	#   ����   #

	$lf0->Label(
		-text => kh_msg->get('count'),#$self->gui_jchar('����������͡�'),
		-font => "TKFN",
	)->pack(-anchor => 'w');

	my $f2 = $lf0->Frame->pack(-fill => 'x');
	
	$f2->Label(
		-text => '   ',
		-font => "TKFN",
	)->pack(-side => 'left', -padx => 2);

	my $inv0 = $f2->Radiobutton(
		-text             => kh_msg->get('tf'),#$self->gui_jchar('�и������TF��'),
		-font             => "TKFN",
		-variable         => \$radio_num,
		-value            => 'tf',
		-command          => sub {
			$self->{tani_obj}->win_obj->configure(-state, 'disabled');
		},
	)->pack(-side => 'left', -padx => 4);

	$f2->Radiobutton(
		-text             => kh_msg->get('df'),#$self->gui_jchar('ʸ�����DF��'),
		-font             => "TKFN",
		-variable         => \$radio_num,
		-value            => 'df',
		-command          => sub {
			$self->{tani_obj}->win_obj->configure(-state, 'normal');
		},
	)->pack(-side => 'left', -padx => 4);

	$self->{tani_obj} = gui_widget::tani->open(
		parent => $f2,
		pack   => {
			-anchor => 'w',
			-pady   => 1,
			-side   => 'left'
		}
	);
	$self->{tani_obj}->win_obj->configure(-state, 'disabled')
		if $radio_num eq 'tf';

	#------------------#
	#   �ե��������   #

	$lf0->Label(
		-text => kh_msg->get('file_type'),#$self->gui_jchar('���Ϥ���ե�����η�����'),
		-font => "TKFN",
	)->pack(-anchor => 'w');

	my $f3 = $lf0->Frame->pack(-fill => 'x');
	
	$f3->Label(
		-text => '   ',
		-font => "TKFN",
	)->pack(-side => 'left', -padx => 2);

	$f3->Radiobutton(
		-text             => kh_msg->get('csv'),#$self->gui_jchar('����޶��ڤ� (*.csv)'),
		-font             => "TKFN",
		-variable         => \$radio_ftype,
		-value            => 'csv',
	)->pack(-side => 'left', -padx => 4);

	$f3->Radiobutton(
		-text             => kh_msg->get('xls'),#$self->gui_jchar('Excel (*.xls)'),
		-font             => "TKFN",
		-variable         => \$radio_ftype,
		-value            => 'xls',
	)->pack(-side => 'left', -padx => 4);


	$win->Button(
		-text => kh_msg->gget('cancel'),#$self->gui_jchar('����󥻥�'),
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->close;}
	)->pack(-side => 'right',-padx => 2);

	$win->Button(
		-text => kh_msg->gget('ok'),#'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->save;}
	)->pack(-side => 'right')->focus;
	
	return $self;
}

sub save{
	my $self = shift;
	my $target_file = mysql_words->word_list_custom(
		type  => $self->gui_jg( $radio_type  ),
		num   => $self->gui_jg( $radio_num   ),
		ftype => $self->gui_jg( $radio_ftype ),
		tani  => $self->{tani_obj}->tani,
	);
	$self->close;
	gui_OtherWin->open($target_file);
	
	return 1;
}

sub win_name{
	return 'w_word_list';
}

1;