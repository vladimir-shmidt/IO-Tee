# -*- perl -*-

require IO::Tee;
require IO::File;

sub CmpFile($$) {
    my($file, $contents) = @_;
    my($fh) = IO::File->new($file, 'r');
    if (!$fh) {
	print STDERR "Cannot open $file: $!\n";
    }
    my($c);
    $fh->read($c, 1024);
    return $c eq $contents;
}

print "1..13\n";

my($fh) = IO::Tee->new(IO::File->new('a', 'w+'), IO::File->new('b', 'w'));
printf("%s 1\n", $fh ? "ok" : "not ok");

my($ok) = $fh->print("skjdh87\n");
printf("%s 2\n", $fh ? "ok" : "not ok");

$ok = $fh->printf("%s%d\n", "abc", 7);
printf("%s 3\n", $fh ? "ok" : "not ok");

$ok = $fh->write ("abcdef\n", 2, 4);
printf("%s 4\n", $fh ? "ok" : "not ok");

$ok = $fh->close();
printf("%s 5\n", $fh ? "ok" : "not ok");

$fh = CmpFile('a', "skjdh87\nabc7\nef");
printf("%s 6\n", $fh ? "ok" : "not ok");

$fh = CmpFile('b', "skjdh87\nabc7\nef");
printf("%s 7\n", $fh ? "ok" : "not ok");

$fh = IO::Tee->new(IO::File->new('a', 'r'), IO::File->new('b', 'w'));
printf("%s 8\n", $fh ? "ok" : "not ok");

$ok = $fh->getc();
printf("%s 9\n", $fh ? "ok" : "not ok");

$ok = $fh->getline();
printf("%s 10\n", $fh ? "ok" : "not ok");

$ok = $fh->getlines();
printf("%s 11\n", $fh ? "ok" : "not ok");

$ok = $fh->close();
printf("%s 12\n", $fh ? "ok" : "not ok");

$fh = CmpFile('b', "skjdh87\nabc7\nef");
printf("%s 13\n", $fh ? "ok" : "not ok");
