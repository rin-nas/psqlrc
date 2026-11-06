# SED escape rules
# Extended Regular Expressions (ERE) syntax (use flag -E)

# https://postgrespro.com/docs/postgresql/18/sql-copy#SQL-COPY-TEXT-FORMAT

s/\x1b\[[0-9;]*[a-zA-Z]//g  # Removes ANSI escape sequences, include colors
s/\\/\x01/g    # Slash to temp symbol
s/\x08/\\b/g   # Backspace (ASCII 8)
s/\x0c/\\f/g   # Form feed (ASCII 12)
s/\x0a/\\n/g   # Newline (ASCII 10)
s/\x0d/\\r/g   # Carriage return (ASCII 13)
s/\x09/\\t/g   # Tab (ASCII 9)
s/\x0b/\\v/g   # Vertical tab (ASCII 11)
s/\x01/\\\\/g  # Temp symbol to double slash
