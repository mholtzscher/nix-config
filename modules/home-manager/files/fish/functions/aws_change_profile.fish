set -l profile

if test -z $argv[1]
    if command -v fzf >/dev/null 2>&1
        set profile (aws configure list-profiles | fzf)
        and set -gx AWS_PROFILE "$profile"
    else
        echo "fzf is not installed. Please install fzf to use this feature."
        return 1
    end
else
    set profile $argv[1]
end

if test -z "$profile"
    echo "No profile selected"
    return 1
end

set -gx AWS_PROFILE "$profile"
echo -e "Using AWS profile: $AWS_PROFILE"

if aws configure get sso_start_url --profile $AWS_PROFILE >/dev/null 2>&1
    if aws sts get-caller-identity >/dev/null 2>&1
        echo "Found valid AWS session"
    else
        echo "Logging into AWS"
        aws sso login
    end
end
