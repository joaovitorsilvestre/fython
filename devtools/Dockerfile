FROM elixir:1.14.1 as base

# Arguments you can modify
ARG DESTINE_PATH="/compiled"
ARG VERSION_TO_USE_AS_BOOTSTRAPER="v0.5.2"

ENV DESTINE_PATH=$DESTINE_PATH
ENV PATH_FYTHON_TO_USE_AS_BOOTSTRAPER="/fython_$VERSION_TO_USE_AS_BOOTSTRAPER"
ENV ELIXIR_BEAMS_PATH="/usr/local/lib/elixir/lib/elixir/ebin/"
ENV IEX_BEAMS_PATH="/usr/local/lib/elixir/lib/iex/ebin/"

# geting older version to use for bootstrap
ENV OUTPUT_ZIP_PATH="/fython_$VERSION_TO_USE_AS_BOOTSTRAPER_compiled.tar.gz"
RUN wget https://github.com/joaovitorsilvestre/fython/releases/download/$VERSION_TO_USE_AS_BOOTSTRAPER/_compiled.tar.gz -O $OUTPUT_ZIP_PATH \
    && mkdir -p $PATH_FYTHON_TO_USE_AS_BOOTSTRAPER \
    && tar -xf $OUTPUT_ZIP_PATH -C $PATH_FYTHON_TO_USE_AS_BOOTSTRAPER

COPY src src
COPY /devtools/bootstrap.sh /bootstrap.sh
COPY /devtools/fython /fython
RUN chmod a+x /bootstrap.sh
RUN chmod a+x /fython

# Execute bootstrap
RUN echo "Bootstraping using Fython $VERSION_TO_USE_AS_BOOTSTRAPER" \
    && ./bootstrap.sh compile /src $DESTINE_PATH $PATH_FYTHON_TO_USE_AS_BOOTSTRAPER $ELIXIR_BEAMS_PATH

# Remove base used for bootstrap (to ensure that we are not using it anymore)
RUN rm -rf $PATH_FYTHON_TO_USE_AS_BOOTSTRAPER

# Check if it can recompile itself (its a good way to test while we dont have proper testing)
#RUN ./bootstrap.sh compile /src /test_compiled1 $DESTINE_PATH $ELIXIR_BEAMS_PATH
#RUN ./bootstrap.sh compile /src /test_compiled2 /test_compiled1

FROM base as elixir_shell
# TODO
# CMD erl -pa $IEX_BEAMS_PATH -noshell -user Elixir.IEx.CLI +iex

FROM base as shell
CMD /fython exec "Shell.start()" $DESTINE_PATH

FROM base as compiler
ENV PROJET_FOLDER="/project"
CMD echo "Compiling project: $PROJET_FOLDER" \
    && /fython exec "Core.Code.compile_project('$PROJET_FOLDER')" $DESTINE_PATH

FROM base as tests
COPY tests tests

CMD /fython exec "Core.Code.compile_project('/tests')" $DESTINE_PATH \
    && /fython exec "Math_tests.run_tests()" $DESTINE_PATH /tests/_compiled
