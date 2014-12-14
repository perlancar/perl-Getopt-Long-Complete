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
    my $comp = shift;

    my $hash;
    if (ref($_[0]) eq 'HASH') {
        $hash = shift;
    }

    my $shell;
    if ($ENV{COMP_SHELL}) {
        ($shell = $ENV{COMP_SHELL}) =~ s!.+/!!;
    } elsif ($ENV{COMMAND_LINE}) {
        $shell = 'tcsh';
    } else {
        $shell = 'bash';
    }

    if ($ENV{COMP_LINE} || $ENV{COMMAND_LINE}) {
        my ($words, $cword);
        if ($ENV{COMP_LINE}) {
            require Complete::Bash;
            ($words,$cword) = @{Complete::Bash::parse_cmdline(undef,undef,'=')};
        } elsif ($ENV{COMMAND_LINE}) {
            require Complete::Tcsh;
            $shell = 'tcsh';
            ($words, $cword) = @{ Complete::Tcsh::parse_cmdline() };
        }

        require Complete::Getopt::Long;

        shift @$words; $cword--; # strip program name
        my $compres = Complete::Getopt::Long::complete_cli_arg(
            words => $words, cword => $cword, getopt_spec=>{ @_ },
            completion => $comp);

        if ($shell eq 'bash') {
            print Complete::Bash::format_completion($compres);
        } elsif ($shell eq 'tcsh') {
            print Complete::Tcsh::format_completion($compres);
        } else {
            die "Unknown shell '$shell'";
        }

        exit 0;
    }

    require Getopt::Long;
    my $old_conf = Getopt::Long::Configure('no_ignore_case', 'bundling');
    if ($hash) {
        Getopt::Long::GetOptions($hash, @_);
    } else {
        Getopt::Long::GetOptions(@_);
    }
    Getopt::Long::Configure($old_conf);
}

sub GetOptions {
    GetOptionsWithCompletion(undef, @_);
}

1;
#ABSTRACT: A drop-in replacement for Getopt::Long, with shell tab completion

=head1 SYNOPSIS

=head2 First example (simple)

You just replace C<use Getopt::Long> with C<use Getopt::Long::Complete> and your
program suddenly supports tab completion. This works for most/many programs. For
example, below is source code for C<delete-user>.

 use Getopt::Long::Complete;
 my %opts;
 GetOptions(
     'help|h'     => sub { ... },
     'on-fail=s'  => \$opts{on_fail},
     'user|U=s'   => \$opts{name},
     'force'      => \$opts{force},
     'verbose!'   => \$opts{verbose},
 );

Several shells are supported. To activate completion, see L</"DESCRIPTION">.
After activation, tab completion works:

 % delete-user <tab>
 --force --help --noverbose --no-verbose --on-fail --user --verbose -h
 % delete-user --h<tab>

=head2 Second example (additional completion)

The previous example only provides completion for option names. To provide
completion for option values as well as arguments, you need to provide more
hints. Instead of C<GetOptions>, use C<GetOptionsWithCompletion>. It's basically
the same as C<GetOptions> but accepts an extra coderef in the first argument.
The code will be invoked when completion to option value or argument is needed.
Example:

 use Getopt::Long::Complete qw(GetOptionsWithCompletion);
 use Complete::Unix qw(complete_user);
 use Complete::Util qw(complete_array_elem);
 my %opts;
 GetOptionsWithCompletion(
     sub {
         my %args  = @_;
         my $word  = $args{word}; # the word to be completed
         my $type  = $args{type}; # 'optname', 'optval', or 'arg'
         my $opt   = $args{opt};
         if ($type eq 'optval' && $opt eq '--on-fail') {
             return complete_array_elem(words=>[qw/die warn ignore/], word=>$word);
         } elsif ($type eq 'optval' && ($opt eq '--user' || $opt eq '-U')) {
             return complete_user(word=>$word);
         } elsif ($type eq 'arg') {
             return complete_user(word=>$word);
         }
         [];
     },
     'help|h'     => sub { ... },
     'on-fail=s'  => \$opts{on_fail},
     'user=s'     => \$opts{name},
     'force'      => \$opts{force},
     'verbose!'   => \$opts{verbose},
 );


=head1 DESCRIPTION

This module provides a quick and easy way to add shell tab completion feature to
your scripts, including scripts already written using the venerable
L<Getopt::Long> module. Currently bash and tcsh are directly supported; fish and
zsh are also supported via L<shcompgen>.

This module is basically just a thin wrapper for Getopt::Long. Its C<GetOptions>
function just checks for COMP_LINE/COMP_POINT environment variable (in the case
of bash) or COMMAND_LINE (in the case of tcsh) before passing its arguments to
C<Getopt::Long>'s C<GetOptions>. If those environment variable(s) are defined,
completion reply will be printed to STDOUT and then the program will exit.
Otherwise, Getopt::Long's GetOptions is called.

To keep completion quick, you should do C<GetOptions()> or
C<GetOptionsWithCompletion()> as early as possible in your script. Preferably
before loading lots of other Perl modules.

To activate tab completion in bash, put your script somewhere in C<PATH> and
execute this in the shell or put it into your bash startup file (e.g.
C</etc/bash.bashrc> or C<~/.bashrc>). Replace C<delete-user> with the actual
script name:

 complete -C delete-user delete-user

For tcsh:

 complete delete-user 'p/*/`delete-user`/'

For other shells (but actually for bash too) you can use L<shcompgen>.


=head1 FUNCTIONS

=head2 GetOptions([\%hash, ]@spec)

Will call Getopt::Long's GetOptions, except when COMP_LINE environment variable
is defined, in which case will print completion reply to STDOUT and exit.

B<Note: Will temporarily set Getopt::Long configuration as follow: bundling,
no_ignore_case. I believe this a sane default.>

=head2 GetOptionsWithCompletion(\&completion, [\%hash, ]@spec)

Just like C<GetOptions>, except that it accepts an extra first argument
C<\&completion> containing completion routine for completing option I<values>
and arguments. This will be passed as C<completion> argument to
L<Complete::Getopt::Long>'s C<complete_cli_arg>. See that module's documentation
on details of what is passed to the routine and what return value is expected
from it.


=head1 SEE ALSO

L<Complete::Getopt::Long> (the backend for this module), C<Complete::Bash>,
C<Complete::Tcsh>.

Other option-processing modules featuring shell tab completion:
L<Getopt::Complete>.

L<Perinci::CmdLine> - an alternative way to easily create command-line
applications with completion feature.

L<shcompgen>

L<Pod::Weaver::Section::Completion::GetoptLongComplete>

=cut
