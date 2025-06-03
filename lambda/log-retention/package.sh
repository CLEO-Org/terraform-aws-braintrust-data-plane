#!/bin/bash

# Create a temporary directory for packaging
TEMP_DIR=$(mktemp -d)
PACKAGE_DIR="$TEMP_DIR/package"

# Create package directory
mkdir -p "$PACKAGE_DIR"

# Copy the Lambda function
cp lambda_function.py "$PACKAGE_DIR/"

# Install dependencies
python3 -m pip install -r requirements.txt -t "$PACKAGE_DIR/"

# Create the deployment package
cd "$PACKAGE_DIR"
zip -r ../function.zip .

# Move the package to the current directory
cd - > /dev/null
mv "$TEMP_DIR/function.zip" .

# Clean up
rm -rf "$TEMP_DIR"

echo "Package created: function.zip" 