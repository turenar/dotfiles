#!/bin/sh
TIMEFORMAT="real %lR / user %lU / sys %lS"
echo "line count: $($@ | wc -l)"
printf "\e[38;5;46mlog_output:\t\t"
time ./log_output $@ >/dev/null
printf "\e[38;5;226mcronlog.pl:\t\t"
time perl cronlog.pl $@ >/dev/null
printf "\e[38;5;46mlog_output -M50:\t"
time ./log_output -M 50 $@ >/dev/null
printf "\e[38;5;226mcronlog.pl -M50:\t"
time perl cronlog.pl $@ | head -n 50 >/dev/null
printf "\e[38;5;46mlog_output -t:\t\t"
time ./log_output --timestamp $@ >/dev/null
printf "\e[38;5;226mcronlog.pl -t:\t\t"
time perl cronlog.pl --timestamp $@ >/dev/null
printf "\e[38;5;46mlog_output -t -M50:\t"
time ./log_output --timestamp -M 50 $@ >/dev/null
printf "\e[38;5;226mcronlog.pl -t -M50:\t"
time perl cronlog.pl --timestamp $@ | head -n 50 >/dev/null
printf "\e[38;5;46mlog_output -P:\t\t"
time ./log_output --print-always $@ >/dev/null
printf "\e[38;5;226mcronlog.pl -P:\t\t"
time perl cronlog.pl --print-always $@ >/dev/null
printf "\e[38;5;46mlog_output -P -t:\t"
time ./log_output --print-always --timestamp $@ >/dev/null
printf "\e[38;5;226mcronlog.pl -P -t:\t"
time perl cronlog.pl --print-always --timestamp $@ >/dev/null

