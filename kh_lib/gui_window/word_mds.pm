package gui_window::word_mds;
use base qw(gui_window);
use utf8;

use strict;
use Tk;

use gui_widget::tani;
use gui_widget::hinshi;
use mysql_crossout;
use kh_r_plot::mds;
use plotR::network;

#------------------#
#   GUI Creation   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt($self->label));

	my $lf_w = $win->LabFrame(
		-label => kh_msg->get('units_words'),
		-labelside => 'acrosstop',
		-borderwidth => 2,
		-foreground => 'blue',
	)->pack(-fill => 'both', -expand => 1, -side => 'left');

	$self->{words_obj} = gui_widget::words->open(
		parent => $lf_w,
		verb   => kh_msg->get('plot'),      # Arrangement
	);

	my $lf = $win->LabFrame(
		-label => kh_msg->get('mds_opt'),
		-labelside => 'acrosstop',
		-borderwidth => 2,
		-foreground => 'blue',
	)->pack(-fill => 'x', -expand => 0);

	# Algorithm selection
	$self->{mds_obj} = gui_widget::r_mds->open(
		parent       => $lf,
		command      => sub{ $self->calc; },
		pack    => { -anchor   => 'w'},
		from    => $self->win_name,

	);
	
	# Font size
	$self->{font_obj} = gui_widget::r_font->open(
		parent    => $lf,
		command   => sub{ $self->calc; },
		pack      => { -anchor   => 'w' },
		show_bold => 1,
	);

	$win->Checkbutton(
			-text     => kh_msg->gget('r_dont_close'),      # Message: do not close this window during run-time
			-variable => \$self->{check_rm_open},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	$win->Button(
		-text => kh_msg->gget('cancel'),                        # Message: cancel
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->withd;}
	)->pack(-side => 'right',-padx => 2, -pady => 2, -anchor => 'se');

	$win->Button(
		-text => kh_msg->gget('ok'),
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->calc;}
	)->pack(-side => 'right', -pady => 2, -anchor => 'se')->focus;

	return $self;
}

sub start_raise{
	my $self = shift;
	$self->{words_obj}->settings_load;
}

sub start{
	my $self = shift;

	# Bindings when closing the window
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

#---------------#
#   Execution   #

sub calc{
	my $self = shift;
	
	# Check input
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('gui_window::word_corresp->select_pos'),
		);
		return 0;
	}

	my $check_num = mysql_crossout::r_com->new(
		tani     => $self->tani,
		tani2    => $self->tani,
		hinshi   => $self->hinshi,
		max      => $self->max,
		min      => $self->min,
		max_df   => $self->max_df,
		min_df   => $self->min_df,
	)->wnum;
	
	$check_num =~ s/,//g;

	if ($check_num < 5){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('select_5words'),
		);
		return 0;
	}

	if ($check_num > 150){
		my $ans = $self->win_obj->messageBox(
			-message => $self->gui_jchar
				(
					kh_msg->get('gui_window::word_corresp->too_many1')
					.$check_num
					.kh_msg->get('gui_window::word_corresp->too_many2')
					."\n"
					.kh_msg->get('gui_window::word_corresp->too_many3')
					."\n"
					.kh_msg->get('gui_window::word_corresp->too_many4')
				),
			-icon    => 'question',
			-type    => 'OKCancel',
			-title   => 'KH Coder'
		);
		unless ($ans =~ /ok/i){ return 0; }
	}

	$self->{words_obj}->settings_save;

	my $w = gui_wait->start;

	# Retrieve data
	my $r_command = mysql_crossout::r_com->new(
		tani   => $self->tani,
		tani2  => $self->tani,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
		rownames => 0,
	)->run;

	# Data reduction
	$r_command .= "d <- t(d)\n";
	$r_command .= "# END: DATA\n";

	my $plot = &make_plot(
		font_size         => $self->{font_obj}->font_size,
		font_bold         => $self->{font_obj}->check_bold_text,
		plot_size         => $self->{font_obj}->plot_size,
		$self->{mds_obj}->params,
		r_command      => $r_command,
		plotwin_name   => 'word_mds',
	);
	
	$w->end(no_dialog => 1);
	return 0 unless $plot;
	
	# Open plot window
	if ($::main_gui->if_opened('w_word_mds_plot')){
		$::main_gui->get('w_word_mds_plot')->close;
	}
	return 0 unless $plot;

	gui_window::r_plot::word_mds->open(
		plots       => $plot->{result_plots},
		msg         => $plot->{result_info},
		#ax          => $self->{ax},
	);
	$plot = undef;
	
	unless ( $self->{check_rm_open} ){
		$self->withd;
	}
}

sub make_plot{
	my %args = @_;

	my $fontsize = 1;
	my $x_factor = 1;
	if (
		$args{dim_number} <= 2
		&& (
			   $args{bubble}
			|| $args{n_cls}
		)
	){
		$x_factor = 4/3;
	}
	$args{height} = $args{plot_size};
	$args{width}  = int( $args{plot_size} * $x_factor );

	my $r_command = $args{r_command};

	kh_r_plot::mds->clear_env;

	unless ($args{dim_number} <= 3 && $args{dim_number} >= 1 ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('error_dim'),                # Error message: please specify a number of dimensions between 1 and 3
		);
		return 0;
	}

	my $source_matrix = 'd';
	if ($args{method_dist} eq 'euclid'){
		# Standardized for each extracted word
		$source_matrix = 't( scale( t(d) ) )';
	}

	$r_command .= "
	library(amap)
	check4mds <- function(d){
		jm <- as.matrix(Dist($source_matrix, method=\"$args{method_dist}\"))
		jm[upper.tri(jm,diag=TRUE)] <- NA
		if ( length( which(jm==0, arr.ind=TRUE) ) ){
			return( which(jm==0, arr.ind=TRUE)[,1][1] )
		} else {
			return( NA )
		}
	}
	";

	$r_command .= "
	if (exists(\"doc_length_mtr\")){
		# NOTE: Not sure what this was supposed to do, but it breaks everything.
		#
		# leng <- as.numeric(doc_length_mtr[,2])
		# leng[leng ==0] <- 1
		# d <- t(d)
		# d <- d / leng
		# d <- d * 1000
		# d <- t(d)
	}
	" unless $args{method_dist} eq 'binary';

	$r_command .= "
	while ( is.na(check4mds(d)) == 0 ){
		n <-  check4mds(d)
		print( paste( \"Dropped object:\", row.names(d)[n]) )
		d <- d[-n,]
	}
	";

	$r_command .= "dj <- Dist($source_matrix,method=\"$args{method_dist}\")\n";

	if ($args{random_starts} == 1){
		$r_command .= "random_starts <- 1\n";
	} else {
		$r_command .= "random_starts <- 0\n";
	}
	$r_command .= "dim_n <- $args{dim_number}\n";

	# Commands for different algorithms
	my $r_command_d = '';
	my $r_command_a = '';
	$r_command .= "method_mds <- \"$args{method}\"\n";
	$r_command .= &r_command_mds();
	
	# Saving the MDS
	my $file_save = $::config_obj->cwd.'/config/R-bridge/'.$::project_obj->dbname.'_'.$args{plotwin_name};
	unlink $file_save if -e $file_save;
	$file_save = $::config_obj->uni_path($file_save);
	$r_command .= "save(d,cl,dim_n, file=\"$file_save\" )\n";
	
	# Commands for plotting (by dimension)
	$args{n_cls}     = 0 unless ( length($args{n_cls}) );
	$args{cls_raw}   = 0 unless ( length($args{cls_raw}) );
	$args{use_alpha} = 0 unless ( length($args{use_alpha}) );
	
	#$r_command_d = $r_command;
	$r_command_d = "\n#--------------------------------------------------------#\n";

	$r_command_d .= "use_alpha <- $args{use_alpha}\n";
	$r_command_d .= "
		if ( exists(\"saving_emf\") || exists(\"saving_eps\") ){
			use_alpha <- 0 
		}
	";
	$r_command_d .= "plot_mode <- \"color\"\n";
	$r_command_d .= "font_size <- $fontsize\n";
	$r_command_d .= "n_cls <- $args{n_cls}\n";
	$r_command_d .= "cls_raw <- $args{cls_raw}\n";
	$r_command_d .= "name_dim <- '".kh_msg->pget('dim')."'\n";      # Dimensions
	
	$r_command_d .= "name_dim1 <- paste(name_dim,'1')\n";
	$r_command_d .= "name_dim2 <- paste(name_dim,'2')\n";
	$r_command_d .= "name_dim3 <- paste(name_dim,'3')\n";
	
	$r_command_a .= "use_alpha <- $args{use_alpha}\n";
	$r_command_d .= "fix_asp <- $args{fix_asp}\n";
	$r_command_a .= "
		if ( exists(\"saving_emf\") || exists(\"saving_eps\") ){
			use_alpha <- 0 
		}
	";
	$r_command_a .= "plot_mode <- \"dots\"\n";
	$r_command_a .= "font_size <- $fontsize\n";
	$r_command_a .= "n_cls <- $args{n_cls}\n";
	$r_command_a .= "cls_raw <- $args{cls_raw}\n";
	$r_command_a .= "dim_n <- $args{dim_number}\n";
	$r_command_d .= "name_dim <- '".kh_msg->pget('dim')."'\n";      # Dimensions

	$r_command_a .= "name_dim1 <- paste(name_dim,'1')\n";
	$r_command_a .= "name_dim2 <- paste(name_dim,'2')\n";
	$r_command_a .= "name_dim3 <- paste(name_dim,'3')\n";

	if ($args{font_bold} == 1){
		$args{font_bold} = 2;
	} else {
		$args{font_bold} = 1;
	}
	$r_command_d .= "text_font <- $args{font_bold}\n";
	$r_command_a .= "text_font <- $args{font_bold}\n";

	if ( $args{dim_number} <= 2){
		if ( $args{bubble} == 0 ){
			$r_command_d .= "bubble <- 0\n";
			$r_command_d .= &r_command_plot(%args);
			$r_command_a .= "bubble <- 0\n";
			$r_command_a .= &r_command_plot(%args);

		} else {
			# When representing the bubbles
			$r_command_d .= "bubble <- 1\n";
			$r_command_d .= "std_radius <- $args{std_radius}\n";
			$r_command_d .= "bubble_var <- $args{bubble_var}\n";
			$r_command_d .= "bubble_size <- $args{bubble_size}\n";
			$r_command_d .= &r_command_plot(%args);

			$r_command_a .= "bubble <- 1\n";
			$r_command_a .= "std_radius <- $args{std_radius}\n";
			$r_command_a .= "bubble_var <- $args{bubble_var}\n";
			$r_command_a .= "bubble_size <- $args{bubble_size}\n";
			$r_command_a .= &r_command_plot(%args);
		}
	}
	elsif ($args{dim_number} == 3){
		$r_command_d .=
			"library(scatterplot3d)\n"
			."s3d <- scatterplot3d(cl, type=\"h\", box=TRUE, pch=16,"
				."highlight.3d=FALSE, color=\"#FFA200FF\", "
				."col.grid=\"gray\", col.lab=\"black\", xlab=name_dim1,"
				."ylab=name_dim2, zlab=name_dim3, col.axis=\"#000099\","
				."mar=c(3,3,0,2), lty.hide=\"dashed\" )\n"
			."cl2 <- s3d\$xyz.convert(cl)\n"
			."library(maptools)\n"
			."labcd <- pointLabel(x=cl2\$x, y=cl2\$y, labels=rownames(cl),"
				."cex=$fontsize, offset=0, col=\"black\", font = text_font, doPlot=F)\n"
			.'
	# ラベル再調整
	xorg <- cl2$x
	yorg <- cl2$y
	cex  <- font_size
	
	if ( length(xorg) < 300 ) {
		library(wordcloud)'
		.&plotR::network::r_command_wordlayout
		.'nc <- wordlayout(
			labcd$x,
			labcd$y,
			rownames(cl),
			cex=cex * 1.25,
			xlim=c(  par( "usr" )[1], par( "usr" )[2] ),
			ylim=c(  par( "usr" )[3], par( "usr" )[4] )
		)

		xlen <- par("usr")[2] - par("usr")[1]
		ylen <- par("usr")[4] - par("usr")[3]

		for (i in 1:length(rownames(cl)) ){
			x <- ( nc[i,1] + .5 * nc[i,3] - labcd$x[i] ) / xlen
			y <- ( nc[i,2] + .5 * nc[i,4] - labcd$y[i] ) / ylen
			d <- sqrt( x^2 + y^2 )
			if ( d > 0.05 ){
				# print( paste( rownames(cb)[i], d ) )
				
				segments(
					nc[i,1] + .5 * nc[i,3], nc[i,2] + .5 * nc[i,4],
					xorg[i], yorg[i],
					col="gray60",
					lwd=1
				)
				
			}
		}

		xorg <- labcd$x
		yorg <- labcd$y
		labcd$x <- nc[,1] + .5 * nc[,3]
		labcd$y <- nc[,2] + .5 * nc[,4]
	}

	text(
		labcd$x,
		labcd$y,
		rownames(cl),
		cex=font_size,
		offset=0,
		font = text_font
	)
			'
		;
		$r_command_a .=
			 "library(scatterplot3d)\n"
			."s3d <- scatterplot3d(cl, type=\"h\", box=TRUE, pch=16,"
				."highlight.3d=TRUE, mar=c(3,3,0,2), "
				."col.grid=\"gray\", col.lab=\"black\", xlab=name_dim1,"
				."ylab=name_dim2, zlab=name_dim3, col.axis=\"#000099\","
				."lty.hide=\"dashed\" )\n"
		;
	}

	#$r_command .= $r_command_a;
	my $r_command_l = "load(\"$file_save\")\n";

	# Plot creation
	my $plot1 = kh_r_plot::mds->new(
		name      => $args{plotwin_name}.'_1',
		command_f => $r_command.$r_command_d,
		command_s => $r_command_l.$r_command_d,
		width     => int( $args{plot_size} * $x_factor ),
		height    => $args{plot_size},
		font_size => $args{font_size},
	) or return 0;
	my $plot2 = kh_r_plot::mds->new(
		name      => $args{plotwin_name}.'_2',
		command_s => $r_command_l.$r_command_a,
		command_a => $r_command_a,
		command_f => $r_command.$r_command_a,
		width     => int( $args{plot_size} * $x_factor ),
		height    => $args{plot_size},
		font_size => $args{font_size},
	) or return 0;

	# Check for words / codes omitted from analysis
	my $dropped = '';
	foreach my $i (split /\n/, $plot1->r_msg){
		if ($i =~ /"Dropped object: (.+)"/){
			$dropped .= "$1, ";
		}
	}
	if ( length($dropped) ){
		chop $dropped;
		chop $dropped;
		#$dropped = Jcode->new($dropped,'sjis')->euc
		#	if $::config_obj->os eq 'win32';
		gui_errormsg->open(
			type => 'msg',
			msg  =>
				kh_msg->get('omit')                      # Message: the following extracted words / codes were omitted from analysis
				.$dropped
		);
	}

	my $txt = $plot1->r_msg;
	if ( length($txt) ){
		print "-------------------------[Begin]-------------------------[R]\n";
		print "$txt\n";
		print "---------------------------------------------------------[R]\n";
	}

	# Acquisition of the stress value
	my $stress;
	if ($args{method} eq 'K' or $args{method} eq 'S' or $args{method} eq 'SM' ){
		$::config_obj->R->send(
			 'str <- paste("khcoder",c$stress, sep = "")'."\n"
			.'print(str)'
		);
		$stress = $::config_obj->R->read;

		if ($stress =~ /"khcoder(.+)"/){
			$stress = $1;
			$stress /= 100 if $args{method} eq 'K';
			$stress = sprintf("%.3f",$stress);
			$stress = "  stress = $stress";
		} else {
			$stress = undef;
		}
	}

	my $plotR;
	$plotR->{result_plots} = [$plot1, $plot2];
	$plotR->{result_info} =  $stress;
	return $plotR;

}

#--------------#
#   Accessor   #


sub label{
	return kh_msg->get('win_title');           # Extracted words / Multi-Dimensional Scaling: Options
}

sub win_name{
	return 'w_word_mds';
}


sub min{
	my $self = shift;
	return $self->{words_obj}->min;
}
sub max{
	my $self = shift;
	return $self->{words_obj}->max;
}
sub min_df{
	my $self = shift;
	return $self->{words_obj}->min_df;
}
sub max_df{
	my $self = shift;
	return $self->{words_obj}->max_df;
}
sub tani{
	my $self = shift;
	return $self->{words_obj}->tani;
}
sub hinshi{
	my $self = shift;
	return $self->{words_obj}->hinshi;
}

sub r_command_plot{
	my %args = @_;
	return '


ylab_text <- ""
if ( dim_n == 2 ){
	ylab_text <- name_dim2
}
if ( dim_n == 1 ){
	cl <- cbind(cl[,1],cl[,1])
}

col_base <- "mediumaquamarine"
bty      <- "l"

if ( exists("bs_fixed") == F ) {
	bubble_size <- bubble_size / '.$args{font_size}.'
	bs_fixed <- 1
}

# Determine the size of the bubbles
neg_to_zero <- function(nums){
  temp <- NULL
  for (i in 1:length(nums) ){
    if ( is.na( nums[i] ) ){
      temp[i] <- 1
    } else {
	    if (nums[i] < 1){
	      temp[i] <- 1
	    } else {
	      temp[i] <-  nums[i]
	    }
	}
  }
  return(temp)
}

b_size <- NULL
b_freq <- NULL

for (i in rownames(cl)){
	if ( is.na(i) || is.null(i) || is.nan(i) ){
		b_size <- c( b_size, 1 )
		b_freq <- c( b_freq, 1 )
	} else {
		b_size <- c( b_size, sum( d[i,] ) )
		b_freq <- c( b_freq, sum( d[i,] ) )
	}
}

# Adjust bubble radius so that appearance number ratio = area ratio
b_size <- sqrt( b_size / pi )

# Standardize (emphasize) bubble size
if (std_radius){ 
	if ( sd(b_size) == 0 ){
		b_size <- rep(10, length(b_size))
	} else {
		b_size <- b_size / sd(b_size)
		b_size <- b_size - mean(b_size)
		b_size <- b_size * 5 * bubble_var / 100 + 10
		b_size <- neg_to_zero(b_size)
	}
}

# Cluster analysis
if (n_cls > 0){
	if (nrow(d) < n_cls){
		n_cls <- nrow(d)
	}

	if (cls_raw == 1){
		djj <- dj
	} else {
		djj <- dist(cl,method="euclid")
	}
	
	if (
		   ( as.numeric( R.Version()$major ) >= 3 )
		&& ( as.numeric( R.Version()$minor ) >= 1.0)
	){                                                      # >= R 3.1.0
		hcl <- hclust(djj,method="ward.D2")
	} else {                                                # <= R 3.0
		djj <- djj^2
		hcl <- hclust(djj,method="ward")
		#hcl$height <- sqrt( hcl$height )
	}
}


#-----------------------------------------------------------------------------#
#                           Prepare label positions
#-----------------------------------------------------------------------------#

if (plot_mode == "color") {

	png_width  <- '.$args{width}.'
	png_height <- '.$args{height}.'
	if ( png_width > png_height ){
		png_width  <- png_width - 0.16 * '.$args{font_size}.' * bubble_size / 100 * png_width
	}
	dpi <- 72 * min(png_width, png_width) / 640 * '.$args{font_size}.'
	p_size <- 12 * dpi / 72;
	png("temp.png", width=png_width, height=png_height, unit="px", pointsize=p_size)

	if ( exists("PERL_font_family") ){
		par(family=PERL_font_family) 
	}
	
	plot(cl)
	library(maptools)
	labcd <- pointLabel(
		x=cl[,1],
		y=cl[,2],
		labels=rownames(cl),
		cex=font_size,
		offset=0,
		doPlot=F
	)
	
	# Label readjustment
	xorg <- cl[,1]
	yorg <- cl[,2]
	cex  <- font_size
	segs <- NULL
	
	if ( length(xorg) < 300 ) {
		library(wordcloud)
		'.&plotR::network::r_command_wordlayout.'

		nc <- wordlayout(
			labcd$x,
			labcd$y,
			rownames(cl),
			cex=cex * 1.25,
			xlim=c(  par( "usr" )[1], par( "usr" )[2] ),
			ylim=c(  par( "usr" )[3], par( "usr" )[4] )
		)
	
		xlen <- par("usr")[2] - par("usr")[1]
		ylen <- par("usr")[4] - par("usr")[3]
	
		for (i in 1:length(rownames(cl)) ){
			x <- ( nc[i,1] + .5 * nc[i,3] - labcd$x[i] ) / xlen
			y <- ( nc[i,2] + .5 * nc[i,4] - labcd$y[i] ) / ylen
			dst <- sqrt( x^2 + y^2 )
			if ( dst > 0.05 ){
				segs <- rbind(
					segs,
					c(
						nc[i,1] + .5 * nc[i,3],
						nc[i,2] + .5 * nc[i,4],
						xorg[i],
						yorg[i]
					)
				)
			}
		}
		xorg <- labcd$x
		yorg <- labcd$y
		labcd$x <- nc[,1] + .5 * nc[,3]
		labcd$y <- nc[,2] + .5 * nc[,4]
	}
	dev.off()
}

#-----------------------------------------------------------------------------#
#                              Start plotting
#-----------------------------------------------------------------------------#

library(grid)
library(ggplot2)

font_family <- "'.$::config_obj->font_plot_current.'"

if ( exists("PERL_font_family") ){
	font_family <- PERL_font_family
}

if (use_alpha == 1){
	alpha_value = 0.6
} else {
	alpha_value = 1
}

if ( n_cls > 0 ){
	cls_labels <- cutree(hcl, k=n_cls)
	cls_labels <- formatC(cls_labels,width=2,flag="0")

	cls_labels <- paste(cls_labels, "  ")
} else {
	cls_labels <- "cluster 1"
}

cl2 <- data.frame(
	d1 = cl[,1],
	d2 = cl[,2],
	s = b_size,
	col_f = cls_labels,
	lx = labcd$x,
	ly = labcd$y,
	labels = rownames(cl),
	stringsAsFactors = F
)

g <- ggplot()

# Plot
if ( bubble == 1 ){
	g <- g + geom_point(
		data=cl2,
		aes(x=d1, y=d2, size=s, colour=col_f, fill=col_f),
		shape=21,
		colour="gray40",
		alpha=alpha_value
	)
	

	lerp <- function(x, a, b) {
		a * (1 - x) + b * x
	}

	nrst_pow10 <- function(x) {
		floor(log10(x))
	}

	lerp_freq <- function(brks) {
		brks * brks * pi
	}

	interp_breaks <- function(extrem) {
		extrem_f = extrem * extrem * pi
		sqrt( c(lerp(0/3, min(extrem_f), max(extrem_f)),
				round(lerp(1/3, min(extrem_f), max(extrem_f)), -1 * nrst_pow10(lerp(1/3, min(extrem_f), max(extrem_f)))),
				round(lerp(2/3, min(extrem_f), max(extrem_f)), -1 * nrst_pow10(lerp(2/3, min(extrem_f), max(extrem_f)))),
				lerp(3/3, min(extrem_f), max(extrem_f))) / pi)
	}

	g <- g + scale_size_area(
		max_size = 30 * bubble_size / 100,
		breaks = interp_breaks,
		labels = lerp_freq,
		guide = guide_legend(
			title = "Frequency:",
			override.aes = list(colour="black", alpha=1),
			label.hjust = 1,
			order = 2
	    )
    )
} else {
	if ( n_cls > 0 ){
		g <- g + geom_point(
			data=cl2,
			aes(x=d1, y=d2, colour=col_f, fill=col_f),
			size=5.5,
			shape=21,
			colour="gray40",
			alpha=alpha_value
		)
	} else {
		g <- g + geom_point(
			data=cl2,
			aes(x=d1, y=d2),
			size=2,
			shape=16,
			colour="mediumaquamarine"
		)
	}
}

if ( n_cls > 0 ){
	g <- g + scale_fill_brewer(
		palette = "Set3",
		guide = guide_legend(
			title = "Cluster:",
			override.aes = list(size=5.5, alpha=1, shape=22),
			keyheight = unit(1.25,"line"),
			ncol=2,
			order = 1
		)
	)
} else {
	g <- g + scale_fill_brewer(
		palette = "Set3",
		guide = "none"
	)
}

# Fix aspect ratio
if (fix_asp == 1){
	g <- g + coord_fixed()
}

# Text
if (plot_mode == "color") {
	if (text_font == 1){
		face <- "plain"
	} else {
		face <- "bold"
	}
	g <- g + geom_text(
		data=cl2,
		aes(x=lx,y=ly,label=labels),
		size=4,
		colour="black",
		family=font_family,
		fontface=face
	)
	if (length(segs) > 0){
		colnames(segs) <- c("x1", "y1", "x2", "y2")
		segs <- as.data.frame(segs)
		g <- g + geom_segment(
			aes(x=x1, y=y1, xend=x2, yend=y2),
			data=segs,
			colour="gray60"
		)

	}
}

# Appearance / Theme
g <- g + labs(x=name_dim1, y=name_dim2)
g <- g + theme_classic(base_family=font_family)
g <- g + theme(
	legend.key   = element_rect(colour = "transparent"),
	axis.line.x    = element_line(colour = "black", size=0.5),
	axis.line.y    = element_line(colour = "black", size=0.5),
	axis.title.x = element_text(face="plain", size=11, angle=0),
	axis.title.y = element_text(face="plain", size=11, angle=90),
	axis.text.x  = element_text(face="plain", size=11, angle=0),
	axis.text.y  = element_text(face="plain", size=11, angle=0),
	legend.title = element_text(face="bold",  size=11, angle=0),
	legend.text  = element_text(face="plain", size=11, angle=0)
)

print(g)

';
}

sub r_command_mds{
	return '

if (method_mds == "K"){
	# Kruskal
	library(MASS)
	c <- isoMDS(dj, k=dim_n, maxit=3000, tol=0.000001)
	if (random_starts == 1){
			print("Running random starts...")
			set.seed(123)
			for (i in 1:1000){ # 200sec
				if (dim_n == 1){
					init <- cbind( rnorm(nrow(d)) )
				} else if (dim_n == 2){
					init <- cbind( rnorm(nrow(d)), rnorm(nrow(d)) )
				} else if (dim_n == 3){
					init <- cbind( rnorm(nrow(d)), rnorm(nrow(d)), rnorm(nrow(d)) )
				} else {
					warn("Error: invalid dimesion number!")
				}
				ct <- isoMDS(dj, y=init, k=dim_n, maxit=3000, tol=0.000001, trace=F)
				if (ct$stress < c$stress){
					c <- ct
					print( paste("random start #", i, ": ",  c$stress, sep=""))
				}
			}
	}
	cl <- c$points
} else if (method_mds == "S"){
	#Sammon
	library(MASS)
	c <- sammon(dj, k=dim_n, niter=3000, tol=0.000001)
	if (random_starts == 1){
			print("Running random starts...")
			set.seed(123)
			for (i in 1:1000){ # 200sec
				if (dim_n == 1){
					init <- cbind( rnorm(nrow(d)) )
				} else if (dim_n == 2){
					init <- cbind( rnorm(nrow(d)), rnorm(nrow(d)) )
				} else if (dim_n == 3){
					init <- cbind( rnorm(nrow(d)), rnorm(nrow(d)), rnorm(nrow(d)) )
				} else {
					warn("Error: invalid dimesion number!")
				}
				ct <- sammon(dj, y=init, k=dim_n, niter=3000, tol=0.000001, trace=F)
				if (ct$stress < c$stress){
					c <- ct
					print( paste("random start #", i, ": ",  c$stress, sep=""))
				}
			}
	}
	cl <- c$points
} else if (method_mds == "C"){
	# Classical
	c <- cmdscale(dj, k=dim_n)
	cl <- c
} else if (method_mds == "SM"){
	# SMACOF
	library(smacof)
	c <- mds(dj, ndim=dim_n, type="ordinal", itmax=3000)
	if (random_starts == 1){
		print("Running random starts...")
		set.seed(123)
		for (i in 1:200){ # 200 -> 246sec
			run <- mds(dj, ndim=dim_n, type="ordinal", init = "random", itmax=3000)
			if (run$stress < c$stress){
				c <- run
				print( paste("random start #", i, ": ",  c$stress, sep=""))
			}
		}
	}
	cl <- c$conf
}
	';
}

1;
