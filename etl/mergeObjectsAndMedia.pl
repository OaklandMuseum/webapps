use strict;

my %count ;
my $delim = "\t";

open MEDIA,$ARGV[0] || die "couldn't open media file $ARGV[0]";
my %media ;
while (<MEDIA>) {
  $count{'media'}++;
  chomp;
  my ($objectcsid, $objectnumber, $mediacsid, $description, $filename, $creatorrefname, $creator, $blobcsid, $copyrightstatement, $identificationnumber, $rightsholderrefname, $rightsholder, $contributor, $approvedforweb, $imageType) = split /$delim/;
  #print "$blobcsid $objectcsid\n";
  $media{$objectcsid} .= $blobcsid . ',';
}

open METADATA,$ARGV[1] || die "couldn't open metadata file $ARGV[1]";
while (<METADATA>) {
  $count{'metadata'}++;
  chomp;
  my ($id, $objectid, @rest) = split /$delim/;
  # insert list of blobs as final column
  my $mediablobs = $media{$objectid};
  my $has_images = 'No';
  if ($mediablobs) {
    $count{'matched'}++;
    $has_images = 'Yes';
  }
  else {
    $count{'unmatched'}++;
    # insert csid of placeholder image
    $mediablobs = '5cfbd545-756a-4874-90eb';

  }
  if ($count{'metadata'} == 1) {
    $mediablobs = 'blob_ss';
    $has_images = 'has_images_s'
  }
  $mediablobs =~ s/,$//; # get rid of trailing comma
  print $_ . $delim . $has_images . $delim . $mediablobs . "\n";
}

foreach my $s (sort keys %count) {
 warn $s . ": " . $count{$s} . "\n";
}
