package IO::Tee;

require 5.004;
use strict;
use Carp;
use Symbol;
use IO::Handle;
use IO::File;
use vars qw($VERSION @ISA);
$VERSION = '0.60';
@ISA = 'IO::Handle';

# Constructor -- bless array reference into our class

sub new
{
    my $class = shift;
    my $self = gensym;
    @{*$self} = map {
        ! ref($_) ? IO::File->new($_)
        : ref($_) eq 'ARRAY' ? IO::File->new(@$_)
        : ref($_) eq 'GLOB' ? bless $_, 'IO::Handle'
        : $_ or return undef } @_;
    bless $self, $class;
    tie *$self, $class, $self;
    return $self;
}

# Return a list of all associated handles

sub handles
{
    @{*{$_[0]}};
}

# Proxy routines for various IO::Handle and IO::File operations

sub _method_return_success
{
    my $method = (caller(1))[3];
    $method =~ s/.*:://;

    my $self = shift;
    my $ret = 1;
    my $fh;
    foreach $fh (@{*$self}) { undef $ret unless $fh->$method(@_) }
    return $ret;
}

sub close        { _method_return_success(@_) }
sub truncate     { _method_return_success(@_) }
sub write        { _method_return_success(@_) }
sub syswrite     { _method_return_success(@_) }
sub format_write { _method_return_success(@_) }
sub fcntl        { _method_return_success(@_) }
sub ioctl        { _method_return_success(@_) }
sub flush        { _method_return_success(@_) }
sub clearerr     { _method_return_success(@_) }
sub seek         { _method_return_success(@_) }

sub formline
{
    my $self = shift;
    my $picture = shift;
    local($^A) = $^A;
    local($\) = "";
    formline($picture, @_);

    my $ret = 1;
    my $fh;
    foreach $fh (@{*$self}) { undef $ret unless print $fh $^A }
    return $ret;
}

sub _state_modify
{
    my $method = (caller(1))[3];
    $method =~ s/.*:://;
    croak "$method values cannot be retrieved collectively" if @_ <= 1;

    my $self = shift;
    my $fh;
    foreach $fh (@{*$self}) { $fh->$method(@_) }
    # Note that we do not return any "previous value" here
}

sub autoflush                    { _state_modify(@_) }
sub output_field_separator       { _state_modify(@_) }
sub output_record_separator      { _state_modify(@_) }
sub format_page_number           { _state_modify(@_) }
sub format_lines_per_page        { _state_modify(@_) }
sub format_lines_left            { _state_modify(@_) }
sub format_name                  { _state_modify(@_) }
sub format_top_name              { _state_modify(@_) }
sub format_line_break_characters { _state_modify(@_) }
sub format_formfeed              { _state_modify(@_) }

# File handle tying interface

sub TIEHANDLE
{
    my ($class, $self) = @_;
    return bless *$self{ARRAY}, $class;
}

sub PRINT
{
    my $self = shift;
    my $ret = 1;
    my $fh;
    foreach $fh (@$self) { undef $ret unless print $fh @_ }
    return $ret;
}

sub PRINTF
{
    my $self = shift;
    my $fmt = shift;
    my $ret = 1;
    my $fh;
    foreach $fh (@$self) { undef $ret unless printf $fh $fmt, @_ }
    return $ret;
}

# Croak for illegal (non-output) operations on IO::Tee objects

sub _croak_reading
{
    my $self = shift;
    my $class = ref $self;
    my $method = (caller(1))[3];
    $method =~ s/.*:://;
    croak "$class does not support $method";
}

sub READ                   { _croak_reading(@_) }
sub READLINE               { _croak_reading(@_) }
sub GETC                   { _croak_reading(@_) }
sub getc                   { _croak_reading(@_) }
sub gets                   { _croak_reading(@_) }
sub getline                { _croak_reading(@_) }
sub getlines               { _croak_reading(@_) }
sub read                   { _croak_reading(@_) }
sub sysread                { _croak_reading(@_) }
sub stat                   { _croak_reading(@_) }
sub eof                    { _croak_reading(@_) }
sub input_record_separator { _croak_reading(@_) }
sub input_line_number      { _croak_reading(@_) }

# Miscellaneous functions

sub DESTROY { my $self = shift; untie *$self; @{*$self} = () }

sub import { }

1;
__END__

=head1 NAME

IO::Tee - Multiplex output to multiple output handles

=head1 SYNOPSIS

    use IO::Tee;

    $tee = IO::Tee->new($handle1, $handle2);
    print $tee "foo", "bar";

=head1 DESCRIPTION

The C<IO::Tee> constructor, given a list of output handles, returns a
tied handle that can be written to but not read from.  When written to
(using print or printf), it multiplexes the output to the list of
handles originally passed to the constructor.  As a shortcut, you can
also directly pass a string or an array reference to the constructor,
in which case C<IO::File::new> is called for you with the specified
argument or arguments.

The C<IO::Tee> class supports certain C<IO::Handle> and C<IO::File>
methods related to output.  In particular, the following methods will
iterate themselves over all handles associated with the C<IO::Tee>
object, and return TRUE indicating success if and only if all associated
handles returned TRUE indicating success:

=over 4

=item close

=item truncate

=item write

=item syswrite

=item format_write

=item formline

=item fcntl

=item ioctl

=item flush

=item clearerr

=item seek

=back

Additionally, the following methods can be used to set (but not retrieve)
the current values of output-related state variables on all associated
handles:

=over 4

=item autoflush

=item output_field_separator

=item output_record_separator

=item format_page_number

=item format_lines_per_page

=item format_lines_left

=item format_name

=item format_top_name

=item format_line_break_characters

=item format_formfeed

=back

=head1 EXAMPLE

    use IO::Tee;
    use IO::File;

    my $tee = new IO::Tee(\*STDOUT,
        new IO::File(">tt1.out"), ">tt2.out");

    print join(' ', $tee->handles), "\n";

    $tee->output_field_separator("//");
    for (1..10) { print $tee $_, "\n" }
    for (1..10) { $tee->print($_, "\n") }
    $tee->flush;

=head1 AUTHOR

Chung-chieh Shan, ken@digitas.harvard.edu

=head1 COPYRIGHT

Copyright (c) 1998 Chung-chieh Shan.  All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perlfunc>, L<IO::Handle>, L<IO::File>.

=cut
