package Data::Object::Exception;

use 5.014;

use strict;
use warnings;
use routines;

use Moo;

use overload (
  '""' => 'explain',
  '~~' => 'explain',
  fallback => 1
);

# VERSION

has id => (
  is => 'ro'
);

has context => (
  is => 'ro'
);

has frames => (
  is => 'ro'
);

has message => (
  is => 'ro',
  default => 'Exception!'
);

# BUILD

fun BUILD($self, $args) {

  # build stack trace
  return $self->trace(2) if !$self->frames;
}

fun BUILDARGS($class, @args) {

  # constructor arguments
  return {
    @args == 1
      # ...
      ? !ref($args[0])
        # single non-ref argument
        ? (message => $args[0])
        # ...
        : 'HASH' eq ref($args[0])
        # single hash-based argument
        ? %{$args[0]}
        # non hash-based argument
        : ()
        # multiple arguments
      : @args
  };
}

# FUNCTIONS

fun throw($self, $message, $context, $offset) {
  my $class = ref $self || $self;

  my $id;
  my $frames;

  my $args = {};

  if (ref $self) {
    for my $name (keys %$self) {
      $args->{$name} = $self->{$name};
    }
  }

  $args->{message} = $message if $message;
  $args->{context} = $context if $context;

  my $exception = $self->new($args);

  die $exception->trace($offset);
}

# METHODS

method explain() {
  $self->trace(1, 1) if !$self->{frames};

  my $frames = $self->{frames};

  my $file = $frames->[0][1];
  my $line = $frames->[0][2];
  my $pack = $frames->[0][0];
  my $subr = $frames->[0][3];

  my $message = $self->{message} || 'Exception!';

  my @stacktrace = ("$message in $file at line $line");

  for (my $i = 1; $i < @$frames; $i++) {
    my $pack = $frames->[$i][0];
    my $file = $frames->[$i][1];
    my $line = $frames->[$i][2];
    my $subr = $frames->[$i][3];

    push @stacktrace, "\t$subr in $file at line $line";
  }

  return join "\n", @stacktrace, "";
}

method trace($offset, $limit) {
  $self->{frames} = my $frames = [];

  for (my $i = $offset // 1; my @caller = caller($i); $i++) {
    push @$frames, [@caller];

    last if defined $limit && $i + 1 == $offset + $limit;
  }

  return $self;
}

1;
