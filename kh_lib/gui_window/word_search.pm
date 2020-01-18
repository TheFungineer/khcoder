package gui_window::word_search;
use base qw(gui_window);
use vars qw($method $kihon $katuyo);
use strict;
use Tk;
use Tk::HList;
use Tk::Balloon;
#use NKF;

use mysql_words;
use gui_widget::optmenu;

#---------------------#
#   Window �����ץ�   #
#---------------------#

sub _new{
	my $self = shift;
	
	my $mw = $::main_gui->mw;
	my $wmw= $self->{win_obj};
	#$wmw->focus;
	$wmw->title($self->gui_jt( kh_msg->get('win_title') )); # '��и측��'

	my $fra4 = $wmw->LabFrame(
		-label => 'Search Entry',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill=>'x');

	# ����ȥ�ȸ����ܥ���Υե졼��
	my $fra4e = $fra4->Frame()->pack(-expand => 'y', -fill => 'x');

	my $e1 = $fra4e->Entry(
		-font => "TKFN",
		-background => 'white'
	)->pack(-expand => 'y', -fill => 'x', -side => 'left');
	$wmw->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);
	$e1->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e1]);
	$e1->bind("<Key-Return>",sub{$self->search;});
	$e1->bind("<KP_Enter>",sub{$self->search;});
	$self->config_entry_focusin($e1);

	my $sbutton = $fra4e->Button(
		-text => kh_msg->get('search'),#$self->gui_jchar('����'),
		-font => "TKFN",
		-command => sub{$self->search;}
	)->pack(-side => 'right', -padx => '2');

	my $blhelp = $wmw->Balloon();
	$blhelp->attach(
		$sbutton,
		-balloonmsg => '"ENTER" key',
		-font => "TKFN"
	);

	# ���ץ���󡦥ե졼��
	my $fra4h = $fra4->Frame->pack(-expand => 'y', -fill => 'x');

	$fra4h->Checkbutton(
		-text     => kh_msg->get('baseform'),#$self->gui_jchar('��и측��'),
		-variable => \$gui_window::word_search::kihon,
		-font     => "TKFN",
		-command  => sub{$self->refresh;}
	)->pack(-side => 'left');

	$self->{the_check} = $fra4h->Checkbutton(
		-text     => kh_msg->get('view_conj'),#$self->gui_jchar('���ѷ���ɽ��'),
		-variable => \$gui_window::word_search::katuyo,
		-font     => "TKFN",
		-command  => sub{$self->refresh;}
	)->pack(-side => 'left');

	unless (defined($gui_window::word_search::katuyo)){
		$gui_window::word_search::kihon = 1;
		$gui_window::word_search::katuyo = 1;
	}
	
	my $fra4i = $fra4->Frame->pack(-expand => 'y', -fill => 'x');

	$self->{optmenu_andor} = gui_widget::optmenu->open(
		parent  => $fra4i,
		pack    => {-anchor=>'e', -side => 'left', -padx => 2},
		#width   => 7,
		options =>
			[
				[kh_msg->get('or') , 'OR'], # $self->gui_jchar('OR����')
				[kh_msg->get('and'), 'AND'], # $self->gui_jchar('AND����')
			],
		variable => \$gui_window::word_search::method,
	);

	$self->{optmenu_bk} = gui_widget::optmenu->open(
		parent  => $fra4i,
		pack    => {-anchor=>'e', -side => 'left', -padx => 12},
		#width   => 8,
		options =>
			[
				[kh_msg->get('part') => 'p'], # $self->gui_jchar('��ʬ����')
				[kh_msg->get('comp') => 'c'], # $self->gui_jchar('��������')
				[kh_msg->get('forw') => 'z'], # $self->gui_jchar('��������')
				[kh_msg->get('back') => 'k'] #$self->gui_jchar('��������')
			],
		variable => \$gui_window::word_search::s_mode,
	);


	# ���ɽ����ʬ
	my $fra5 = $wmw->LabFrame(
		-label => 'Result',
		-labelside => 'acrosstop',
		-borderwidth => 2
	)->pack(-expand=>'yes',-fill=>'both');

	my $hlist_fra = $fra5->Frame()->pack(-expand => 'y', -fill => 'both');

	my $lis = $hlist_fra->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 1,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 3,
		-padx             => 2,
		-background       => 'white',
		-selectforeground   => $::config_obj->color_ListHL_fore,
		-selectbackground   => $::config_obj->color_ListHL_back,
		-selectborderwidth  => 0,
		-highlightthickness => 0,
		-selectmode       => 'extended',
		-command          => sub {$self->conc;},
		#-height           => 20,
	)->pack(-fill =>'both',-expand => 'yes');

	$lis->header('create',0,-text => kh_msg->get('word')); # $self->gui_jchar('��и�')
	$lis->header('create',1,-text => kh_msg->get('pos')); # $self->gui_jchar('�ʻ�')
	$lis->header('create',2,-text => kh_msg->get('freq')); # $self->gui_jchar('����')

	$self->{copy_btn} = $fra5->Button(
		-text => kh_msg->gget('copy'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {gui_hlist->copy($self->list);}
	)->pack(-side => 'right');

	$self->win_obj->bind(
		'<Control-Key-c>',
		sub{ $self->{copy_btn}->invoke; }
	);
	$self->win_obj->Balloon()->attach(
		$self->{copy_btn},
		-balloonmsg => 'Ctrl + C',
		-font => "TKFN"
	);

	$self->{conc_button} = $fra5->Button(
		-text => kh_msg->get('kwic'),#$self->gui_jchar('���󥳡�����'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {$self->conc;}
	)->pack(-side => 'left');
	
	$self->{list_f} = $hlist_fra;
	$self->{list}  = $lis;
	#$self->{win_obj} = $wmw;
	$self->{entry}   = $e1;
	$self->refresh;
	return $self;
}

#--------------------#
#   ɽ�����ڤ��ؤ�   #
#--------------------#

sub refresh{
	my $self = shift;
	
	# �����å��ܥå������ڤ��ؤ�
	if ($gui_window::word_search::kihon){
		$self->the_check->configure(-state,'normal');
		$self->conc_button->configure(-state,'normal');
	} else {
		$self->the_check->configure(-state,'disable');
		$self->conc_button->configure(-state,'disable');
	}
	
	# �ꥹ�Ȥ��ڤ��ؤ�
	if ($gui_window::word_search::kihon){
		$self->list->destroy;
		
		$self->{list} = $self->list_f->Scrolled(
			'HList',
			-scrollbars       => 'osoe',
			-header           => 1,
			-itemtype         => 'text',
			-font             => 'TKFN',
			-columns          => 3,
			-indent           => 20,
			-padx             => 2,
			-background       => 'white',
			-selectforeground   => $::config_obj->color_ListHL_fore,
			-selectbackground   => $::config_obj->color_ListHL_back,
			-selectborderwidth  => 0,
			-highlightthickness => 0,
			-selectmode       => 'extended',
			-command          => sub {$self->conc;},
		)->pack(-fill =>'both',-expand => 'yes');
		$self->list->header('create',0,-text => kh_msg->get('word'));#$self->gui_jchar('��и�')
		if ( $gui_window::word_search::katuyo ){
			$self->list->header('create',1,-text => kh_msg->get('pos_conj'));#$self->gui_jchar('�ʻ�/����')
		} else {
			$self->list->header('create',1,-text => kh_msg->get('pos'));#$self->gui_jchar('�ʻ�')
		}
		$self->list->header('create',2,-text => kh_msg->get('freq'));#$self->gui_jchar('����')
	} else {
		$self->list->destroy;
		$self->{list} = $self->list_f->Scrolled(
			'HList',
			-scrollbars       => 'osoe',
			-header           => 1,
			-itemtype         => 'text',
			-font             => 'TKFN',
			-columns          => 4,
			-padx             => 2,
			-background       => 'white',
			-selectforeground   => $::config_obj->color_ListHL_fore,
			-selectbackground   => $::config_obj->color_ListHL_back,
			-selectborderwidth  => 0,
			-highlightthickness => 0,
			-selectmode       => 'extended',
		)->pack(-fill =>'both',-expand => 'yes');
		$self->list->header('create',0,-text => kh_msg->get('morph'));#$self->gui_jchar('������')
		$self->list->header('create',1,-text => kh_msg->get('pos'));#$self->gui_jchar('�ʻ����䥡�')
		$self->list->header('create',2,-text => kh_msg->get('conj'));#$self->gui_jchar('����')
		$self->list->header('create',3,-text => kh_msg->get('freq'));#$self->gui_jchar('����')
	}
	$self->list->update;
}


#----------#
#   ����   #
#----------#

sub search{
	my $self = shift;
	
	# �ѿ�����
	my $query = $self->gui_jg( $self->entry->get );

	unless ($query){
		return;
	}

	# �����¹�
	my $result = mysql_words->search(
		query  => $query,
		method => $gui_window::word_search::method,
		kihon  => $gui_window::word_search::kihon,
		katuyo => $gui_window::word_search::katuyo,
		mode   => $gui_window::word_search::s_mode
	);

	# ���ɽ��
	
	my $numb_style = $self->list->ItemStyle(
		'text',
		-anchor => 'e',
		-background => 'white',
		-font => "TKFN"
	);
	
	$self->list->delete('all');
	my $row = 0;
	my $last;
	foreach my $i (@{$result}){
		my $cu;
		if ( $i->[0] eq 'katuyo' ){
			$cu = $self->list->addchild($last);
			shift @{$i};
		} else {
			$cu = $self->list->add($row,-at => "$row");
			$last = $cu;
		}
		my $col = 0;
		foreach my $h (@{$i}){
			if ($h =~ /^[0-9]+$/o && $col > 0){
				$self->list->itemCreate(
					$cu,
					$col,
					-text  => $h,
					-style => $numb_style
				);
			} else {
				$self->list->itemCreate($cu,$col,-text => $self->gui_jchar($h));
			}
			++$col;
		}
		++$row;
	}
	$self->{last_search} = $result;
	
	gui_hlist->update4scroll($self->list);
}

#----------------------------#
#   ���󥳡����󥹸ƤӽФ�   #
#----------------------------#
sub conc{
	use gui_window::word_conc;
	my $self = shift;
	unless ($gui_window::word_search::kihon){
		return 0;
	}
	
	# �ѿ�����
	my @selected = $self->list->infoSelection;
	unless(@selected){
		return;
	}
	my $selected = $selected[0];
	my $result = $self->last_search;
	my ($query, $hinshi, $katuyo);
	if (index($selected,'.') > 0){
		my ($parent, $child) = split /\./, $selected;
		$query = $self->gui_jchar($result->[$parent][0]);
		$hinshi = $self->gui_jchar($result->[$parent][1]);
		$katuyo = $self->gui_jchar($result->[$parent + $child + 1][1]);
		substr($katuyo,0,3) = ''
	} else {
		$query = $self->gui_jchar($result->[$selected][0]);
		$hinshi = $self->gui_jchar($result->[$selected][1]);
	}

	# ���󥳡����󥹤θƤӽФ�
	my $conc = gui_window::word_conc->open;
	$conc->entry->delete(0,'end');
	$conc->entry4->delete(0,'end');
	$conc->entry2->delete(0,'end');
	$conc->entry->insert('end',$query);
	$conc->entry4->insert('end',$hinshi);
	$conc->entry2->insert('end',$katuyo);
	$conc->search;
}

#--------------#
#   ��������   #
#--------------#

sub list{
	my $self = shift;
	return $self->{list};
}
sub entry{
	my $self = shift;
	return $self->{entry};
}
sub win_name{
	return 'w_word_search';
}
sub the_check{
	my $self = shift;
	return $self->{the_check};
}
sub list_f{
	my $self = shift;
	return $self->{list_f};
}
sub last_search{
	my $self = shift;
	return $self->{last_search};
}
sub conc_button{
	my $self = shift;
	return $self->{conc_button};
}
sub start{
	my $self = shift;
	$self->entry->focus;
}

1;
