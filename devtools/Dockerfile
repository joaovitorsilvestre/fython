FROM elixir:1.14.1 as base

# Arguments you can modify
ARG DESTINE_PATH="/compiled"
ARG VERSION_TO_USE_AS_BOOTSTRAPER="v0.7.0"

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

FROM base as bootstrap
ENV FIRST_PATH="/test_compiled1"
ENV SECOND_PATH="/test_compiled2"

# Check if it can recompile itself (its a good way to test while we dont have proper testing)
RUN ./bootstrap.sh compile /src $FIRST_PATH $DESTINE_PATH $ELIXIR_BEAMS_PATH
RUN ./bootstrap.sh compile /src $SECOND_PATH $FIRST_PATH $ELIXIR_BEAMS_PATH

# The final version bootstraped ready for release
ENV FINAL_PATH="/bootstraped"
CMD ./bootstrap.sh compile /src $FINAL_PATH $SECOND_PATH $ELIXIR_BEAMS_PATH

FROM base as shell
ENV ADITIONAL_PATHS=""
ENV SHELL_PATH="/libs/shell"
ENV SHELL_PATH_COMPILED="/libs/shell/_compiled"

COPY libs/shell $SHELL_PATH
RUN /fython exec "Core.Code.compile_project('$SHELL_PATH')" $DESTINE_PATH

CMD /fython exec "Shell.start()" $SHELL_PATH_COMPILED $DESTINE_PATH $ADITIONAL_PATHS

FROM base as compiler
ENV PROJET_FOLDER="/project"
CMD echo "Compiling project: $PROJET_FOLDER" \
    && rm -rf $PROJET_FOLDER/_compiled \
    && /fython exec "Core.Code.compile_project('$PROJET_FOLDER')" $DESTINE_PATH

FROM base as fytest

ENV FOLDER="MUST_BE_GIVEN"

ENV FYTEST_PATH="/libs/fytest"
ENV FYTEST_PATH_COMPILED="/libs/fytest/_compiled"

COPY libs/fytest $FYTEST_PATH
RUN /fython exec "Core.Code.compile_project('$FYTEST_PATH')" $DESTINE_PATH

CMD echo "Compiling $FOLDER" \
    && /fython exec "Core.Code.compile_project('$FOLDER')" $DESTINE_PATH \
    && /fython exec "Fytest.run('$FOLDER')" $FOLDER/_compiled $FYTEST_PATH_COMPILED $DESTINE_PATH
