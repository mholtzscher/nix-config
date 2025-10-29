if not command -q fzf
    echo "fzf is not installed. Please install 'fzf' to use this function."
    return 1
end

if not command -q bat
    echo "bat is not installed. Please install 'bat' to use this function."
    return 1
end

if not command -q fd
    echo "fd is not installed. Please install 'fd' to use this function."
    return 1
end

set -l preview_command "bat --color=always --plain --line-range :50 {}"

set -l selected_files (fd -t f | fzf -m --height 60% --border --preview "$preview_command" --preview-window "right:60%:wrap")
if test -z "$selected_files"
    echo "No files selected."
    return 0
end

# Confirm before adding to chezmoi
echo "The following files will be added to chezmoi:"
for file in $selected_files
    echo "  $file"
end

read -P "Proceed with 'chezmoi add'? (Y/n) " -l confirmation

if not string match -q -- n (string lower -- "$confirmation")
    # Add the selected files to chezmoi
    echo "Adding files to chezmoi..."
    chezmoi add $selected_files

    # Check the exit status of the chezmoi add command
    if test $status -eq 0
        echo "Files successfully added to chezmoi."
    else
        echo "An error occurred while adding files to chezmoi. Exit status: $status"
        return $status
    end
else
    echo "Operation cancelled by user."
end

return 0
