from fython.core.lexer.errors import Error


class UndefinedFunction(Error):
    def __init__(self, pos_start, pos_end, details):
        super().__init__(pos_start, pos_end, 'Undefined function', details)

