.PHONY: all
all: dmt

DMD ?= dmd
DMDFLAGS = -release -inline -O
#DMDFLAGS = -cov -unittest -release -inline -O

dmt: dmt.d
	$(DMD) $(DMDFLAGS) dmt.d
	strip ./dmt

.PHONY: test
test: dmt test1.dt test2.dt test3.dt
	./dmt test1.dt
	./dmt test2.dt
	./dmt test3.dt

.PHONY: clean
clean:
	rm -f ./dmt dmt.o
	rm -f test1 test2 test3
	rm -f test1.o test2.o test3.o
