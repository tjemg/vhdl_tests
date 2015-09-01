#!/usr/bin/perl
#
#
#  Swiss Bit Knife  (SBK)
#  Post-Processing output of PulseView
#  Export as "Gnuplot data format"
#
#  @2015, Tiago Gasiba
#         tiago.gasiba@gmail.com
#

use Data::Dumper;

my %convUnits    = ( MHz => 1.0e6,
                     kHz => 1.0e3,
                      Hz => 1.0   );
my %channelValue = ();
my %indexToLabel = ();
my %labelToIndex = ();
my $samplingFreq = 0.0;
my $numChannels  = 0;
my $numSamples   = 0;

#
# Binary To Unsigned Int conversion
#   binToUint("A3,A2,A1,A0")
#  A3, A2, A1, A0   value       A3, A2, A1, A0   value
#   0   0   0   0     0          1   0   0   0     8
#   0   0   0   1     1          1   0   0   1     9
#   0   0   1   0     2          1   0   1   0     10
#   0   0   1   1     3          1   0   1   1     11
#   0   1   0   0     4          1   1   0   0     12
#   0   1   0   1     5          1   1   0   1     13
#   0   1   1   0     6          1   1   1   0     14
#   0   1   1   1     7          1   1   1   1     15
sub binToUint {
    my ($convStr)  = @_;
    my @usedLabels = split /,/,$convStr;
    my @retVals    = ();

    for my $rowIndex (0..$numSamples-1) {
    my $multiplier  = 1;
    my $accumulator = 0;
    for my $lbl (reverse @usedLabels) {
        my $val = $channelValue{ $labelToIndex{$lbl} }[$rowIndex];
        $accumulator += ($multiplier * $val);
        $multiplier  *= 2;
    }
    push @retVals, $accumulator;
    }
    return @retVals;
}


#
# Binary To Signed Int conversion
#   binToUint("A3,A2,A1,A0")
#  A3, A2, A1, A0   value       A3, A2, A1, A0   value
#   0   0   0   0     0          1   0   0   0     0
#   0   0   0   1     1          1   0   0   1     -1
#   0   0   1   0     2          1   0   1   0     -2
#   0   0   1   1     3          1   0   1   1     -3
#   0   1   0   0     4          1   1   0   0     -4
#   0   1   0   1     5          1   1   0   1     -5
#   0   1   1   0     6          1   1   1   0     -6
#   0   1   1   1     7          1   1   1   1     -7
sub binToSint {
    my ($convStr)     = @_;
    my @usedLabels    = split /,/,$convStr;
    my @retVals       = ();
    my $numUsedLabels = scalar @usedLabels;
    my $signBitVal    = 1 << ($numUsedLabels-1);

    for my $rowIndex (0..$numSamples-1) {
    my $multiplier  = 1;
    my $accumulator = 0;
    my $computedVal = 0;

    for my $lbl (reverse @usedLabels) {
        my $val = $channelValue{ $labelToIndex{$lbl} }[$rowIndex];
        $accumulator += ($multiplier * $val);
        $multiplier  *= 2;
    }

    if ( $signBitVal == ($accumulator & $signBitVal) ){
        $computedVal = - ($accumulator & ($signBitVal-1));
    } else {
        $computedVal = $accumulator;
    }
    push @retVals, $computedVal;
    }
    return @retVals;
}

#
# Binary To Signed Int conversion (2's Complement)
#   binToUint("A3,A2,A1,A0")
#  A3, A2, A1, A0   value       A3, A2, A1, A0   value
#   0   0   0   0     0          1   0   0   0     -8
#   0   0   0   1     1          1   0   0   1     -7
#   0   0   1   0     2          1   0   1   0     -6
#   0   0   1   1     3          1   0   1   1     -5
#   0   1   0   0     4          1   1   0   0     -4
#   0   1   0   1     5          1   1   0   1     -3
#   0   1   1   0     6          1   1   1   0     -2
#   0   1   1   1     7          1   1   1   1     -1
sub binToS2int {
    my ($convStr)     = @_;
    my @usedLabels    = split /,/,$convStr;
    my @retVals       = ();
    my $numUsedLabels = scalar @usedLabels;
    my $signBitVal    = 1 << ($numUsedLabels-1);

    for my $rowIndex (0..$numSamples-1) {
    my $multiplier  = 1;
    my $accumulator = 0;
    my $computedVal = 0;

    for my $lbl (reverse @usedLabels) {
        my $val = $channelValue{ $labelToIndex{$lbl} }[$rowIndex];
        $accumulator += ($multiplier * $val);
        $multiplier  *= 2;
    }

    if ( $signBitVal == ($accumulator & $signBitVal) ){
        $computedVal = -(($accumulator ^ (2*$signBitVal-1))+1);
    } else {
        $computedVal = $accumulator;
    }
    push @retVals, $computedVal;
    }
    return @retVals;
}


open (FD, "<test.dat");
print "############################################################\n";
while ( my $line = <FD> ) {
    chomp $line;
    if ($line =~ m/#\s+(\d+)\s+(.*)$/) {
    my ($index, $label)   = ($1, $2);
    $indexToLabel{$index} = $label;
    print "# '$index' : '$label'\n";
    $numChannels = $index if ($numChannels<$index);
    next;
    }
    if ($line =~ m/Acquisition with.*at (.*) (.*)$/) {
    my ($value, $units) = ($1, $2);
    unless (defined $convUnits{$units}) {
        print "ERROR: Unkown units: $units\n";
        exit -1;
    }
    $samplingFreq = $value * $convUnits{$units};
    print "# Sampling frequency = $samplingFreq\n";
    next;
    }
    if ($line =~ m/^#/) {
    next;
    }
    my @values = ($line =~ m/\d+/g);
    my $valCnt = 0;
    for my $val (@values) {
    if (0==$valCnt) {
        my $convValue = $val / $samplingFreq;
        push @{$channelValue{0}}, $convValue;
    } else {
        push @{$channelValue{$valCnt}}, $val;
    }
    $valCnt++;
    }
    $numSamples++;
}
print "# Total Number of Samples: $numSamples\n";
print "############################################################\n";
close(FD);

%labelToIndex = reverse %indexToLabel;
###############################################################################################################
# ADAPT TO WANTED EXPRESSION HERE       ADAPT TO WANTED EXPRESSION HERE       ADAPT TO WANTED EXPRESSION HERE #
###############################################################################################################
my @outVec    = ( [binToS2int("B7,B6,B5,B4,B3,B2,B1,B0,A7,A6,A5,A4,A3,A2,A1,A0")]  );
###############################################################################################################
###############################################################################################################
###############################################################################################################
my $numOutVec = scalar (@outVec);


for my $n (0..$numSamples-1) {
    my @lineVec = ();
    for my $rowVal (@outVec) {
        push @lineVec, ${$rowVal}[$n];
    }
    print "$n @lineVec\n";
}
