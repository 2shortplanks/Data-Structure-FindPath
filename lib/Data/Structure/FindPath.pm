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

=head2 Methods

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

=item data_find_path_num $value, $data, 

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

=back

