for interface in (networksetup -listallhardwareports | awk '/^Device:/ {print $2}')
    set ip (ipconfig getifaddr $interface)
    if test -n "$ip"
        echo "$interface: $ip"
    end
end
