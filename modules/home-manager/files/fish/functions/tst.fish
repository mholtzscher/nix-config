if test -e go.mod
    echo "go.mod found. Running Go tests..."
    go test ./...
else if test -e build.gradle -o -e build.gradle.kts
    echo "build.gradle found. Running ./gradlew test..."
    ./gradlew test
else
    echo "Neither go.mod nor build.gradle found in the current directory."
end
