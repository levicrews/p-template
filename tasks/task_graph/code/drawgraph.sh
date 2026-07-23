#!/usr/bin/env bash
set -euo pipefail

input_graph="$1"
shift

if [[ "$1" != "-o" ]]; then
	echo "usage: $0 INPUT_GRAPH -o OUTPUT_SVG" >&2
	exit 1
fi

output_svg="$2"

if ! command -v dot >/dev/null 2>&1; then
	echo "error: graphviz 'dot' is not installed or not on PATH" >&2
	exit 1
fi

tmp_dot=$(mktemp)
cleanup() {
	rm -f "$tmp_dot"
}
trap cleanup EXIT

awk '
function emit_node(node, color) {
	printf "  \"%s\" [fillcolor=\"%s\"];\n", node, color
}

/->/ {
	gsub(/"/, "", $0)
	split($0, parts, /[[:space:]]*->[[:space:]]*/)
	upstream = parts[1]
	downstream = parts[2]
	sub(/[[:space:]]*;.*/, "", downstream)

	nodes[upstream] = 1
	nodes[downstream] = 1
	outdegree[upstream]++
	indegree[downstream]++
	edges[++edge_count] = sprintf("  \"%s\" -> \"%s\";", upstream, downstream)
}

END {
	print "digraph G {"
	for (i in nodes) {
		if (!(i in indegree)) {
			emit_node(i, "#fee2e2")
		} else if (!(i in outdegree)) {
			emit_node(i, "#dcfce7")
		} else {
			emit_node(i, "#fef3c7")
		}
	}
	for (i = 1; i <= edge_count; i++) {
		print edges[i]
	}
	print "}"
}
' "$input_graph" > "$tmp_dot"

dot \
	-Grankdir=LR \
	-Glabel="Task pipeline for \"[Project Name]\"" \
	-Glabelloc=t \
	-Glabeljust=r \
	-Gfontname="DejaVu Sans Mono Bold" \
	-Gfontsize=30 \
	-Gpad=0.15 \
	-Gnodesep=0.15 \
	-Granksep=0.35 \
	-Nshape=box \
	-Nstyle="rounded,filled" \
	-Nfillcolor="#f7f7f7" \
	-Ncolor="#666666" \
	-Nfontname="DejaVu Sans Mono" \
	-Nfontsize=10 \
	-Nmargin="0.08,0.04" \
	-Ecolor="#555555" \
	-Earrowsize=0.6 \
	-Tsvg "$tmp_dot" -o "$output_svg"

echo "Wrote $output_svg"
