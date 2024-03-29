use strict;
use warnings;
package Test::Deep::UnorderedPairs;
{
  $Test::Deep::UnorderedPairs::VERSION = '0.003';
}
# git description: v0.002-3-g11fa25b

BEGIN {
  $Test::Deep::UnorderedPairs::AUTHORITY = 'cpan:ETHER';
}
# ABSTRACT: A Test::Deep plugin for comparing lists as if they were hashes

use parent 'Test::Deep::Cmp';
use Exporter 'import';
use Carp 'confess';
use Test::Deep::Hash;
use Test::Deep::ArrayLength;

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

    $self->{val} = \@vals;
}

sub descend
{
    my ($self, $got) = @_;

    my $exp = $self->{val};

    return 0 unless Test::Deep::ArrayLength->new(@$exp + 0)->descend($got);

    # check that all the keys are present -- can test as a bag

    my @exp_keys = _keys_of_list($exp);
    my @got_keys = _keys_of_list($got);

    return 0 unless Test::Deep::descend(\@got_keys, Test::Deep::UnorderedPairKeys->new(@exp_keys));

    Test::Deep::descend($got, Test::Deep::UnorderedPairElements->new($exp));
}

sub _keys_of_list
{
    my $list = shift;

    my $i = 0;
    map { $i++ % 2 ? () : $_ } @$list;
}


package Test::Deep::UnorderedPairKeys;
{
  $Test::Deep::UnorderedPairKeys::VERSION = '0.003';
}
# git description: v0.002-3-g11fa25b

BEGIN {
  $Test::Deep::UnorderedPairKeys::AUTHORITY = 'cpan:ETHER';
}
use parent 'Test::Deep::Set';

sub init
{
    # quack like a bag
    shift->SUPER::init(0, '', @_);
}

sub diagnostics
{
    my ($self, $where, $last) = @_;

    my $error = $last->{diag};
    my $diag = <<EOM;
Comparing keys of $where
$error
EOM

    return $diag;
}


package Test::Deep::UnorderedPairElements;
{
  $Test::Deep::UnorderedPairElements::VERSION = '0.003';
}
# git description: v0.002-3-g11fa25b

BEGIN {
  $Test::Deep::UnorderedPairElements::AUTHORITY = 'cpan:ETHER';
}
use parent 'Test::Deep::Cmp';

sub init
{
    my ($self, $val) = @_;
    $self->{val} = $val;
}

# we assume the keys are already verified as identical.
sub descend
{
    my ($self, $got) = @_;

    # make copy, as we are going to modify this one!
    my @exp = @{$self->{val}};
    my $data = $self->data;

    GOT_KEY: for (my $got_index = 0; $got_index < @$got; $got_index += 1)
    {
        # find the first occurrence of $key in @exp
        EXP_KEY: for (my $exp_index = 0; $exp_index < @exp; $exp_index += 1)
        {
            if (not Test::Deep::eq_deeply_cache($got->[$got_index], $exp[$exp_index]))
            {
                # advance to the next key position
                ++$exp_index;
                next;
            }

            # found a matching key in got and exp

            $data->{got_index} = ++$got_index;
            $data->{exp_value} = $exp[++$exp_index];

            if (Test::Deep::eq_deeply_cache($got->[$got_index], $data->{exp_value}))
            {
                # splice this out of the exp list and continue with the next key
                splice(@exp, $exp_index - 1, 2);
                next GOT_KEY;
            }

            # values do not match - keep looking for another match unless there are no more!
        }

        # got to the end of exp_keys, but still no matches found
        return 0;
    }

    # exhausted all got_keys. if everything matched, @exp would be empty
    return @exp ? 0 : 1;
}

sub render_stack
{
    my ($self, $var, $data) = @_;
    $var .= "->" unless $Test::Deep::Stack->incArrow;
    $var .= '[' . $data->{got_index} . ']';

    return $var;
}

sub reset_arrow
{
    return 0;
}

sub renderGot
{
    my ($self, $got) = @_;
    return $self->SUPER::renderGot($got->[$self->data->{got_index}]);
}

sub renderExp
{
    my $self = shift;
    return $self->SUPER::renderGot($self->data->{exp_value});
}

1;

__END__

=pod

=encoding utf-8

=for :stopwords Karen Etheridge tuples irc

=head1 NAME

Test::Deep::UnorderedPairs - A Test::Deep plugin for comparing lists as if they were hashes

=head1 VERSION

version 0.003

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

This module provides the sub C<unordered_pairs>
(and C<tuples>, C<samehash>, as synonyms)
to indicate the data being tested is a list of pairs that should be tested
where the order of the pairs is insignificant.

This is useful when testing a function that returns a list of hash elements as
an arrayref, not a hashref.  One such application might be testing L<PSGI>
headers, which are passed around as an arrayref:

    my $response = [
        '200',
        [
            'Content-Length' => '12',
            'Content-Type' => 'text/plain',
        ],
        [ 'hello world!' ],
    ];

    # this test passes
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
