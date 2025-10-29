set -l KEY_FILE_PATH $argv[1]
set -l LOCAL_PORT $argv[2]
set -l ENDPOINT $argv[3]
set -l USER_HOSTNAME $argv[4]

ssh -i $KEY_FILE_PATH -v -N -L $LOCAL_PORT:$ENDPOINT $USER_HOSTNAME
