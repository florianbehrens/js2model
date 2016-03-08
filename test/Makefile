# If generated_code/generated_srcs.mk doesn't exist, the corresponding target
# below will be run.  This is how we force source file generation before further
# rules processing.
include generated_code/generated_srcs.mk

SOURCES= test.cpp $(GENERATED_SRCS) third_party/json11/json11.cpp
OBJDIR := generated_code/obj
OBJS := $(addprefix $(OBJDIR)/, $(patsubst %.cpp,%.o,$(SOURCES)))

# About `-cxx-isystem assert`: this makes sure `<assert.h>` is found in our
# local `assert` directory rather than the system default.  In our `assert.h` we
# replace the assert macro with code that throws an exception rather than
# calling abort(), and thus we can verify assertion failures in our tests.
CFLAGS= -std=c++14 -stdlib=libc++ -I generated_code -I third_party -I third_party/boost -cxx-isystem assert

test: generated_code/test
	$<

generated_code/test: $(OBJS)
	cc $(CFLAGS) -lm -lc++ -o $@ $(OBJS)

generated_code/generated_srcs.mk: jsonSchema/quickstart.schema.json
	$(CURDIR)/../src/js2model --namespace ft -o generated_code -l cpp $<
	echo "GENERATED_SRCS=`echo generated_code/*.cpp`" > generated_code/generated_srcs.mk

$(OBJDIR)/%.o : %.cpp
	mkdir -p $(dir $@)
	cc $(CFLAGS) -c -o $@ $<

clean:
	rm -rf generated_code

foo:
	echo $(SOURCES) > /dev/null
	echo $(OBJS) > /dev/null

