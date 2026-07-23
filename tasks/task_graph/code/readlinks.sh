#!/bin/bash
# Script to generate graph of task dependencies from task Makefiles.

set -euo pipefail

graph_file="../output/graph.txt"
missing_file="../output/missing.txt"

tmp_edges=$(mktemp)
tmp_missing=$(mktemp)

cleanup() {
	rm -f "$tmp_edges" "$tmp_missing"
}
trap cleanup EXIT

find ../../ -path '*/code/Makefile' -print |
sort |
xargs awk -v edges_file="$tmp_edges" -v missing_file="$tmp_missing" '
function task_name(path, parts, n) {
	n = split(path, parts, "/")
	return (n >= 2) ? parts[n - 2] : ""
}

function add_edge(upstream, downstream) {
	if (upstream == "" || downstream == "" || upstream == downstream) {
		return
	}
	print "\"" upstream "\" -> \"" downstream "\"" >> edges_file
}

function add_missing(line) {
	print FILENAME ":" FNR ":" line >> missing_file
}

function scan_token(token, downstream) {
	if (token ~ /\.\.\/\.\.\/\[[^]]+\]\/output\//) {
		add_missing($0)
		return
	}

	if (token ~ /\.\.\/\.\.\/[^\/]+\/output\//) {
		split(token, parts, "/")
		add_edge(parts[3], downstream)
		return
	}

	if (token ~ /\.\.\/\.\.\/initialdata\/hand\//) {
		add_edge("initialdata", downstream)
		return
	}

	if (token ~ /\.\.\/\.\.\/functions_model\//) {
		add_edge("functions_model", downstream)
		return
	}

	if (token ~ /\.\.\/\.\.\/functions_data\//) {
		add_edge("functions_data", downstream)
		return
	}

	if (token ~ /\.\.\/\.\.\/functions_map\//) {
		add_edge("functions_map", downstream)
		return
	}
}

BEGIN {
	FS = "[[:space:]]+"
}

{
	sub(/\r$/, "", $0)
}

/^[[:space:]]*#/ {
	next
}

{
	downstream = task_name(FILENAME)

	if ($0 ~ /^\.\.\/input\/[^:]*:/) {
		split($0, halves, ":")
		if (length(halves) < 2) {
			next
		}

		rhs = halves[2]
		sub(/[[:space:]]*\|.*/, "", rhs)
		n = split(rhs, tokens, /[[:space:]]+/)
		for (i = 1; i <= n; i++) {
			if (tokens[i] != "") {
				scan_token(tokens[i], downstream)
			}
		}
		next
	}

	if ($0 !~ /:/ && ($0 ~ /\.\.\/\.\.\/functions_model\// || $0 ~ /\.\.\/\.\.\/functions_data\// || $0 ~ /\.\.\/\.\.\/functions_map\//)) {
		for (i = 1; i <= NF; i++) {
			scan_token($i, downstream)
		}
		next
	}

	if ($0 ~ /:/ && ($0 ~ /\.\.\/\.\.\/functions_model\// || $0 ~ /\.\.\/\.\.\/functions_data\// || $0 ~ /\.\.\/\.\.\/functions_map\//)) {
		split($0, halves, ":")
		if (length(halves) >= 2) {
			rhs = halves[2]
			sub(/[[:space:]]*\|.*/, "", rhs)
			n = split(rhs, tokens, /[[:space:]]+/)
			for (i = 1; i <= n; i++) {
				if (tokens[i] != "") {
					scan_token(tokens[i], downstream)
				}
			}
		}
	}
}
'

{
	echo "digraph G {"
	sort -u "$tmp_edges"
	echo "}"
} > "$graph_file"

sort -u "$tmp_missing" > "$missing_file"
