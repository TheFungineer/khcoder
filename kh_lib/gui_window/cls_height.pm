package gui_window::cls_height;
use strict;
use Tk::PNG;
use base qw(gui_window);

use gui_window::cls_height::doc;
use gui_window::cls_height::word;
use gui_window::cls_height::cod;

#------------------#
#   Window�򳫤�   #
#------------------#

sub _new{
	my $self = shift;
	my %args = @_;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$self->{plots} = $args{plots};
	$self->{type}  = $args{type};
	$self->{range} = 'last';

	$win->title($self->win_title);
	
	$self->{photo} = $win->Label(
		-image => $win->Photo(
			-file => $self->{plots}{$args{type}}{$self->{range}}->path
		),
		-borderwidth => 2,
		-relief => 'sunken',
	)->pack(-anchor => 'c');

	my $f1 = $win->Frame()->pack(-expand => 'y', -fill => 'x', -pady => 2);

	$f1->Label(
		-text => kh_msg->get('plotting'), #  �ץ�å��ϰϡ� 
		-font => "TKFN"
	)->pack(-anchor => 'e', -side => 'left');

	$self->{btn_first} = $f1->Button(
		-text => kh_msg->get('f50'), # << �ǽ�50
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {
			$self->{range} = 'first';
			$self->renew;
			$self->{btn_first}->configure(-state => 'disabled');
			$self->{btn_all}->configure(  -state => 'normal'  );
			$self->{btn_last}->configure( -state => 'normal'  );
			return $self;
		}
	)->pack(-side => 'left', -padx => 2);

	$self->{btn_all} = $f1->Button(
		-text => kh_msg->get('all'), # ����
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {
			$self->{range} = 'all';
			$self->renew;
			$self->{btn_first}->configure(-state => 'normal'  );
			$self->{btn_all}->configure(  -state => 'disabled');
			$self->{btn_last}->configure( -state => 'normal'  );
			return $self;
		}
	)->pack(-side => 'left', -padx => 2);

	$self->{btn_last} = $f1->Button(
		-text => kh_msg->get('l50'), # �Ǹ�50 >>
		-font => "TKFN",
		-borderwidth => '1',
		-state => 'disabled',
		-command => sub {
			$self->{range} = 'last';
			$self->renew;
			$self->{btn_first}->configure(-state => 'normal'  );
			$self->{btn_all}->configure(  -state => 'normal'  );
			$self->{btn_last}->configure( -state => 'disabled');
			return $self;
		}
	)->pack(-side => 'left', -padx => 2);

	$f1->Button(
		-text => kh_msg->gget('close'), # �Ĥ���
		-font => "TKFN",
		-width => 8,
		-borderwidth => '1',
		-command => sub { $self->close(); }
	)->pack(-side => 'right');

	$f1->Button(
		-text => kh_msg->gget('save'), # ��¸
		-font => "TKFN",
		#-width => 8,
		-borderwidth => '1',
		-command => sub { $self->save(); }
	)->pack(-side => 'right', -padx => 4);

	return $self;
}

sub save{
	my $self = shift;

	# ��¸��λ���
	my @types = (
		[ "Encapsulated PostScript",[qw/.eps/] ],
		[ "PDF",[qw/.pdf/] ],
		[ "SVG",[qw/.svg/] ],
		[ "PNG",[qw/.png/] ],
		[ "R Source",[qw/.r/] ],
	);
	@types = ([ "Enhanced Metafile",[qw/.emf/] ], @types)
		if $::config_obj->os eq 'win32';

	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.eps',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt(kh_msg->get('save_as')), # �ץ�åȤ���¸
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);

	$path = $self->gui_jg_filename_win98($path);
	$path = $self->gui_jg($path);
	$path = $::config_obj->os_path($path);

	$self->_save($path) if length($path);
	return 1;
}

sub _save{
	my $self = shift;
	my $path = shift;
	
	# R Source����¸������ˤ��к���ɬ�ס�
	$self->{plots}{$self->{type}}{$self->{range}}->save($path) if $path;
}

sub renew{
	my $self = shift;
	
	if (defined($_[0])){
		$self->{type} = shift;
	}
	
	$self->{photo}->configure(
		-image =>
			$self->{win_obj}->Photo(
				-file => $self->{plots}{$self->{type}}{$self->{range}}->path
			)
	);
	
	$self->{photo}->update;
	return $self;
}


1;
