FROM elixir:1.14.1

ARG VERSION_TO_USE_AS_BOOTSTRAPER="v0.5.2"
ARG DESTINE_PATH="/compiled"
ENV DESTINE_PATH=$DESTINE_PATH
ENV ELIXIR_BEAMS_PATH="/usr/local/lib/elixir/lib/elixir/ebin/"

RUN mkdir $DESTINE_PATH

# geting older version to use for bootstrap
ENV OUTPUT_ZIP_PATH="/fython_$VERSION_TO_USE_AS_BOOTSTRAPER_compiled.tar.gz"
ENV COMPILED_OUTPUT_PATH="/fython_$VERSION_TO_USE_AS_BOOTSTRAPER"
RUN wget https://github.com/joaovitorsilvestre/fython/releases/download/$VERSION_TO_USE_AS_BOOTSTRAPER/_compiled.tar.gz -O $OUTPUT_ZIP_PATH \
    && mkdir -p $COMPILED_OUTPUT_PATH \
    && tar -xf $OUTPUT_ZIP_PATH -C $COMPILED_OUTPUT_PATH

COPY src src
COPY functions.sh /functions.sh

# Execute bootstrap
RUN ALL_FILES_PATH=$(find /src -name '*.fy') \
    && echo "Bootstraping using Fython $VERSION_TO_USE_AS_BOOTSTRAPER" \
    && echo "Destine folder: DESTINE_PATH" \
    && cp -r $ELIXIR_BEAMS_PATH/* $DESTINE_PATH \
    && SRC_DIR=/src \
    && for FILE_PATH in $ALL_FILES_PATH; do  \
      ERL_COMMAND_CALL="application:start(compiler), application:start(elixir), 'Elixir.Code':compiler_options(#{ignore_module_conflict => true}), 'Fython.Core.Code':compile_project_file(<<"'"'$SRC_DIR'"'">>, <<"'"'${FILE_PATH}'"'">>, "'"'$DESTINE_PATH'"'"), init:stop()."; \
      erl -pa $COMPILED_OUTPUT_PATH  -noshell -eval "$ERL_COMMAND_CALL"; \
    done
