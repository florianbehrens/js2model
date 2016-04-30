# If generated_code/generated_srcs.mk doesn't exist, the corresponding target
# below will be run.  This is how we force source file generation before further
# rules processing.
include generated_code/generated_srcs.mk

SOURCES= $(wildcard *.cpp) $(GENERATED_SRCS) third_party/json11/json11.cpp
OBJDIR := generated_code/obj
OBJS := $(addprefix $(OBJDIR)/, $(patsubst %.cpp,%.o,$(SOURCES)))
INPUT_SCHEMAS = $(wildcard jsonSchema/*.schema.json)
CC ?= cc
CXX ?= c++
LIBCXX ?= c++

CFLAGS= -std=c++14 -I generated_code -I third_party \
	-I third_party/boost/include \
	-I .

test: generated_code/test
	$<

generated_code/test: $(OBJS)
	$(CXX) -lm -l$(LIBCXX) -o $@ $(OBJS)

generated_code/generated_srcs.mk: $(INPUT_SCHEMAS) ../src/tr/jsonschema/jsonschema2model.py ../src/tr/jsonschema/templates_cpp/*.mako
	$(CURDIR)/../src/js2model --namespace ft::js2model::test -o generated_code -l cpp \
	    --assert-macro test_assert --include assert/test_assert.h \
	    $(INPUT_SCHEMAS)
	echo "GENERATED_SRCS=`echo generated_code/*.cpp`" > generated_code/generated_srcs.mk

$(OBJDIR)/%.o : %.cpp
	mkdir -p $(dir $@)
	$(CXX) $(CFLAGS) -c -o $@ $<

clean:
	rm -rf generated_code

