package gui_window::cod_jaccard;
use base qw(gui_window);

use strict;

my $debug_ms = 0;

#-------------#
#   GUI����   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	#$win->focus;
	$win->title($self->gui_jt(kh_msg->get('win_title'))); # �����ǥ��󥰡�����ٹ����Jaccard������

	#------------------------#
	#   ���ץ����������ʬ   #

	my $lf = $win->LabFrame(
		-label => 'Entry',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x');
	
	# �롼�롦�ե�����
	my %pack0 = (-side => 'left');
	$self->{codf_obj} = gui_widget::codf->open(
		parent => $lf,
		pack   => \%pack0
	);
	# �����ǥ���ñ��
	$lf->Label(
		-text => kh_msg->get('unit_cod'), # �������ǥ���ñ�̡�
		-font => "TKFN",
	)->pack(-side => 'left');
	$self->{tani_obj} = gui_widget::tani->open(
		parent => $lf,
		pack   => \%pack0,
	);

	$lf->Button(
		-text    => kh_msg->get('gui_window::cod_outtab->run'), # ����
		-font    => "TKFN",
		-width   => 8,
		-command => sub{$self->_calc;}
	)->pack( -anchor => 'e', -side => 'right');
	
	#------------------#
	#   ���ɽ����ʬ   #

	my $rf = $win->LabFrame(
		-label => 'Result',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both',-expand => 'yes',-anchor => 'n');

	$self->{list_flame} = $rf->Frame()->pack(-fill => 'both',-expand => 1);
	
	$self->{list} = $self->{list_flame}->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 0,
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
		-height           => 10,
	)->pack(-fill =>'both',-expand => 'yes');

	$self->{label} = $rf->Label(
		-text       => 'Ready.',
		-font       => "TKFN",
		-foreground => 'blue'
	)->pack(-side => 'left');

	$self->{btn_copy} = $rf->Button(
		-text => kh_msg->gget('copy_all'), # ���ԡ���ɽ���Ρ�
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub { $self->copy; }
	)->pack(-anchor => 'e', -pady => 1, -side => 'right');

	$self->win_obj->bind(
		'<Control-Key-c>',
		sub{ $self->{btn_copy}->invoke; }
	);
	$self->win_obj->Balloon()->attach(
		$self->{btn_copy},
		-balloonmsg => 'Ctrl + C',
		-font => "TKFN"
	);

	return $self;
}

#------------------#
#   ���ץ롼����   #

sub _calc{
	my $self = shift;
	$self->label->configure(
		-text => 'Counting...',
		-foreground => 'red'
	);
	$self->win_obj->update;

	# �������ƥ����å�
	unless (
		   $self->tani
		&& -e $self->cfile
	){
		my $win = $self->win_obj;
		gui_errormsg->open(
			msg => kh_msg->get('gui_window::cod_count->error_cod_f'), # "�����ǥ��󥰥롼�롦�ե��������ꤷ�Ʋ�������",
			window => \$win,
			type => 'msg',
		);
		$self->rtn;
		return 0;
	}
	
	# ���פμ¹�
	my $result;
	unless ($result = kh_cod::func->read_file($self->cfile)){
		$self->rtn;
		return 0;
	}
	#if ($self->{prox_opt} eq 'jac'){
		unless ( $result = $result->jaccard($self->tani) ){
			$self->rtn;
			return 0;
		}
	#} else {
	#	unless ( $result = $result->jaccard_a($self->tani) ){
	#		$self->rtn;
	#		return 0;
	#	}
	#}

	# ���ɽ���Ѥ�HList����
	my $cols = @{$result->[0]};
	my $width = 0;
	foreach my $i (@{$result}){
		if ( length($i->[0]) > $width ){
			$width = length($i->[0]);
		}
	}
	$width = $width * 2;

	$self->{list}->destroy if $self->{list};                # �Ť���Τ��Ѵ�
	$self->{list2}->destroy if $self->{list2};
	$self->{sb1}->destroy if $self->{sb1};
	$self->{sb2}->destroy if $self->{sb2};
	$self->{list_flame_inner}->destroy if $self->{list_flame_inner};

	$self->{list_flame_inner} = $self->{list_flame}->Frame( # �����ʥꥹ�Ⱥ���
		-relief      => 'sunken',
		-borderwidth => 2
	);
	$self->{list2} = $self->{list_flame_inner}->HList(
		-header             => 1,
		-itemtype           => 'text',
		-font               => 'TKFN',
		-columns            => 1,
		-padx               => 2,
		-background         => 'white',
		-selectbackground   => 'white',
		-selectforeground   => 'black',
		-selectmode         => 'extended',
		-height             => 10,
		-width              => $width,
		-borderwidth        => 0,
		-highlightthickness => 0,
	);
	$self->{list2}->header('create',0,-text => ' ');
	$self->{list} = $self->{list_flame_inner}->HList(
		-header             => 1,
		-itemtype           => 'text',
		-font               => 'TKFN',
		-columns            => $cols - 1,
		-padx               => 2,
		-background         => 'white',
		-selectforeground   => 'black',
		-selectmode         => 'extended',
		-height             => 10,
		-borderwidth        => 0,
		-highlightthickness => 0,
	);

	my $col = 0;                                            # Header����
	foreach my $i (@{$result->[0]}){
		unless ($col){
			++$col;
			next;
		}
		my $w = $self->{list}->Label(
			-text               => $i,
			-font               => "TKFN",
			-foreground         => 'blue',
			-cursor             => 'hand2',
			-padx               => 0,
			-pady               => 0,
			-borderwidth        => 0,
			-highlightthickness => 0,
		);
		my $key = $col;
		$w->bind(
			"<Button-1>",
			sub { $self->sort($key); }
		);
		$w->bind(
			"<Enter>",
			sub { $w->configure(-foreground => 'red'); }
		);
		$w->bind(
			"<Leave>",
			sub { $w->configure(-foreground => 'blue'); }
		);
		$self->list->header(
			'create',
			$col - 1,
			-itemtype  => 'window',
			-widget    => $w,
		);
		++$col;
	}
	shift @{$result};
	$self->{result} = $result;

	my $sb1 = $self->{list_flame}->Scrollbar(               # ������������
		-orient  => 'v',
		-command => sub {
			$self->multiscrolly(@_);
		},
	);
	my $sb2 = $self->{list_flame}->Scrollbar(
		-orient => 'h',
		-command => ['xview' => $self->{list}]
	);

	$self->{list}->configure(
		-yscrollcommand => sub{
			$sb1->set(@_);
			# �⤦�����Υꥹ�Ȥ��ɿ路�Ƥ��ʤ����Ʊ��������
			my $p1 = $_[0];
			my @t = $self->{list2}->yview;
			my $p2 = $t[0];
			
			if (
				   defined($self->{list_moveto})
				&& $self->{list_moveto} == $p1 
			){
					print "list1: pass\n" if $debug_ms;
					return 1;
			}
			
			if ($p1 == $p2){
				print "list1: list2 ok\n" if $debug_ms;
			} else {
				if ($self->{list2_moveto} == $p1){
					print "list1: already moved?\n" if $debug_ms;
					return 1
				}
				print "list1: change list2 to $p1 from $p2\n" if $debug_ms;
				$self->{list2_moveto} = $p1;
				$self->{list2}->yview(
					moveto => $p1,
				);
			}
		},
	);

	$self->{list2}->configure(
		-yscrollcommand => sub{
			$sb1->set(@_);
			# �⤦�����Υꥹ�Ȥ��ɿ路�Ƥ��ʤ����Ʊ��������
			my $p1 = $_[0];
			my @t = $self->{list}->yview;
			my $p2 = $t[0];
			
			if (
				   defined($self->{list2_moveto})
				&& $self->{list2_moveto} == $p1 
			){
				print "list2: pass\n" if $debug_ms;
				return 1;
			}
			
			if ($p1 == $p2){
				print "list2: list1 ok\n" if $debug_ms;
			} else {
				if ($self->{list_moveto} == $p1){
					print "list2: already moved?\n" if $debug_ms;
					return 1
				}
				print "list2: change list1 to $p1 from $p2\n" if $debug_ms;
				$self->{list_moveto} = $p1;
				$self->{list}->yview(
					moveto => $p1,
				);
			}
		},
	);

	$self->{list}->configure( -xscrollcommand => ['set', $sb2] );
	$self->{sb1} = $sb1;
	$self->{sb2} = $sb2;
	
	$sb1->pack(-side => 'right', -fill => 'y');             # Pack
	$self->{list_flame_inner}->pack(-fill =>'both',-expand => 'yes');
	$self->{list2}->pack(-side => 'left', -fill =>'y', -pady => 0);
	$self->{list}->pack(-fill =>'both',-expand => 'yes', -pady => 0);
	$sb2->pack(-fill => 'x');

	# ��̤ν񤭽Ф�
	my $right_style = $self->list->ItemStyle(
		'text',
		-font => "TKFN",
		-anchor => 'e',
	);
	my $center_style = $self->list->ItemStyle(
		'text',
		-font => "TKFN",
		-anchor => 'c',
		-background => 'white',
	);

	my $row = 0;
	foreach my $i (@{$result}){
		$self->list->add($row,-at => "$row");
		$self->{list2}->add($row,-at => "$row");
		my $col = 0;
		foreach my $h (@{$i}){
			if ($col){
				$self->list->itemCreate(
					$row,
					$col - 1,
					-text  => $h,#$self->gui_jchar($h,'sjis'),
					-style => $right_style
				);
			} else {
				$self->{list2}->itemCreate(
					$row,
					0,
					-text  => $h,#$self->gui_jchar($h,'sjis')
				);
			}
			++$col;
		}
		++$row;
	}
	
	$self->rtn;
}

sub rtn{
	my $self = shift;
	$self->label->configure(
		-text => 'Ready.',
		-foreground => 'blue'
	);
}

sub multiscrolly{
	my $self = shift;
	my $from = ( $self->{sb1}->get() )[0];
	
	$self->{list}->yview('moveto', $_[1]);
	print "multiscrolly to $_[1] from $from\n" if $debug_ms;
	return $self;
}

sub sort{
	my $self = shift;
	my $key  = shift;
	$key = 0 if $self->{last_sort_key} == $key;
	
	$self->{list}->delete('all');
	$self->{list2}->delete('all');
	
	# ������
	my @temp;
	if ($key){
		@temp = sort { $b->[$key] <=> $a->[$key] } @{$self->{result}};
		$self->{btn_copy}->configure(
			-text => kh_msg->get('copy_sel') # ���ԡ����������
		);
	} else {
		@temp = @{$self->{result}};
		$self->{btn_copy}->configure(
			-text => kh_msg->gget('copy_all') # ���ԡ���ɽ���Ρ�
		);
	}

	# ����
	my $right_style = $self->list->ItemStyle(
		'text',
		-font => "TKFN",
		-anchor => 'e',
	);
	my $row = 0;
	foreach my $i ( @temp ){
		$self->list->add($row,-at => "$row");
		$self->{list2}->add($row,-at => "$row");
		my $col = 0;
		foreach my $h (@{$i}){
			if ($col){
				$self->list->itemCreate(
					$row,
					$col - 1,
					-text  => $h,
					-style => $right_style
				);
			} else {
				$self->{list2}->itemCreate(
					$row,
					0,
					-text  => $h,#$self->gui_jchar($h,'sjis')
				);
			}
			++$col;
		}
		++$row;
	}
	$self->{list}->yview(0);
	$self->{list2}->yview(0);
	
	# ��٥�ο����ѹ�
	if ($key){
		my $w = $self->{list}->header(
			'cget',
			$key - 1,
			'-widget'
		);
		$w->configure(
			-foreground => 'red',
			#-cursor => undef
		);
		$w->bind(
			"<Leave>",
			sub { $w->configure(-foreground => 'red')}
		);
	}
	
	# �����ѹ�������٥�ο��򸵤��᤹
	if ($self->{last_sort_key}){
		my $lw = $self->{list}->header(
			'cget',
			$self->{last_sort_key} - 1,
			'-widget'
		);
		$lw->configure(
			-foreground => 'blue',
			#-cursor => 'hand2'
		);
		$lw->bind(
			"<Leave>",
			sub { $lw->configure(-foreground => 'blue'); }
		);
	}
	
	$self->{last_sort_key} = $key;
}

sub copy{
	my $self = shift;
	
	return 0 unless $self->{result};
	
	# 1����
	my $clip = "\t";
	
	my $cols = @{$self->{result}->[0]} - 2;
	for (my $n = 0; $n <= $cols; ++$n){
		if ($self->{last_sort_key}){
			unless ($n + 1 == $self->{last_sort_key}){
				next;
			}
		}
		
		my $w = $self->{list}->header(
			'cget',
			$n,
			'-widget'
		);
		$clip .= $w->cget('-text')."\t";
	}
	chop $clip;
	$clip .= "\n";
	
	# ���
	my $rows = @{$self->{result}} - 2;
	for (my $r = 0; $r <= $rows; ++$r){
		# 1����
		if ($self->{list2}->itemExists($r, 0)){
			my $cell = $self->{list2}->itemCget($r, 0, -text);
			chop $cell if $cell =~ /\r$/o;
			$clip .= "$cell\t";
		} else {
			$clip .= "\t";
		}
		# 2���ܰʹ�
		for (my $c = 0; $c <= $cols; ++$c){
			if ($self->{last_sort_key}){
				unless ($c + 1 == $self->{last_sort_key}){
					next;
				}
			}
		
			if ($self->{list}->itemExists($r, $c)){
				my $cell = $self->{list}->itemCget($r, $c, -text);
				chop $cell if $cell =~ /\r$/o;
				$clip .= "$cell\t";
			} else {
				$clip .= "\t";
			}
		}
		chop $clip;
		$clip .= "\n";
	}
	
	use kh_clipboard;
	kh_clipboard->string($clip);
}

#--------------#
#   ��������   #

sub cfile{
	my $self = shift;
	return $self->{codf_obj}->cfile;
}
sub tani{
	my $self = shift;
	return $self->{tani_obj}->tani;
}
sub list{
	my $self = shift;
	return $self->{list};
}
sub list_frame{
	my $self = shift;
	return $self->{listframe};
}
sub label{
	my $self = shift;
	return $self->{label};
}
sub win_name{
	return 'w_cod_jaccard';
}
1;