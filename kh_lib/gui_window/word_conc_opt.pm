package gui_window::word_conc_opt;
use base qw(gui_window);

use Tk;

#----------------#
#   Window����   #
#----------------#

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	#$win->focus;
	$win->title($self->gui_jt( kh_msg->get('win_title') )); # '�ɲþ�KWIC���󥳡�����'
	#$self->{win_obj} = $win;

	$win->Label(
		-text => kh_msg->get('preface1'),#$self->gui_jchar("���ֺ���������ˤ�����θ줬�и����Ƥ��뤳�ȡפȤ��������ɲäǤޤ���"),
		-font => "TKFN"
	)->pack(-anchor => 'w');
	$win->Label(
		-text => kh_msg->get('preface2'),#$self->gui_jchar("�������ɲä���ˤϡ��ޤ��ְ��֡פ���ꤷ�Ʋ�������"),
		-font => "TKFN"
	)->pack(-anchor => 'w');

	my @options = (
		[ kh_msg->get('0'),  '0'],#$self->gui_jchar('����ʤ�')
		[ kh_msg->get('rl'), 'rl'],#$self->gui_jchar('������1-5')
		[ kh_msg->get('l'),   'l'],#$self->gui_jchar('����1-5')
		[ kh_msg->get('r'),   'r'],#$self->gui_jchar('����1-5')
		[ kh_msg->get('l5'),     'l5'],
		[ kh_msg->get('l4'),     'l4'],
		[ kh_msg->get('l3'),     'l3'],
		[ kh_msg->get('l2'),     'l2'],
		[ kh_msg->get('l1'),     'l1'],
		[ kh_msg->get('r1'),     'r1'],
		[ kh_msg->get('r2'),     'r2'],
		[ kh_msg->get('r3'),     'r3'],
		[ kh_msg->get('r4'),     'r4'],
		[ kh_msg->get('r5'),     'r5']
	);

	#-----------#
	#   1����   #

	my $f2 = $win->LabFrame(
		-label => kh_msg->get('opt1'),#$self->gui_jchar('�ɲþ��1'),
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill=>'x');

	$f2->Label(
		-text => kh_msg->get('position'),#$self->gui_jchar('���֡�'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{menu1} = gui_widget::optmenu->open(
		parent   => $f2,
		pack     => {-anchor=>'e', -side => 'left'},
		options  => \@options,
		variable => \$self->{pos1},
		width    => 6,
		command  => sub{$self->_menu_check;}
	);
	
	$f2->Label(
		-text => kh_msg->get('word'),#$self->gui_jchar('����и졧'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{entry}{'1a'} = $f2->Entry(
		-font => "TKFN",
		-background => 'gray',
		-width => 14
	)->pack(-side => 'left');

	$f2->Label(
		-text => kh_msg->get('pos'),#$self->gui_jchar('���ʻ졧'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{entry}{'1b'} = $f2->Entry(
		-font => "TKFN",
		-background => 'gray',
		-width => 8
	)->pack(-side => 'left');

	$f2->Label(
		-text => kh_msg->get('conj'),#$self->gui_jchar('�����ѷ���'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{entry}{'1c'} = $f2->Entry(
		-font => "TKFN",
		-width => 8,
		-background => 'gray'
	)->pack(-side => 'left');
	
	#-----------#
	#   2����   #
	
	my $f3 = $win->LabFrame(
		-label => kh_msg->get('opt2'),#$self->gui_jchar('�ɲþ��2'),
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill=>'x');

	$f3->Label(
		-text => kh_msg->get('position'),#$self->gui_jchar('���֡�'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{menu2} = gui_widget::optmenu->open(
		parent   => $f3,
		pack     => {-anchor=>'e', -side => 'left'},
		options  => \@options,
		variable => \$self->{pos2},
		width    => 6,
		command  => sub{$self->_menu_check;}
	);

	$f3->Label(
		-text => kh_msg->get('word'),#$self->gui_jchar('����и졧'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{entry}{'2a'} = $f3->Entry(
		-font => "TKFN",
		-background => 'gray',
		-width => 14
	)->pack(-side => 'left');

	$f3->Label(
		-text => kh_msg->get('pos'),#$self->gui_jchar('���ʻ졧'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{entry}{'2b'} = $f3->Entry(
		-font => "TKFN",
		-background => 'gray',
		-width => 8
	)->pack(-side => 'left');

	$f3->Label(
		-text => kh_msg->get('conj'),#$self->gui_jchar('�����ѷ���'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{entry}{'2c'} = $f3->Entry(
		-font => "TKFN",
		-width => 8,
		-background => 'gray'
	)->pack(-side => 'left');
	
	#-----------#
	#   3����   #
	
	my $f4 = $win->LabFrame(
		-label => kh_msg->get('opt3'),#$self->gui_jchar('�ɲþ��3'),
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill=>'x');

	$f4->Label(
		-text => kh_msg->get('position'),#$self->gui_jchar('���֡�'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{menu3} = gui_widget::optmenu->open(
		parent   => $f4,
		pack     => {-anchor=>'e', -side => 'left'},
		options  => \@options,
		variable => \$self->{pos3},
		width    => 6,
		command  => sub{$self->_menu_check;}
	);

	$f4->Label(
		-text => kh_msg->get('word'),#$self->gui_jchar('����и졧'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{entry}{'3a'} = $f4->Entry(
		-font => "TKFN",
		-background => 'gray',
		-width => 14
	)->pack(-side => 'left');

	$f4->Label(
		-text => kh_msg->get('pos'),#$self->gui_jchar('���ʻ졧'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{entry}{'3b'} = $f4->Entry(
		-font => "TKFN",
		-background => 'gray',
		-width => 8
	)->pack(-side => 'left');

	$f4->Label(
		-text => kh_msg->get('conj'),#$self->gui_jchar('�����ѷ���'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{entry}{'3c'} = $f4->Entry(
		-font => "TKFN",
		-width => 8,
		-background => 'gray'
	)->pack(-side => 'left');
	
	$self->config_entry_focusin($self->{entry}{'1a'});
	$self->config_entry_focusin($self->{entry}{'1b'});
	$self->config_entry_focusin($self->{entry}{'1c'});

	$self->config_entry_focusin($self->{entry}{'2a'});
	$self->config_entry_focusin($self->{entry}{'2b'});
	$self->config_entry_focusin($self->{entry}{'2c'});

	$self->config_entry_focusin($self->{entry}{'3a'});
	$self->config_entry_focusin($self->{entry}{'3b'});
	$self->config_entry_focusin($self->{entry}{'3c'});

	# OK & Cancel
	$win->Button(
		-text => kh_msg->gget('cancel'),#$self->gui_jchar('����󥻥�'),
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->close;}
	)->pack(-side => 'right',-padx => 2);

	$win->Button(
		-text => kh_msg->gget('ok'),
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->save;}
	)->pack(-side => 'right');
	
	return $self;
}

sub start {
	my $self = shift;
	foreach my $i ('1a','1b','1c','2a','2b','2c','3a','3b','3c'){
		$self->{entry}{$i}
			->bind(
				"<Key>",
				[\&gui_jchar::check_key_e,Ev('K'),\$self->{entry}{$i}]
			);
		$self->{entry}{$i}
			->bind("<Key-Return>",sub{$self->save;});
		$self->{entry}{$i}
			->bind("<KP_Enter>",sub{$self->save;});
	}
	
	foreach my $n (1,2,3){
		if ($gui_window::word_conc::additional->{$n}{pos}){
			$self->{"menu"."$n"}->set_value(
				$gui_window::word_conc::additional->{$n}{pos}
			);
			$self->{entry}{"$n"."a"}->insert(
				'end',
				$self->gui_jchar($gui_window::word_conc::additional->{$n}{query}),
			);
			$self->{entry}{"$n"."b"}->insert(
				'end',
				$self->gui_jchar($gui_window::word_conc::additional->{$n}{hinshi})
			);
			$self->{entry}{"$n"."c"}->insert(
				'end',
				$self->gui_jchar($gui_window::word_conc::additional->{$n}{katuyo})
			);
		}
	}
	
	$self->_menu_check;
	#$self->{win_obj}->grab;
}

#----------------------#
#   Window�ξ����ѹ�   #

sub _menu_check{
	my $self = shift;
	foreach my $n (1,2,3){
		if ($self->{"pos$n"}) {
			foreach my $i ('a','b','c'){
				my $key = "$n"."$i";
				$self->{entry}{$key}->configure(
					-state      => 'normal',
					-background => 'white',
				);
			}
			if ($n + 1 <= 3){
				my $key = $n + 1;
				$key = "menu"."$key";
				$self->{$key}->configure(-state, 'normal');
			}
		} else {
			foreach my $i ('a','b','c'){
				my $key = "$n"."$i";
				$self->{entry}{$key}->configure(
					-state      => 'disable',
					-background => 'gray',
				);
				$self->disabled_entry_configure($self->{entry}{$key});
			}
			if ($n + 1 <= 3){
				my $key = $n + 1;
				$key = "menu"."$key";
				$self->{$key}->set_value(0);
				$self->{$key}->configure(-state, 'disable');
			}
		}
	}
}

#------------------#
#   Option����¸   #
#------------------#

sub save{
	my $self = shift;

	my $ad;
	foreach my $n (1,2,3){
		if ($self->{"pos$n"}) {
			$ad->{$n}{query}  = $self->check_entry_input( $self->{entry}{"$n"."a"}->get );
			#unless (length($ad->{$n}{query})){
			#	$ad->{$n} = undef;
			#	next;
			#}
			$ad->{$n}{pos} = $self->{"pos$n"};
			$ad->{$n}{hinshi} = $self->check_entry_input( $self->{entry}{"$n"."b"}->get );
			$ad->{$n}{katuyo} = $self->check_entry_input( $self->{entry}{"$n"."c"}->get );
		} else {
			$ad->{$n} = undef;
		}
	}
	
	$gui_window::word_conc::additional = $ad;
	$::main_gui->{'w_word_conc'}->btn_check;
	$self->close;
}


sub win_name{
	return 'w_word_conc_opt';
}

1;