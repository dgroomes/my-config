export CLICOLOR=1

export PATH="$PATH:$HOME/.local/bin"

# I don't need Homebrew auto-updates. I don't want the hint noise. Don't send telemetry.
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_ANALYTICS=1

# Add the JetBrains shell scripts directory to your path so you can launch the IDEs or launch the diff tool from the
# commandline. Usually, I do "idea ." to open the current directory in Intellij.
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# Add the Sublime Text launcher command to the PATH so that you can conveniently execute commands like `subl ~/.bashrc`.
export PATH="$PATH:/Applications/Sublime Text.app/Contents/SharedSupport/bin"

# Rust toolchain
export PATH="$PATH:$HOME/.cargo/bin"

# Disable the "Use 'docker scan'" message on every Docker build. For reference, see this GitHub issue discussion: https://github.com/docker/scan-cli-plugin/issues/149#issuecomment-823969364
export DOCKER_SCAN_SUGGEST=false

# Add Go binaries to the PATH.
export PATH="$PATH:$HOME/go/bin"
