.PHONY: all
all: dmt

DMD ?= dmd
DMDFLAGS ?= -release -inline -O
#DMDFLAGS = -cov -unittest -release -inline -O

dmt: dmt.d
	$(DMD) $(DMDFLAGS) dmt.d

.PHONY: test tests run_tests
test: dmt tests
	./test1

ALL_TESTS_SOURCES := $(wildcard test*.dt)
#ALL_TESTS := $(ALL_TESTS_SOURCES:.dt=)
ALL_TESTS := $(ALL_TESTS_SOURCES:%.dt=run_%)

run_tests: dmt $(ALL_TESTS)
	:

%: dmt %.dt
	./dmt $<

run_%: %.dt dmt
	./dmt -run $<

.PHONY: clean
clean:
	rm -v -f dmt dmt.o a.out
	rm -v -f test*.o test*.d
