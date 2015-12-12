#!/bin/bash

target=$(perl -MCAM::PDF -e 'print $INC{"CAM/PDF.pm"};')
chmod 644 $target

cat <<'EOF' | patch $target
--- PDF.pm~     2014-07-28 19:12:10.340394556 +0200
+++ PDF.pm      2014-07-28 19:13:28.436396955 +0200
@@ -311,9 +311,10 @@
       if (1024 > length $content)
       {
          my $file = $content;
+         $content = q{};
+
          if ($file eq q{-})
          {
-            $content = q{};
             my $offset = 0;
             my $step = 4096;
             binmode STDIN; ##no critic (Syscalls)
EOF

chmod 444 $target
