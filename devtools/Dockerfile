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
# TODO
# CMD erl -pa $IEX_BEAMS_PATH -noshell -user Elixir.IEx.CLI +iex

FROM base as shell
CMD erl -pa $DESTINE_PATH -s 'Fython.Shell' start -noshell

FROM base as compile_project
ENV PROJET_FOLDER=/project
# TODO só está funcionando quando está dentro da pasta :O arrumar e tomar cuidado
# TODO se não fizer isso, a pasta _compiled fica vázia por algum motivo
CMD cd $PROJET_FOLDER \
    && erl -pa $DESTINE_PATH -noshell -eval "'Fython.Core.Code':compile_project(<<"'"'"$PROJET_FOLDER"'"'">>)." -run init stop

FROM base as tests
COPY tests tests
CMD cd /tests \
    && erl -pa $DESTINE_PATH -noshell -eval "'Fython.Core.Code':compile_project(<<"'"'"/tests"'"'">>)." -run init stop \
    && erl -pa /tests/_compiled -noshell -eval "'Fython.Math':run_tests()." -run init stop
