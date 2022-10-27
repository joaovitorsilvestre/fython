FROM elixir:1.14.1 as base

ARG DESTINE_PATH="/compiled"
ENV DESTINE_PATH=$DESTINE_PATH
ARG VERSION_TO_USE_AS_BOOTSTRAPER="v0.5.2"

ENV PATH_FYTHON_TO_USE_AS_BOOTSTRAPER="/fython_$VERSION_TO_USE_AS_BOOTSTRAPER"
ENV ELIXIR_BEAMS_PATH="/usr/local/lib/elixir/lib/elixir/ebin/"

# geting older version to use for bootstrap
ENV OUTPUT_ZIP_PATH="/fython_$VERSION_TO_USE_AS_BOOTSTRAPER_compiled.tar.gz"
RUN wget https://github.com/joaovitorsilvestre/fython/releases/download/$VERSION_TO_USE_AS_BOOTSTRAPER/_compiled.tar.gz -O $OUTPUT_ZIP_PATH \
    && mkdir -p $PATH_FYTHON_TO_USE_AS_BOOTSTRAPER \
    && tar -xf $OUTPUT_ZIP_PATH -C $PATH_FYTHON_TO_USE_AS_BOOTSTRAPER

COPY src src
COPY /devtools/compile.sh /compile.sh
RUN chmod a+x /compile.sh

# Execute bootstrap
RUN echo "Bootstraping using Fython $VERSION_TO_USE_AS_BOOTSTRAPER" \
    && ./compile.sh /src $DESTINE_PATH $PATH_FYTHON_TO_USE_AS_BOOTSTRAPER $ELIXIR_BEAMS_PATH

# Remove base used for bootstrap (to ensure that we are not using it anymore)
RUN rm -rf $PATH_FYTHON_TO_USE_AS_BOOTSTRAPER

# Check if it can recompile itself (its a good way to test while we dont have proper testing)
RUN ./compile.sh /src /test_compiled1 $DESTINE_PATH $ELIXIR_BEAMS_PATH
RUN ./compile.sh /src /test_compiled2 /test_compiled1

FROM base as elixir_shell
# TODO elixir shell with fython loaded

FROM base as fython_shell
