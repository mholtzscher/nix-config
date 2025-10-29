function update --description "Update all the things"
    _neovim_plugins
    _asdf_plugins
    _go_tools

    gum log --time kitchen --level info Finished
end

function _neovim_plugins
    gum log --time kitchen --level info "Updating neovim plugins"
    nvim --headless "+Lazy! sync" +qa
end

function _asdf_plugins
    gum log --time kitchen --level info "Installing asdf plugins"

    gum log --time kitchen --level info "Installing asdf plugin: java"
    asdf plugin add java
    gum log --time kitchen --level info "Installing latest java"
    asdf install java latest
    gum log --time kitchen --level info "Setting global java to latest"
    asdf global java latest

    gum log --time kitchen --level info "Installing asdf plugin: nodejs"
    asdf plugin add nodejs
    gum log --time kitchen --level info "Installing latest nodejs"
    asdf install nodejs latest
    gum log --time kitchen --level info "Setting global nodejs to latest"
    asdf global nodejs latest

    gum log --time kitchen --level info "Installing asdf plugin: python"
    asdf plugin add python
    gum log --time kitchen --level info "Installing latest python"
    asdf install python latest
    gum log --time kitchen --level info "Setting global python to latest"
    asdf global python latest

    gum log --time kitchen --level info "Installing asdf plugin: terraform"
    asdf plugin add terraform
    gum log --time kitchen --level info "Installing latest terraform"
    asdf install terraform latest
    gum log --time kitchen --level info "Setting global terraform to latest"
    asdf global terraform latest

    gum log --time kitchen --level info "Installing asdf plugin: rust"
    asdf plugin add rust
    gum log --time kitchen --level info "Installing latest rust"
    asdf install rust latest
    gum log --time kitchen --level info "Setting global rust to latest"
    asdf global rust latest

    gum log --time kitchen --level info "Installing asdf plugin: lua"
    asdf plugin add lua
    gum log --time kitchen --level info "Installing latest lua"
    asdf install lua latest
    gum log --time kitchen --level info "Setting global lua to latest"
    asdf global lua latest

    gum log --time kitchen --level info "Updating asdf plugins"
    asdf plugin update --all
end

function _go_tools
    gum log --time kitchen --level info "Installing go tools"

    gum log --time kitchen --level info "Installing protoc-gen-gotag"
    go install github.com/srikrsna/protoc-gen-gotag@latest

    gum log --time kitchen --level info "Installing godotenv"
    go install github.com/joho/godotenv/cmd/godotenv@latest

    gum log --time kitchen --level info "Installing govulncheck"
    go install golang.org/x/vuln/cmd/govulncheck@latest

    gum log --time kitchen --level info "Installing protoc-gen-go"
    go install google.golang.org/protobuf/cmd/protoc-gen-go@latest

    gum log --time kitchen --level info "Installing protoc-gen-connect-go"
    go install connectrpc.com/connect/cmd/protoc-gen-connect-go@latest

    gum log --time kitchen --level info "Installing mockery"
    go install github.com/vektra/mockery/v2@latest

    gum log --time kitchen --level info "Installing goose"
    go install github.com/pressly/goose/v3/cmd/goose@latest

    gum log --time kitchen --level info "Installing sqlc"
    go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest

    gum log --time kitchen --level info "Installing air"
    go install github.com/air-verse/air@latest

    gum log --time kitchen --level info "Installing cobra-cli"
    go install github.com/spf13/cobra-cli@latest
end
