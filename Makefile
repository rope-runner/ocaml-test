build:
	ocamlfind ocamlopt -thread -o bin/server -linkpkg -package lwt.unix server.ml; \
	ocamlfind ocamlopt -thread -o bin/client -linkpkg -package lwt.unix client.ml; \
	sudo rm -Rf *.cmi *.cmx *.o

.PHONY: clean

clean:
	sudo rm -Rf bin/server bin/client