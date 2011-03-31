use strict;
use warnings;

use Test::More;

use lib 't/lib';
use aliased 'App::Mimosa::Test::Mech';

my $mech = Mech->new;

$mech->get_ok('/');

$mech->submit_form_ok({
    form_name => 'main_input_form',
    fields => {
        sequence => 'ATGCTAGTCGTCGATAGTCGTAGTAGCTGA',
        mimosa_sequence_set_id => 1,
      },
},
'submit single sequence with defaults',
);

$mech->content_contains('Report');
$mech->content_contains('Altschul');

# now try a spammy submission
$mech->get_ok('/');
$mech->submit_form_ok({
    form_name => 'main_input_form',
    fields => {
        sequence => '<a href="spammy.html">Spammy McSpammerson!</a>',
        mimosa_sequence_set_id => 0,
    },
});
$mech->content_like( qr!Hits_to_DB</td>\s*<td>0!i )
  or diag $mech->content;

# now try a spammy submission
$mech->get_ok('/');
$mech->submit_form(
    form_name => 'main_input_form',
    fields => {
        sequence => '',
        mimosa_sequence_set_id => 0,
    },
);
$mech->content_like( qr/error/i );
is $mech->status, 400, 'input error for empty sequence';

#try an submission that will be sure to get us an ungapped error
$mech->get_ok('/');
$mech->submit_form(
    form_name => 'main_input_form',
    fields => {
        filtered => 'T',
        sequence => 'A'x40,
        mimosa_sequence_set_id => 1,
    },
);
$mech->content_like( qr/error/i );
is $mech->status, 400, 'input error for ungapped stuff';



done_testing;
