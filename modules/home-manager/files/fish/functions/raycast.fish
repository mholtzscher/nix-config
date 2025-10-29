echo "Attempting to restart Raycast..."

pkill -f Raycast
if test $status -eq 0
    echo "Raycast process found and terminated."
else
    echo "Raycast process not found or already terminated."
end

# Wait for a short period to ensure the process has fully terminated.
# This can sometimes prevent issues with relaunching too quickly.
sleep 1

open -a Raycast
if test $status -eq 0
    echo "Raycast launched successfully."
else
    echo "Failed to launch Raycast. Make sure it's installed correctly."
end
