# Filter for the build output read by VS Code (.vscode/tasks.json).
#
# sdasz80 and sdcc report "file:line: Error: message" with no column, so VS Code underlines
# only the first character. This adds the columns of the code on that line (first non-blank
# character up to the comment): "file:line:start:end: Error: message". Other lines pass as is.

match($0, /^[^:]+:[0-9]+: +([Ee]rror|[Ww]arning)/) {
	split($0, f, ":")
	file = f[1]
	line = f[2] + 0

	text = ""
	n = 0
	while ((getline l < file) > 0)
		if (++n == line) {
			text = l
			break
		}
	close(file)

	sub(/;.*/, "", text)		# no assembler error points into a comment
	sub(/[ \t]+$/, "", text)
	start = match(text, /[^ \t]/)	# columns count characters: a tab is one
	if (!start)
		start = 1
	end = length(text) + 1

	printf "%s:%d:%d:%d:%s\n", file, line, start, end, substr($0, length(f[1]) + length(f[2]) + 3)
	next
}
{ print }
