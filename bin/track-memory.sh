#!/usr/bin/env bash
#
# https://milianw.de/code-snippets/tracking-memory-consumption-using-pmap.html

set -e

if [ -z "${1}" ]
then
  echo "pass a program in..."
  exit 1
fi

# This loops forever waiting to find the application running.
while ! pgrep "${1}" > /dev/null; do sleep 0.1; done
pid=$(pgrep "${1}")

echo "pid: ${pid}"

logfile=$(mktemp)

while [[ "$(ps -p $pid | grep $pid)" != "" ]]
do
  pmap -x $pid | tail -n1 >> $logfile
  sleep 0.1
done

title=$(head -n1 "$logfile")
timeout=$(head -n2 "$logfile" | tail -n1)

gnuplot -p -e "
set title '${title/\# /}';
set xlabel 'snapshot ~${timeout/\# /}s';
set ylabel 'memory consumption in Kb';
set key bottom right;
plot \
  '$logfile' using 4 w lines title 'RSS' lt 1, \
  '$logfile' using 4 smooth bezier w lines title 'RSS (smooth)' lt 7, \
  '$logfile' using 5 w lines title 'Dirty' lt 2, \
  '$logfile' using 5 smooth bezier w lines title 'Dirty (smooth)' lt 3;
";
