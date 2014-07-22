package Getopt::Long::Complete;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
                    GetOptions
               );
our @EXPORT_OK = qw(
                    GetOptions
                    GetOptionsWithCompletion
               );

sub GetOptionsWithCompletion {
    my $comps = shift;

    my $hash;
    if (ref($_[0]) eq 'HASH') {
        $hash = shift;
    }

    if (defined $ENV{COMP_LINE}) {
        require Complete::Bash;
        require Complete::Getopt::Long;

        my ($words, $cword) = @{ Complete::Bash::parse_cmdline(
            undef, undef, '=') };
        my $compres = Complete::Getopt::Long::complete_cli_arg(
            words => $words, cword => $cword, getopt_spec=>{ @_ },
            completion => $comps);
        print Complete::Bash::format_completion($compres);
        exit 0;
    }

    require Getopt::Long;
    if ($hash) {
        Getopt::Long::GetOptions($hash, @_);
    } else {
        Getopt::Long::GetOptions(@_);
    }
}

sub GetOptions {
    GetOptionsWithCompletion({}, @_);
}

1;
#ABSTRACT: A drop-in replacement for Getopt::Long, with tab completion

=head1 SYNOPSIS

=head2 First example (simple)

You just replace C<use Getopt::Long> with C<use Getopt::Long::Complete> and your
program suddenly supports tab completion. This works for most/many programs. For
example, below is source code for C<delete-user>.

 use Getopt::Long::Complete;
 my %opts;
 GetOptions(
     'help|h' => sub { ... },
     'user=s' => \$opts{name},
     'force'  => \$opts{force},
 );

To activate completion, put your script somewhere in C<PATH> and execute this in
the shell or put it into your bash startup file (e.g. C</etc/bash_profile> or
C<~/.bashrc>):

 complete -C delete-user delete-user

Now, tab completion works:

 % delete-user <tab>
 --force --help --user -h
 % delete-user --h<tab>

=head2 Second example (added completion)

The previous example only provides completion


=head1 DESCRIPTION

L<Getopt::Long::Complete> is basically just L<Getopt::Long>.


=head1 SEE ALSO

L<Complete::Getopt::Long>

Other option-processing modules featuring shell tab completion:
L<Getopt::Complete>.

L<Perinci::CmdLine> - an alternative way to easily create command-line
applications with completion feature.

=cut
