# SED colorize rules
# Extended Regular Expressions (ERE) syntax (use flag -E)

s/↵/ /g
s/([¤∅↓∞]) /\x1b[38;5;7m\1\x1b[0m /g # gray
s/(✕) /\x1b[38;5;196m\1\x1b[0m /g   # red
s/(✓) /\x1b[38;5;10m\x1b[1m\1\x1b[0m /g  # green bold
s/(▲) /\x1b[38;5;220m\1\x1b[0m /g   # yellow
s/(◆) /\x1b[38;5;12m\1\x1b[0m /g    # blue
s/(●) /\x1b[38;5;15m\1\x1b[0m /g    # white
s/(○) /\x1b[38;5;196m\1\x1b[0m /g   # hollow red
s/\b([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(:[0-9]{1,5}|\/[0-9]{1,2})?)\b/\x1b[38;5;13m\1\x1b[0m/g   # IP: magenta
