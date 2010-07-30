package Data::Structure::FindPath;
use base qw(Exporter);

use 5.006;  # so we can "use warnings" and "no warnings";

our $VERSION = 0.01;
our @EXPORT_OK;

use strict;
use warnings;

use Scalar::Util qw(blessed reftype);

# ABSTRACT: find paths to elements in data structures

=head1 NAME

Data::Structure::FindPath - find paths to elements in data structures

=head1 SYNOPSIS

  use Data::Structure::FindPath qw(
    data_find_path data_find_path_eq data_find_path_num
  );

  my $ds = {bob => [1,42,42,{ foo => "fred" }]};

  # prints "{'bob'}[3]{'foo'}"
  print join ",", data_find_path {
    defined($_[0]) && $_[0] eq "fred"
  } $foo;
  
  # also prints "{'bob'}[3]{'foo'}"
  print join ",", data_find_path_eq "fred", $foo;
  
  # prints "{'bob'}[1],{'bob'}[2]"
  print join ",", data_find_path_num 42, $foo;
  
=head1 DESCRIPTION

This module allows you to find the paths to matching elements
within a data structure.

=head2 Functions

The following functions can be imported in the usual fashion.
No functions are exported by default.

They all take standard options which are detailed below.

=over

=item data_find_path $match_sub, $data, @options

Returns the paths for matching values within C<$data>.  
C<$match_sub> should be a subroutine that, when executed,
returns true if and only if its first argument matches.

=item data_find_path_eq $value, $data, @options

Returns the paths for values that are C<eq> within C<$data>.
Note that stringification is forced on the values by C<eq>, so
you should be particularly careful with undefined values (which
will stringify to the empty string) and objects that have
overloaded stringification.

=item data_find_path_num $value, $data, @options

Returns the paths for values that are C<==> within C<$data>.

=back

=cut

sub _data_find_path {
  my $sub  = shift;
  my $data = shift;
  my $path = shift;
  my $opts = shift;
  my $seen = shift;
  
  # avoid cirular loops
  if (ref($data)) {
    return if $seen->{ $data };
    $seen = { %$seen };  # TODO: Could this be better done with local?
    $seen->{ $data } = 1;
  }
  
  my @results;
  
  if ($sub->($data)) {
    return $path unless $opts->{inside_matches};
    push @results, $path;
  }
  
  if (!$opts->{inside_objects} && blessed $data) {
    return @results;
  }
  
  if (ref $data && reftype($data) eq "HASH") {
    push @results, _data_find_path(
      $sub,
      $data->{ $_ },
      $path."{'"._escape($_)."'}",
      $opts,
      $seen) foreach sort keys %$data;
    return @results;
  }
  
  if (ref $data && reftype($data) eq "ARRAY") {
    push @results, _data_find_path(
      $sub,
      $data->[ $_ ],
      $path."[$_]",
      $opts,
      $seen) foreach 0..(@$data - 1);
    return @results;
  }
  
  return @results;
}

sub data_find_path(&$;@) {
  my $sub = shift;
  my $data = shift;
  my %opts = @_;
  return _data_find_path($sub, $data, "", \%opts, {});
}
push @EXPORT_OK, "data_find_path";

sub data_find_path_eq($$;@) {
  my $value = shift;
  my $data = shift;
  my %opts = @_;
  no warnings 'uninitialized';  # we want autovivication
  return _data_find_path(sub { $_[0] eq $value }, $data, "", \%opts, {});
}
push @EXPORT_OK, "data_find_path_eq";

sub data_find_path_num($$;@) {
  my $value = shift;
  my $data = shift;
  my %opts = @_;
  return _data_find_path(sub { $_[0] == $value }, $data, "", \%opts, {});
}
push @EXPORT_OK, "data_find_path_num";

sub _escape { 
  my $input = shift;
  $input =~ s/\\/\\\\/g;  # \ -> \\
  $input =~ s/'/\\'/g;    # ' -> \'
  return $input;
}

=head2 Options

The above functions all take the following options.  They can be
specified by passing them as the last arguments.  For example:

  print data_find_path_eq "foo", $data, inside_objects => 1;

=over

=item inside_objects (boolean)

If this option is enabled objects that are based on hashref or
arrayrefs are searched in the same way that unblessed hashrefs
and arrayrefs are.  It is off by default.

=item inside_matches (boolean)

If this option is enabled then searching continues within
matching data structures.  For example, if your match subroutine
returns true when passed a hashref with this option enabled the
contents of that hashref would also be searched for further matches.
This is off by default.

=back

=head1 AUTHOR

Written by Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

Copryright Photobox 2010.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

This module only searches inside hashref and arrayrefs in your data
structure and makes no attempt to use any magic to delve inside other
data structures.

For obvious reasons if you pass this module a circular data structure
it cannot always return all paths (as there are an infinte number of
them.)  It will return the maximum number of paths without reprocessing
the same part of the data structure a second time.

This module only supports depth first search at this time.

Please report any bugs or feature requests through the web
interface at http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Structure-FindPath

=head1 AVAILABILITY

The latest version of this module is available from the
Comprehensive Perl Archive Network (CPAN). 
visit http://www.perl.com/CPAN/ to find a CPAN site near you,
or see http://search.cpan.org/dist/Data-Structure-FindPath/

The development version lives at http://github.com/2shortplanks/Data-Structure-FindPath/.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 SEE ALSO

L<Data::Visitor> can be used to examine each element of a data
structure.

L<Data::Structure::Utils> has handy functions to extract all
objects or references from a data structure.

L<Tree::Simple> has a bunch of tree functions you might like
to play with.

=cut

1;

