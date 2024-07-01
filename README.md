# Ocaml test project

## Structure
Consists of:

* `server.ml` - responsible for creating tcp server, spawning connections, respawning child processes, logging to the log.txt file
* `client.ml` - responsible for connecting to the tcp server, scheduling alive messages, scheduling self-destruction
* `Makefile` - primitive build and clean script

## Running
* Make sure you have needed dependecies ocaml, make, lwt, etc
* In root directory run `make`
* If you dont want to use make run `ocamlfind ocamlopt -thread -o bin/server -linkpkg -package lwt.unix server.ml`
* And then `ocamlfind ocamlopt -thread -o bin/client -linkpkg -package lwt.unix client.ml`
* And finally `./bin/server <number of desired processes>`
* Enjoy !

## Changing
If you will visit `server.ml` you can change the port for tcp server, or logggin format. In the `client.ml` you can change the lifetime for child process and also interval boundaries for alive messages, and port for connection.