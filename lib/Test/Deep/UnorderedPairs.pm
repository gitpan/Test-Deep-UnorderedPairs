use strict;
use warnings;
package Test::Deep::UnorderedPairs;
{
  $Test::Deep::UnorderedPairs::VERSION = '0.001';
}
# git description: 02132a1

BEGIN {
  $Test::Deep::UnorderedPairs::AUTHORITY = 'cpan:ETHER';
}
# ABSTRACT: A Test::Deep plugin for comparing lists as if they were hashes

use parent 'Test::Deep::Cmp';
use Exporter 'import';
use Carp 'confess';
use Test::Deep::Hash;

# I'm not sure what name is best; decide later
our @EXPORT = qw(tuples unordered_pairs samehash);

sub tuples
{
    return __PACKAGE__->new(@_);
}
sub unordered_pairs { goto &tuples }
sub samehash { goto &tuples }

sub init
{
    my ($self, @vals) = @_;

    confess 'tuples must have an even number of elements'
        if @vals % 2;

    $self->{val_as_hash} = Test::Deep::Hash->new({ @vals });
}

sub descend
{
    my ($self, $got) = @_;

    return 0 unless $self->test_reftype($got, 'ARRAY');

    # simply compare as a hashref
    my $exp = $self->{val_as_hash};

    if ($exp->descend( { @$got } ))
    {
        $Test::Deep::Stack->pop;
        return 1;
    }
    return 0;
}

1;

__END__

=pod

=encoding utf-8

=for :stopwords Karen Etheridge tuples irc

=head1 NAME

Test::Deep::UnorderedPairs - A Test::Deep plugin for comparing lists as if they were hashes

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Test::More;
    use Test::Deep;
    use Test::Deep::UnorderedPairs;

    cmp_deeply(
        {
            inventory => [
                pear => 6,
                peach => 5,
                apple => 1,
            ],
        },
        {
            inventory => unordered_pairs(
                apple => 1,
                peach => ignore,
                pear => 6,
            ),
        },
        'got the right inventory',
    );

=head1 DESCRIPTION

This module provides the sub C<unordered_pairs> (and C<tuples>, as a synonym)
to indicate the data being tested is a list of pairs that should be tested
where the order of the pairs is insignificant.  This would be equivalent to
testing the list is as if it were a hash.

This is useful when testing a function that returns a list of hash elements as
an arrayref, not a hashref.  One such application might be testing L<PSGI>
headers, which are passed around as an arrayref:

    cmp_deeply(
        $response,
        [
            '200',
            unordered_pairs(
                'Content-Type' => 'text/plain',
                'Content-Length' => '12',
            ],
            [ 'hello world!' ],
        ],
        'check headers as an arrayref of unordered pairs',
    );

=head1 FUNCTIONS/METHODS

=for Pod::Coverage init
descend

=over

=item * C<unordered_pairs>

Pass an (even-numbered) list of items to test

=item * C<tuples>, C<samehash>

C<tuples> and C<samehash> are aliases for C<unordered_pairs>.  I'm open to more names as well;
I'm not quite yet sure what the best nomenclature should be.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Deep-UnorderedPairs>
(or L<bug-Test-Deep-UnorderedPairs@rt.cpan.org|mailto:bug-Test-Deep-UnorderedPairs@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 ACKNOWLEDGEMENTS

Ricardo Signes, for maintaining L<Test::Deep> and for being the first consumer
of this module, in L<Router::Dumb>.

=head1 SEE ALSO

L<Test::Deep>

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
