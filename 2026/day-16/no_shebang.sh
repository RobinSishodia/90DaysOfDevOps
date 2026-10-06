echo "No shebang here. My shell is: $(readlink /proc/$$/exe)"
[[ 1 == 1 ]] && echo "bash-only [[ ]] syntax worked"
