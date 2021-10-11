vendor/flecs.o: vendor/flecs.c
	cc -o $@ -c $^

vendor/libflecs.a: vendor/flecs.o
	ar -rc $@ $^

.PHONY: spec
spec: vendor/libflecs.a
	crystal spec --error-trace

.PHONY: spec-lldb
spec-lldb: vendor/libflecs.a
	crystal build spec/spec_main.cr -o /tmp/crystal-flecs-spec
	lldb -o run -- /tmp/crystal-flecs-spec
