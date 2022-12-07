FROM elixir:1.14.1 as base

# Arguments you can modify
ARG FYTHON_PATH="/compiled"
ARG VERSION_TO_USE_AS_BOOTSTRAPER="v0.10.1"

ENV FYTHON_PATH=$FYTHON_PATH
ENV PATH_FYTHON_TO_USE_AS_BOOTSTRAPER="/fython_$VERSION_TO_USE_AS_BOOTSTRAPER"
ENV ELIXIR_BEAMS_PATH="/usr/local/lib/elixir/lib/elixir/ebin/"
ENV IEX_BEAMS_PATH="/usr/local/lib/elixir/lib/iex/ebin/"

# geting older version to use for bootstrap
ENV OUTPUT_ZIP_PATH="/fython_$VERSION_TO_USE_AS_BOOTSTRAPER_compiled.tar.gz"
RUN wget https://github.com/joaovitorsilvestre/fython/releases/download/$VERSION_TO_USE_AS_BOOTSTRAPER/_compiled.tar.gz -O $OUTPUT_ZIP_PATH \
    && mkdir -p $PATH_FYTHON_TO_USE_AS_BOOTSTRAPER \
    && tar -xf $OUTPUT_ZIP_PATH -C $PATH_FYTHON_TO_USE_AS_BOOTSTRAPER

COPY lib/fython lib/fython
COPY /devtools/fython /fython
RUN chmod a+x /fython

# Execute bootstrap
RUN echo "Bootstraping using Fython $VERSION_TO_USE_AS_BOOTSTRAPER" \
  && /fython bootstrap /lib/fython $FYTHON_PATH $PATH_FYTHON_TO_USE_AS_BOOTSTRAPER $ELIXIR_BEAMS_PATH

# Remove base used for bootstrap (to ensure that we are not using it anymore)
RUN rm -rf $PATH_FYTHON_TO_USE_AS_BOOTSTRAPER

FROM base as bootstrap

ENV FIRST_BOOTSTRAP_DESTINE="/bootstrap1"
ENV SECOND_BOOTSTRAP_DESTINE="/bootstrap2"

RUN /fython bootstrap /lib/fython $FIRST_BOOTSTRAP_DESTINE $FYTHON_PATH $ELIXIR_BEAMS_PATH

# Check if it can recompile itself
RUN /fython bootstrap /lib/fython $SECOND_BOOTSTRAP_DESTINE $FIRST_BOOTSTRAP_DESTINE $ELIXIR_BEAMS_PATH

# The final version bootstraped ready for release
ENV FINAL_PATH="/bootstraped"
CMD /fython bootstrap /lib/fython $FINAL_PATH $SECOND_BOOTSTRAP_DESTINE $ELIXIR_BEAMS_PATH

FROM base as shell
ENV ADITIONAL_PATHS=""
ENV SHELL_PATH="/lib/shell"
ENV SHELL_PATH_COMPILED="/lib/shell/_compiled"

COPY lib/shell $SHELL_PATH
RUN /fython exec "Core.Code.compile_project('$SHELL_PATH')" $FYTHON_PATH

CMD /fython exec "Shell.start()" $SHELL_PATH_COMPILED $FYTHON_PATH $ADITIONAL_PATHS

FROM base as compiler
ENV PROJET_FOLDER="/project"
CMD echo "Compiling project: $PROJET_FOLDER" \
    && rm -rf $PROJET_FOLDER/_compiled \
    && /fython exec "Core.Code.compile_project('$PROJET_FOLDER')" $FYTHON_PATH

FROM base as fytest

ENV FOLDER="MUST_BE_GIVEN"

ENV FYTEST_PATH="/lib/fytest"
ENV FYTEST_PATH_COMPILED="/lib/fytest/_compiled"

COPY lib/fytest $FYTEST_PATH
RUN /fython exec "Core.Code.compile_project('$FYTEST_PATH')" $FYTHON_PATH

CMD echo "Compiling $FOLDER" \
    && /fython exec "Core.Code.compile_project('$FOLDER')" $FYTHON_PATH \
    && /fython exec "Fytest.run('$FOLDER')" $FOLDER/_compiled $FYTEST_PATH_COMPILED $FYTHON_PATH

FROM base as fydoc

ENV FOLDER="MUST_BE_GIVEN"
ENV FYDOC_PATH="/lib/fydoc"

# Install python to use for docs
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    apt update && \
    apt install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt install -y python3.9 python3-pip

COPY /lib/fydoc/mkdocs/requirements.txt $FYDOC_PATH/mkdocs/requirements.txt
RUN pip3 install -r $FYDOC_PATH/mkdocs/requirements.txt

COPY /lib/fydoc $FYDOC_PATH
RUN /fython exec "Core.Code.compile_project('$FYDOC_PATH')" $FYTHON_PATH

CMD rm -rf $FOLDER/docs && \
    /fython exec "Fydoc.run('$FOLDER')" $FYDOC_PATH/_compiled $FYTHON_PATH && \
    cp $FYDOC_PATH/mkdocs/docs/extra.css $FOLDER/docs/extra.css && \
    cp $FYDOC_PATH/mkdocs/docs/extra.js $FOLDER/docs/extra.js && \
    cp $FYDOC_PATH/mkdocs/docs/index.md $FOLDER/docs/index.md && \
    cp $FYDOC_PATH/mkdocs/mkdocs.yml $FOLDER/mkdocs.yml && \
    cd $FOLDER && mkdocs build && rm -rf $FOLDER/mkdocs.yml && rm -rf $FOLDER/docs && \
    echo "Documentation generated at $FOLDER/site"