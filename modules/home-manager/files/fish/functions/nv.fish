set -l config_dir "$HOME/.config"
set -l configs (find "$config_dir" -maxdepth 1 -name "nvim*" -type d | sed "s|$config_dir/||" | sort)

if test (count $configs) -eq 0
    echo "No Neovim configurations found in $config_dir"
    return 1
end

set -l selected_config (printf '%s\n' $configs | fzf --prompt="Select Neovim config: " --height=40% --border)

if test -n "$selected_config"
    env NVIM_APPNAME="$selected_config" nvim $argv
end