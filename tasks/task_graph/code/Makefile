all: ../output/task_graph.svg

../output:
	mkdir $@

../output/graph.txt: readlinks.sh $(shell find ../../ -name "Makefile") | ../output
	bash readlinks.sh

../output/task_graph.svg: drawgraph.sh ../output/graph.txt
	bash drawgraph.sh ../output/graph.txt -o $@

../output/graph_checkcycles.txt: ../output/graph.txt
	grep -v '{\|}' ../output/graph.txt | awk -F'->' '{if ($$2 < $$1) {print $$2 "," $$1} else {print $$1 "," $$2} }' | sort | uniq -d  > $@
