# SED colorize rules
# Extended Regular Expressions (ERE) syntax (use flag -E)

s/↵/ /g
s/([¤∅↓]) /\o033[38;5;7m\1\o033[0m /g # gray
s/(✕) /\o033[38;5;196m\1\o033[0m /g   # red
s/(✓) /\o033[38;5;10m\o033[1m\1\o033[0m /g  # green bold
s/(▲) /\o033[38;5;220m\1\o033[0m /g   # yellow
s/(◆) /\o033[38;5;12m\1\o033[0m /g    # blue
s/(●) /\o033[38;5;15m\1\o033[0m /g    # white
s/(○) /\o033[38;5;196m\1\o033[0m /g   # hollow red
s/\b([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(:[0-9]{1,5}|\/[0-9]{1,2})?)\b/\o033[38;5;13m\1\o033[0m/g   # IP: magenta
