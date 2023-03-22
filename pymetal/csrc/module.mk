PYMETAL_LIB = $(LIBDIR)/libpymetal_csrc.so
PYMETAL_DEFINES = -DGIT_HASH=$(shell git rev-parse HEAD)
PYMETAL_INCLUDES = $(COMMON_INCLUDES) -I$(TT_METAL_HOME)/tt_metal -I$(TT_METAL_HOME)/. $(shell python3-config --includes) -I$(TT_METAL_HOME)/tt_metal/third_party/pybind11/include
PYMETAL_LDFLAGS = -L/usr/lib/x86_64-linux-gnu -L$(TT_METAL_HOME) -ldevice -lcommon -lbuild_kernels_for_riscv -lllrt -ltt_metal -lyaml-cpp -lhlkc_api -lprofiler -lbuild_kernels_for_riscv
PYMETAL_CFLAGS = $(CFLAGS) -Werror -Wno-int-to-pointer-cast

PYMETAL_SRCS = \
	pymetal/csrc/pymetal_bindings.cpp \
	pymetal/csrc/type_caster.cpp \

PYMETAL_OBJS = $(addprefix $(OBJDIR)/, $(PYMETAL_SRCS:.cpp=.o))
PYMETAL_DEPS = $(addprefix $(OBJDIR)/, $(PYMETAL_SRCS:.cpp=.d))

-include $(PYMETAL_DEPS)

pymetal: $(PYMETAL_LIB)

# Link obj files into shared lib
$(PYMETAL_LIB): $(COMMON_LIB) $(PYMETAL_OBJS) $(DEVICE_LIB)
	@mkdir -p $(LIBDIR)
	$(CXX) $(PYMETAL_CFLAGS) $(CXXFLAGS) $(SHARED_LIB_FLAGS) -o $@ $^ $(LDFLAGS) $(PYMETAL_LDFLAGS)

.PHONY: pymetal/csrc/setup_inplace_link
pymetal/csrc/setup_inplace_link: $(PYMETAL_LIB)
	@mkdir -p $(PYTHON_ENV)/lib/python3.8/site-packages/ttlib
	cp $^ $(PYTHON_ENV)/lib/python3.8/site-packages/ttlib/_C.so
	rm -f pymetal/ttlib/_C.so
	ln -s $(PYTHON_ENV)/lib/python3.8/site-packages/ttlib/_C.so pymetal/ttlib

# Compile obj files
$(OBJDIR)/pymetal/csrc/%.o: pymetal/csrc/%.cpp
	@mkdir -p $(@D)
	$(CXX) $(PYMETAL_CFLAGS) $(CXXFLAGS) $(STATIC_LIB_FLAGS) $(PYMETAL_INCLUDES) -c -o $@ $<

pymetal/csrc: $(PYMETAL_LIB)
