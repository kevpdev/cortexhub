#!/usr/bin/env bash
# common.sh — shared helpers for ai-core scripts. Source, do not execute.

# Resolve memory-bank directory for the current project.
# Prints the path if found, empty string if not.
find_memory_dir() {
  if [ -d ".ai-local/memory-bank" ]; then
    echo ".ai-local/memory-bank"
  elif [ -d ".claude/memory-bank" ]; then
    echo ".claude/memory-bank"
  else
    echo ""
  fi
}

# Resolve captures directory. Returns empty string if no memory-bank exists.
find_captures_dir() {
  local mem
  mem=$(find_memory_dir)
  if [ -n "$mem" ]; then
    echo "$mem/captures"
  else
    echo ""
  fi
}
