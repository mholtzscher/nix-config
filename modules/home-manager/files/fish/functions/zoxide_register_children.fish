set -f target_dir (pwd)

echo "Adding current directory to zoxide: $target_dir"
zoxide add "$target_dir"

echo "Scanning for child directories in: $target_dir"
set -l count 0
fd --type d --maxdepth 1 . | while read -L child_dir
    if test -n "$child_dir" # Ensure read command got a non-empty string
        echo "  Adding: $child_dir"
        zoxide add "$child_dir"
        set count (math $count + 1)
    end
end

if test $count -eq 0
    echo "No child directories found to add."
else
    echo "Done. Added $count child directories to zoxide."
end
