MIN :=

SCRIPTS := site/js/egg$(MIN).js
SHADERS := src/shaders/egg.vert src/shaders/egg.frag

COFFEE := coffee
MINIFY := google-closure-compiler
RENDER := google-chrome --disable-web-security --user-data-dir=$(PWD)/.chrome


.PHONY: init


all: $(SCRIPTS) site/index.html

site/js/%.js: src/coffee/%.coffee
	@mkdir -p site/js
	@echo "COFFEE $<"
	@$(COFFEE) -o site/js -c $<

site/js/%.min.js: site/js/%.js
	@echo "MINIFY $<"
	@$(MINIFY) --js $< --js_output_file $@
	@rm -f $<

site/index.html: src/pages/index.html $(SHADERS)
	@echo "GENERATE $<"
	@python generate-site.py $(SHADERS)

clean:
	@rm -rf site/index.html $(SCRIPTS)

render:
	$(RENDER) $(PWD)/site/index.html &

init:
	@echo "setting .git/hooks"
	@find .git/hooks -type l -exec rm {} \;
	@find .githooks -type f -exec ln -sf ../../{} .git/hooks/ \;
