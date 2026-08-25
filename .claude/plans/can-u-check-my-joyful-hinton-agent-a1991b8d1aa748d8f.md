# Plan for searching large files and build artifacts

## Objective
Identify files >5MB, build artifacts that shouldn't be in version control, and directories indicating poor git hygiene.

## Steps
1. Find files larger than 5MB excluding .git directory.
2. Search for common build artifact extensions (.exe, .dll, .so, .class, etc.)
3. Look for specific directories: node_modules, Pods, .dart_tool, .flutter-plugins, build directories.
4. Check for unusually large lock files or other binary files.
5. Report findings with file paths and sizes.

## Tools to use
- Bash find for size and extension searches
- Glob and Grep for pattern matching
- Read for examining specific files if needed

## Output
List of problematic files and directories with recommendations for .gitignore updates.


