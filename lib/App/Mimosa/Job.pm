package App::Mimosa::Job;
use Moose;
use namespace::autoclean;
use autodie ':all';

use Bio::SeqIO;
use Moose::Util::TypeConstraints;

use File::Slurp qw/slurp/;
use File::Temp qw/tempfile/;

use IPC::Run;

# Good breakdown of commandline flags
# http://www.molbiol.ox.ac.uk/analysis_tools/BLAST/BLAST_blastall.shtml
subtype 'Program'
             => as Str
             => where {
                    /^blast(n|p|all)$/;
                };
subtype 'SubstitutionMatrix'
             => as Str
             => where {
                    /^(BLOSUM|PAM)\d\d$/;
                };

# validate!
has program => (
    isa     => 'Program',
    is      => 'rw',
    default => 'blastn',
);

has mimosa_sequence_set_id => (
    is      => 'ro',
    isa     => 'Int',
);

has input_file => (
    isa => 'Str',
    is  => 'rw',
);

has output_file => (
    isa => 'Str',
    is  => 'rw',
);

has evalue => (
    isa => 'Num',
    is  => 'rw',
    default => 0.01,
);

has maxhits => (
    isa => 'Int',
    is  => 'rw',
    default => 100,
);

has matrix => (
    isa     => 'SubstitutionMatrix',
    is      => 'rw',
    default => 'BLOSUM62',
);

enum 'BoolStr' => qw(T F);

has filtered => (
    isa     => 'BoolStr',
    is      => 'rw',
    default => 'T',
);


sub run {
    my ($self) = @_;

    my @blast_cmd = (
        'blastall',
        -d => "$ENV{PWD}/examples/data/solanum_peruvianum_mRNA.seq",
        -M => $self->matrix,
        -b => $self->maxhits,
        -e => $self->evalue,
        -v => 1,
        -p => $self->program,
        -F => $self->filtered,
        -i => $self->input_file,
        -o => $self->output_file,
      );

    my $console_output = File::Temp->new;
    my $success = IPC::Run::run \@blast_cmd, \*STDIN, $console_output, $console_output;
    $console_output->close;
    unless( $success ) {
        return $self->_error_output( $console_output );
    }
    return;
}

sub _error_output {
    my ( $self, $tempfile ) = @_;
    my $max_lines    = 50;
    my $error_output = '';
    open my $f, "$tempfile";
    while( $max_lines-- and my $line = <$f> ) {
        $error_output .= $line;
    }
    return $error_output;
}

1;
