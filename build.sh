#!/usr/bin/env bash
#
# GitMsgAI Build Script
# Builds native executables, runs checks/tests, and supports optional installation.
#

set -e

# ANSI Color codes
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RED="\033[31m"
DIM="\033[2m"
RESET="\033[0m"

APP_NAME="gitmsgai"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
ENTRY_POINT="bin/gitmsgai.dart"

INSTALL=false
FAST=false
LINUX_CROSS=false
CLEAN=false

# Print help message
show_help() {
  echo -e "${BOLD}Usage:${RESET} ./build.sh [options]"
  echo ""
  echo -e "${BOLD}Options:${RESET}"
  echo -e "  -h, --help       Show this help message"
  echo -e "  -i, --install    Install the compiled executable to ~/.local/bin or /usr/local/bin"
  echo -e "  -f, --fast       Fast build: skip format check, analyze, and tests"
  echo -e "  -l, --linux      Also cross-compile for Linux (x64 & arm64)"
  echo -e "  -c, --clean      Clean previous build artifacts before building"
}

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -i|--install)
      INSTALL=true
      shift
      ;;
    -f|--fast)
      FAST=true
      shift
      ;;
    -l|--linux)
      LINUX_CROSS=true
      shift
      ;;
    -c|--clean)
      CLEAN=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${RESET}"
      show_help
      exit 1
      ;;
  esac
done

cd "$ROOT_DIR"

echo -e "${BOLD}${CYAN}=== Building $APP_NAME ===${RESET}"

# Step 0: Clean if requested
if [ "$CLEAN" = true ]; then
  echo -e "\n${YELLOW}🧹 Cleaning build directory...${RESET}"
  rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"

# Step 1: Check Dart SDK
if ! command -v dart &> /dev/null; then
  echo -e "${RED}✖ Dart SDK not found in PATH. Please install Dart before building.${RESET}"
  exit 1
fi
echo -e "${DIM}Dart version: $(dart --version)${RESET}"

# Step 2: Quality checks (unless --fast is specified)
if [ "$FAST" = false ]; then
  echo -e "\n${CYAN}1/4 Checking dependencies...${RESET}"
  dart pub get

  echo -e "\n${CYAN}2/4 Checking code formatting...${RESET}"
  if ! dart format . --set-exit-if-changed; then
    echo -e "${RED}✖ Code formatting issues found. Run 'dart format .' to fix.${RESET}"
    exit 1
  fi
  echo -e "${GREEN}✓ Code formatting passed${RESET}"

  echo -e "\n${CYAN}3/4 Running static analysis...${RESET}"
  dart analyze --fatal-infos
  echo -e "${GREEN}✓ Static analysis passed${RESET}"

  echo -e "\n${CYAN}4/4 Running test suite...${RESET}"
  dart test
  echo -e "${GREEN}✓ All tests passed${RESET}"
else
  echo -e "\n${YELLOW}⚡ Fast mode enabled: skipping format, analyze, and tests.${RESET}"
fi

# Step 3: Compile for Host OS
HOST_TARGET="$BUILD_DIR/$APP_NAME"
echo -e "\n${CYAN}🔨 Compiling native executable for current host...${RESET}"
dart compile exe "$ENTRY_POINT" -o "$HOST_TARGET"
chmod +x "$HOST_TARGET"

# Display size
FILE_SIZE=$(ls -lh "$HOST_TARGET" | awk '{print $5}')
echo -e "${GREEN}✓ Host binary generated:${RESET} ${BOLD}$HOST_TARGET${RESET} ($FILE_SIZE)"

# Step 4: Cross-compile for Linux if requested
if [ "$LINUX_CROSS" = true ]; then
  echo -e "\n${CYAN}🌐 Cross-compiling for Linux...${RESET}"
  
  LINUX_X64="$BUILD_DIR/${APP_NAME}-linux-x64"
  echo -e "  Compiling Linux x64: $LINUX_X64"
  dart compile exe --target-os=linux --target-arch=x64 "$ENTRY_POINT" -o "$LINUX_X64"
  chmod +x "$LINUX_X64"

  LINUX_ARM64="$BUILD_DIR/${APP_NAME}-linux-arm64"
  echo -e "  Compiling Linux arm64: $LINUX_ARM64"
  dart compile exe --target-os=linux --target-arch=arm64 "$ENTRY_POINT" -o "$LINUX_ARM64"
  chmod +x "$LINUX_ARM64"

  echo -e "${GREEN}✓ Linux cross-compilation complete!${RESET}"
fi

# Step 5: Install if requested
if [ "$INSTALL" = true ]; then
  echo -e "\n${CYAN}📦 Installing $APP_NAME...${RESET}"
  
  INSTALL_DIR=""
  if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    INSTALL_DIR="$HOME/.local/bin"
  elif [ -w "/usr/local/bin" ]; then
    INSTALL_DIR="/usr/local/bin"
  else
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
  fi

  cp "$HOST_TARGET" "$INSTALL_DIR/$APP_NAME"
  chmod +x "$INSTALL_DIR/$APP_NAME"
  echo -e "${GREEN}✓ Installed successfully to:${RESET} ${BOLD}$INSTALL_DIR/$APP_NAME${RESET}"

  if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "${YELLOW}⚠ Note: $INSTALL_DIR is not in your PATH. Add it to your shell profile:${RESET}"
    echo -e "  export PATH=\"\$PATH:$INSTALL_DIR\""
  fi
fi

echo -e "\n${BOLD}${GREEN}🎉 Build completed successfully!${RESET}"
echo -e "Run ${BOLD}./build/$APP_NAME --help${RESET} to test the binary.\n"
