if aws configure get sso_start_url --profile $AWS_PROFILE >/dev/null 2>&1
    aws sso logout
end
set -e AWS_PROFILE
