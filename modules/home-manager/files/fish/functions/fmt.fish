if test -e go.mod
    echo "go.mod found. Running Go formatter..."
    go fmt ./...
else if test -e build.gradle
    echo "build.gradle found. Running ./gradlew spotlessApply..."
    ./gradlew spotlessApply --parallel
else
    echo "Neither go.mod nor build.gradle found in the current directory."
end
