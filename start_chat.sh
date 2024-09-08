#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a Python package is installed
package_installed() {
    pip show "$1" > /dev/null 2>&1
}

# Check and install system dependencies
for cmd in python3 pip; do
    if ! command_exists $cmd; then
        echo "Error: $cmd is not installed. Please install $cmd and try again."
        exit 1
    fi
done

# Install Ollama if necessary
if ! command_exists ollama; then
    echo "Ollama is not installed. Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install Ollama. Please check your internet connection and try again."
        exit 1
    fi
    echo "Ollama installed successfully."
else
    echo "Ollama is already installed."
fi

# Create and activate virtual environment
if [ ! -d "env" ]; then
    python3 -m venv env
fi
source env/bin/activate

# Install required Python packages
for package in gradio ollama langchain_community; do
    if ! package_installed $package; then
        echo "Installing $package..."
        pip install $package
    else
        echo "$package library is already installed."
    fi
done

# Start Ollama server if not running
if ! pgrep -x "ollama" > /dev/null; then
    echo "Starting Ollama server..."
    nohup ollama serve > /dev/null 2>&1 &
    sleep 5  # Give some time for the server to start
else
    echo "Ollama server is already running."
fi

# Pull the Gemma 2B model if not already present
if ! ollama list | grep -q "gemma2:2b"; then
    echo "Pulling Gemma 2B model..."
    ollama pull gemma2:2b
    if [ $? -ne 0 ]; then
        echo "Error: Failed to pull Gemma 2B model. Please check your internet connection and try again."
        exit 1
    fi
    echo "Gemma 2B model pulled successfully."
else
    echo "Gemma 2B model is already present."
fi

# Function to start all components
start_components() {

    # Start Gemma 2B model if not running
    if ! ollama list | grep -q "gemma2:2b (running)"; then
        echo "Starting Gemma 2B model..."
        ollama run gemma2:2b &
        sleep 10  # Wait for the model to initialize
    else
        echo "Gemma 2B model is already running."
    fi

    # Start Gradio chatbot if not running
    if ! pgrep -f "gradio_ollama_chat.py" > /dev/null; then
        echo "Starting Gradio chatbot..."
        python gradio_ollama_chat.py &
    else
        echo -e "Gradio chatbot is already running.\nConnect your browser to http://127.0.0.1:7860"
    fi
}

# Start all components
start_components

echo "Installation and startup complete. All necessary components are now running."

# Keep the script running to maintain the background processes
echo "Press Ctrl+C to stop all processes and exit."
wait
