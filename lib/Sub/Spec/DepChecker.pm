package Sub::Spec::DepChecker;
{
  $Sub::Spec::DepChecker::VERSION = '0.03';
}

use 5.010;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(check_deps);

# VERSION

sub check_deps {
    my ($val) = @_;
    #say "D:check: ", dump($val);
    while (my ($cname, $cval) = each %$val) {
        return "Unknown dependency clause: $cname"
            unless defined &{"checkdep_$cname"};
        my $check = \&{"checkdep_$cname"};
        my $res = $check->($cval);
        if ($res) {
            $res = "$cname: $res";
            return $res;
        }
    }
    "";
}

sub checkdep_all {
    my ($cval) = @_;
    #say "D:check_all: ", dump($cval);
    for (@$cval) {
        my $res = check_deps($_);
        return "Some dependency not met: $res" if $res;
    }
    "";
}

sub checkdep_any {
    my ($cval) = @_;
    my $nfail = 0;
    for (@$cval) {
        return "" unless check_deps($_);
        $nfail++;
    }
    $nfail ? "None of the dependencies are met" : "";
}

sub checkdep_none {
    my ($cval) = @_;
    for (@$cval) {
        my $res = check_deps($_);
        return "A dependency is met when it shouldn't: $res" unless $res;
    }
    "";
}

sub checkdep_mod {
    my ($cval) = @_;
    my $m = $cval;
    $m =~ s!::!/!g;
    $m .= ".pm";
    #eval { require $m } ? "" : "Can't load module $cval: $@";
    eval { require $m } ? "" : "Can't load module $cval";
}

sub checkdep_sub {
    my ($cval) = @_;
    my ($pkg, $name);
    if ($cval =~ /(.*)::(.+)/) {
        $pkg = $1 || "main";
        $name = $2;
    } else {
        $pkg = "main";
        $name = $cval;
    }
    no strict 'refs';
    my $stash = \%{"$pkg\::"};
    $stash->{$name} ? "" : "Subroutine $cval doesn't exist";
}

sub checkdep_env {
    my ($cval) = @_;
    $ENV{$cval} ? "" : "Environment variable $cval not set/true";
}

sub checkdep_code {
    my ($cval) = @_;
    $cval->() ? "" : "code doesn't return true value";
}

sub checkdep_exec {
    my ($cval) = @_;

    if ($cval =~ m!/!) {
        return "Executable $cval not available" unless (-x $cval);
    } else {
        require File::Which;
        return "$cval not found in PATH" unless File::Which::which($cval);
    }
    "";
}

1;
# ABSTRACT: Check dependencies from 'deps' spec clause


__END__
=pod

=head1 NAME

Sub::Spec::DepChecker - Check dependencies from 'deps' spec clause

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use Sub::Spec::DepChecker qw(check_deps);
 my $err = check_deps($spec->{deps});
 print "Dependencies not met: $err" if $err;

=head1 DESCRIPTION

B<NOTICE>: This module and the L<Sub::Spec> standard is deprecated as of Jan
2012. L<Rinci> is the new specification to replace Sub::Spec, it is about 95%
compatible with Sub::Spec, but corrects a few issues and is more generic.
C<Perinci::*> is the Perl implementation for Rinci and many of its modules can
handle existing Sub::Spec sub specs.

The 'deps' spec clause adds information about subroutine dependencies. This
module performs check on it.

To handle a new dependency clause, create a checkdep_CLAUSE() into
Sub::Spec::DepChecker namespace.

=head1 SEE ALSO

L<Sub::Spec>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

