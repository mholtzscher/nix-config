if test (count $argv) -lt 2
    echo "Usage: fish_watch <interval> <command>"
    return 1
end

set interval $argv[1]
set command (string join " " $argv[2..-1])

while true
    clear
    eval $command
    sleep $interval
end
