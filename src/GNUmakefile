all:	libAFLDriver.a

aflpp_driver.o:	aflpp_driver.c
	$(CC) -I. -I../../include $(CFLAGS) -c aflpp_driver.c -fPIC

libAFLDriver.a:	aflpp_driver.o
	ar ru libAFLDriver.a aflpp_driver.o
	cp -vf libAFLDriver.a ../../

clean:
	rm -f *.o libAFLDriver*.a