vendor/flecs.o: vendor/flecs.c
	cc -o $@ -c $^

vendor/libflecs.a: vendor/flecs.o
	ar -rc $@ $^

.PHONY: spec
spec: vendor/libflecs.a
	crystal spec
