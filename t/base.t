#! -*- perl -*-
print "1..1\n";
eval { require IO::Tee; };
printf("%s 1\n", $@ ? "not ok" : "ok");
