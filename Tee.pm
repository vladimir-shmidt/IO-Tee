# -*- perl -*-
#
#   IO::Tee - An IO::Handle subclass for emulation 'tee' behaviour
#
#   Copyright (C) 1998, Jochen Wiedmann
#                       Am Eisteich 9
#                       72555 Metzingen
#                       Germany
#
#                       Phone: +49 7123 14887
#                       Email: joe@ispsoft.de
#
#
#   This module is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This module is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this module; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
############################################################################

require 5.004;
use strict;

require IO::Handle;


package IO::Tee;

$IO::Tee::VERSION = '0.01';
@IO::Tee::ISA = qw(IO::Handle);

sub new ($$$) {
    my($class, $tfh, $lfh) = @_;
    if (!$tfh  ||  !$lfh) {
	return undef;
    }
    my($self) = { 'tfh' => $tfh, 'lfh' => $lfh };
    bless($self, (ref($class) || $class));
    $self;
}

sub close ($) {
    my($self) = shift;
    my($result) = $self->{'tfh'}->close();
    $result &= $self->{'lfh'}->close();
    $result;
}

sub fileno ($) { my($self) = shift; $self->{'tfh'}->fileno(); }

sub getc ($) {
    my($self) = shift;
    my($c) = $self->{'tfh'}->getc();
    if (defined($c)  &&  length($c) > 0  &&  !$self->{'lfh'}->print($c)) {
	$self->{'tfh'}->ungetc($c);
	return undef;
    }
    $c;
}

sub eof ($) { my($self) = shift; $self->{'tfh'}->eof(); }

sub read ($$$;$) {
    my($self, $scalar, $length, $offset) = @_;
    my($len) = $self->{'tfh'}->read($scalar, $length, $offset);
    if ($len  &&  !$self->{'lfh'}->write($scalar, $len, $offset)) {
	$len = undef;
    }
    $len;
}

sub truncate ($$) {
    my($self, $len) = @_;
    return $self->{'lfh'}->truncate($len);
}

sub stat ($) { my($self) = shift; return $self->{'tfh'}->stat(); }

sub print ($@) {
    my($self) = shift;
    return ($self->{'tfh'}->print(@_) && $self->{'lfh'}->print(@_));
}

sub printf ($$@) {
    my($self) = shift;
    my($format) = shift;
    return ($self->{'tfh'}->printf($format, @_)
	    && $self->{'lfh'}->printf($format, @_));
}

sub sysread ($$$;$) {
    my($self, $scalar, $length, $offset) = @_;
    my($len) = $self->{'tfh'}->sysread($scalar, $length, $offset);
    if ($len  &&  !$self->{'lfh'}->write($scalar, $offset, $len)) {
	$len = undef;
    }
    $len;
}

sub syswrite ($$$;$) {
    my($self, $scalar, $length, $offset) = @_;
    my($len) = $self->{'tfh'}->syswrite($scalar, $length, $offset);
    if ($len  &&  !$self->{'lfh'}->write($scalar, $offset, $len)) {
	$len = undef;
    }
    $len;
}

sub autoflush ($;$) {
    my($self, $mode) = @_;
    return ($self->{'tfh'}->autoflush($mode)
	    && $self->{'tfh'}->autoflush($mode));
}

sub output_field_separator ($;$) {
    my($self, $mode) = @_;
    return ($self->{'tfh'}->output_field_separator($mode)
	    && $self->{'tfh'}->output_field_separator($mode));
}

sub output_record_separator ($;$) {
    my($self, $mode) = @_;
    return ($self->{'tfh'}->output_record_separator($mode)
	    && $self->{'tfh'}->output_recordx_separator($mode));
}

sub input_record_separator ($;$) {
    my($self, $mode) = @_;
    return $self->{'tfh'}->input_record_separator($mode);
}

sub input_line_number ($;$) {
    my($self, $mode) = @_;
    return $self->{'tfh'}->input_line_number($mode);
}

sub format_page_number ($;$) {
    my($self, $mode) = @_;
    return $self->{'tfh'}->format_page_number($mode);
}

sub format_lines_per_page ($;$) {
    my($self, $mode) = @_;
    return $self->{'tfh'}->format_lines_per_page($mode);
}

sub format_lines_left ($;$) {
    my($self, $mode) = @_;
    return $self->{'tfh'}->format_lines_left($mode);
}

sub format_name ($;$) {
    my($self, $mode) = @_;
    return $self->{'tfh'}->format_name($mode);
}

sub format_top_name ($;$) {
    my($self, $mode) = @_;
    return $self->{'tfh'}->format_top_name($mode);
}

sub format_line_break_characters ($;$) {
    my($self, $mode) = @_;
    return $self->{'tfh'}->format_line_break_characters($mode);
}

sub format_formfeed ($;$) {
    my($self, $mode) = @_;
    return $self->{'tfh'}->format_formfeed($mode);
}

sub format_write ($;$) {
    my($self, $mode) = @_;
    return $self->{'tfh'}->format_writeX($mode);
}

sub getline ($) {
    my($self) = shift;
    my($line) = $self->{'tfh'}->getline();
    if (defined($line)  &&  !$self->{'lfh'}->print($line)) {
	$line = undef;
    }
    $line;
}

sub getlines ($) {
    my($self) = shift;
    my(@lines) = $self->{'tfh'}->getlines();
    my($line);
    foreach $line (@lines) {
	if (!$self->{'lfh'}->print($line)) {
	    @lines = ();
	    last;
	}
    }
    @lines;
}

sub ungetc($$) {
    my($self, $c) = @_;
    undef; # Cannot ungetc from logfile
}

sub write ($$$$) {
    my($self, $buf, $length, $offset) = @_;
    $self->{'tfh'}->write($buf, $length, $offset)
	&& $self->{'lfh'}->write($buf, $length, $offset);
}

sub flush ($) {
    my($self) = shift;
    $self->{'tfh'}->flush()  &&  $self->{'lfh'}->flush();
}

sub error ($) {
    my($self) = shift;
    $self->{'tfh'}->error()  .  $self->{'lfh'}->error();
}

sub clearerr ($) {
    my($self) = shift;
    $self->{'tfh'}->clearerr();
    $self->{'lfh'}->clearerr();
}


1;


__END__

=head1 NAME

IO::Tee - An IO::Handle subclass for emulating 'tee' behaviour

=head1 SYNOPSIS

    require IO::Tee;

    # Read from a given handle $ifh while logging to './logfile'
    my($fh) = IO::Tee->new($ifh, IO::File->new('./logfile', 'w'));
    if (!$fh) {
	die $!;
    }
    my($line);
    while (defined($line = $fh->getline())) {
	# Do something here
	...
    }

    # Write something into a socket while appending to './logfile'
    $fh = IO::Tee->new($ofh, IO::File->new('./logfile', 'a'));
    while (!$done) {
        # Do something here
        ...
	$fh->print($output);
    }

=head1 DESCRIPTION

This module does something very similar to the 'tee' program: All input
read from or sent to a given IO handle is copied to another IO handle.
Typically all methods are just inherited from IO::Handle. Exceptions
are:

=over 4

=item new

The constructor receives two handles as arguments: The first handle
which will be used for reading or writing, the second for logging.
The constructor returns undef, if either of the handles is undef,
so that you can safely do something like the following:

   my($fh) = IO::Tee->new(IO::File->new('foo', 'r'),
			  IO::File->new('bar', 'w'));
   if (!$fh) {
       die "Error: $!";
   }

Of course the logging handle must be ready for output. The first handle
can be used for both reading and writing, but that's probably not too
much useful, as you cannot distinguish the output in the logfile.


=back

=head1 COPYRIGHT AND AUTHOR

    Copyright (C) 1998, Jochen Wiedmann
                        Am Eisteich 9
                        72555 Metzingen
                        Germany

                        Phone: +49 7123 14887
                        Email: joe@ispsoft.de


This module is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This module is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this module; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 SEE ALSO

    L<IO::Handle (3)>, L<IO::Seekable (3)>, L<tee (1)>

