use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Warnings;
use Test::Fatal;
use Test::Deep qw(cmp_details deep_diag);
use Test::Deep::UnorderedPairs;

like(
    exception { tuples(1) },
    qr/^tuples must have an even number of elements/,
    'wrong number of tuple elements',
);

my @tests = (
    'wrong type - should be array' => {
        got => { foo => 2 },
        exp => tuples(foo => 1),
        ok => 0,
        diag => qr/^Compared reftype\(\$data\)\n\s+got : 'HASH'\nexpect : 'ARRAY'\n$/,
    },
    'key does not match' => {
        got => [ foo => 2 ],
        exp => tuples(bar => 2),
        ok => 0,
        diag => "Comparing hash keys of \$data\nMissing: 'bar'\nExtra: 'foo'\n",
    },
    'value does not match' => {
        got => [ foo => 2 ],
        exp => tuples(foo => 1),
        ok => 0,
        diag => qr/^Compared \$data->{"foo"}\n\s+got : '2'\nexpect : '1'\n$/,
    },
    'one of the values does not match' => {
        got => [ bar => 2, foo => 2 ],
        exp => tuples(foo => 1, bar => 2),
        ok => 0,
        diag => qr/^Compared \$data->{"foo"}\n\s+got : '2'\nexpect : '1'\n$/,
    },
    'single tuple match' => {
        got => [ foo => 1 ],
        exp => tuples(foo => 1),
        ok => 1,
    },
    'two tuples match' => {
        got => [ foo => 1, bar => 2 ],
        exp => tuples(foo => 1, bar => 2),
        ok => 1,
    },
    'unordered match',
    {
        got => [ bar => 2, foo => 1 ],
        exp => tuples(foo => 1, bar => 2),
        ok => 1,
    },
);

while (my ($test_name, $test) = (shift(@tests), shift(@tests)))
{
    last if not $test_name;

    subtest $test_name => sub {
        my ($ok, $stack) = cmp_details(@{$test}{qw(got exp)});

        ok( !($ok xor $test->{ok}), 'test ' . ($test->{ok} ? 'passed' : 'failed'));
        return if not Test::Builder->new->is_passing;

        if (not $ok)
        {
            my $diag = deep_diag($stack);
            if (__is_regexp($test->{diag}))
            {
                like($diag, $test->{diag}, 'failure diagnostics');
            }
            else
            {
                is($diag, $test->{diag}, 'failure diagnostics');
            }
        }
    };
}

sub __is_regexp
{
    re->can('is_regexp') ? re::is_regexp(shift) : ref(shift) eq 'Regexp';
}

done_testing;
