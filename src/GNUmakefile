ifeq "" "$(LLVM_CONFIG)"
  LLVM_CONFIG=llvm-config
endif

LLVM_BINDIR = $(shell $(LLVM_CONFIG) --bindir 2>/dev/null)
ifneq "" "$(LLVM_BINDIR)"
  LLVM_BINDIR := $(LLVM_BINDIR)/
endif

CFLAGS := -O3 -funroll-loops -g -fPIC

all:	libAFLDriver.a

aflpp_driver.o:	aflpp_driver.c
	-$(LLVM_BINDIR)clang -I. -I../../include $(CFLAGS) -c aflpp_driver.c

libAFLDriver.a:	aflpp_driver.o
	ar ru libAFLDriver.a aflpp_driver.o
	cp -vf libAFLDriver.a ../../

clean:
	rm -f *.o libAFLDriver*.a