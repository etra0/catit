all: main

run: main
	./$<

main: src/main.nim
	nim c --mm:orc -o:$@ $<

clean:
	rm -rf main

.PHONY: all run clean
