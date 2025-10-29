# --- Dependency Check ---
# Ensure that 'jq' for JSON processing and 'delta' for diffing are installed.
if not command -v jq >/dev/null
    echo "Error: 'jq' is not installed. Please install it to proceed." >&2
    echo "On macOS: brew install jq" >&2
    return 1
end

if not command -v delta >/dev/null
    echo "Error: 'delta' is not installed. Please install it to proceed." >&2
    echo "See installation instructions at: https://github.com/dandavison/delta" >&2
    return 1
end

# --- Clipboard Access (macOS) ---
# Using 'pbpaste' which is the standard clipboard command on macOS.
if not command -v pbpaste >/dev/null
    echo "Error: 'pbpaste' command not found. This function is intended for macOS." >&2
    return 1
end

# --- Read and Validate JSON ---
# Read the content from the clipboard into a variable.
set -l json_string (pbpaste)

# Check if the clipboard was empty.
if test -z "$json_string"
    echo "Error: Clipboard is empty." >&2
    return 1
end

# Use jq's exit code (-e) to validate if the string is valid JSON.
if not echo "$json_string" | jq -e . >/dev/null
    echo "Error: Clipboard content is not valid JSON." >&2
    return 1
end

# Check if the JSON is an array and contains exactly two elements.
set -l array_length (echo "$json_string" | jq 'if type == "array" then length else -1 end')

if test "$array_length" -ne 2
    echo "Error: Expected a JSON array with exactly two objects in the clipboard." >&2
    echo "Found an item of type '(echo "$json_string" | jq -r 'type')' with length $array_length." >&2
    return 1
end

# --- Perform the Diff ---
# Use process substitution to feed the pretty-printed JSON objects directly to delta.
# This avoids creating temporary files on disk.
# The first object (index 0) is passed as the first file.
# The second object (index 1) is passed as the second file.
delta --side-by-side --diff-args=-U999 --paging=never \
    (echo "$json_string" | jq '.[0]' | psub) \
    (echo "$json_string" | jq '.[1]' | psub)
