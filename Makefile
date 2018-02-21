URN_PATH ?= "../../../gitlab.com/urn/urn"
URN_FLAGS = -O2

all: main.lua

run: all
	love .

main.lua: main.lisp scheme.lisp ansi.lisp term.lisp pp.glsl
	$(URN_PATH)/bin/urn.lua $(URN_FLAGS) -o $@ $<

scheme.lisp: scheme.json scheme-to-lisp.py
	python3 scheme-to-lisp.py > $@

out.txt: $(SOURCE_FILE)
	highlight -O pango -s $(SOURCE_THEME) -l > $@ $<

dist: game.zip

run-dist: game.zip
	love $<

game.zip: main.lua pp.glsl Glass_TTY_VT220.ttf
	zip $@ $^

clean:
	rm -f main.lua game.zip

.PHONY: all run clean dist run-dist

