from fython.core.lexer.consts import LETTERS_DIGITS, LETTERS, DIGISTS
from fython.core.lexer.tokens import *
from fython.core.lexer.position import Position
from fython.core.lexer.errors import InvalidSyntaxError, IllegalCharError, ExpectedCharError


class Lexer:
    def __init__(self, fn, text):
        self.text = text
        self.pos = Position(-1, 0, -1, fn, text)
        self.current_char = None
        self.advance()
        self.current_ident_level = 0

    def advance(self):
        self.pos.advance(self.current_char)
        self.current_char = self.text[self.pos.idx] if self.pos.idx < len(self.text) else None

    def make_tokens(self):
        tokens = []

        while self.current_char != None:
            if self.current_char == ' ' and self.pos.col == 0:
                error = self.make_ident()
                if error:
                    return [], error
            elif self.current_char in ';\n':
                self.current_ident_level = max(0, self.current_ident_level - 4)
                tokens.append(Token(TT_NEWLINE, self.current_ident_level, pos_start=self.pos))
                self.advance()
            elif self.current_char in ' \t':
                self.advance()
            elif self.current_char == ':':
                tok, error = self.make_do_or_atom()
                if error:
                    return [], error
                tokens.append(tok)
            elif self.current_char == '#':
                self.skip_comment()
            elif self.current_char in DIGISTS:
                tokens.append(self.make_number())
            elif self.current_char in LETTERS:
                tokens.append(self.make_identifier())
            elif self.current_char in ["'", '"']:
                tokens.append(self.make_string())
            elif self.current_char == '+':
                tokens.append(Token(TT_PLUS, self.current_ident_level, pos_start=self.pos))
                self.advance()
            elif self.current_char == '-':
                tokens.append(Token(TT_MINUS, self.current_ident_level, pos_start=self.pos))
                self.advance()
            elif self.current_char == '*':
                tokens.append(self.make_mul_or_power())
            elif self.current_char == '/':
                tokens.append(Token(TT_DIV, self.current_ident_level, pos_start=self.pos))
                self.advance()
            elif self.current_char == '(':
                tokens.append(Token(TT_LPAREN, self.current_ident_level, pos_start=self.pos))
                self.advance()
            elif self.current_char == ')':
                tokens.append(Token(TT_RPAREN, self.current_ident_level, pos_start=self.pos))
                self.advance()
            elif self.current_char == '[':
                tokens.append(Token(TT_LSQUARE, self.current_ident_level, pos_start=self.pos))
                self.advance()
            elif self.current_char == ']':
                tokens.append(Token(TT_RSQUARE, self.current_ident_level, pos_start=self.pos))
                self.advance()
            elif self.current_char == '{':
                tokens.append(Token(TT_LCURLY, self.current_ident_level, pos_start=self.pos))
                self.advance()
            elif self.current_char == '}':
                tokens.append(Token(TT_RCURLY, self.current_ident_level, pos_start=self.pos))
                self.advance()
            elif self.current_char == '!':
                tok, error = self.make_not_equals()
                if error:
                    return [], error
                tokens.append(tok)
            elif self.current_char == '=':
                tokens.append(self.make_equals())
                self.advance()
            elif self.current_char == '<':
                tokens.append(self.make_less_than())
                self.advance()
            elif self.current_char == '>':
                tokens.append(self.make_greater_than())
                self.advance()
            elif self.current_char == ',':
                tokens.append(Token(TT_COMMA, self.current_ident_level, pos_start=self.pos))
                self.advance()
            elif self.current_char == '|':
                tok, error = self.make_pipe()
                if error:
                    return [], error
                tokens.append(tok)
            else:
                pos_start = self.pos.copy()
                char = self.current_char
                self.advance()
                return [], IllegalCharError(pos_start, self.pos, "'" + char + "'")

        tokens.append(Token(TT_EOF, self.current_ident_level, pos_start=self.pos))
        return tokens, None

    def make_ident(self):
        total_spaces = 0
        pos_start = self.pos.copy()

        while self.current_char == '\n':
            self.advance()

        while self.current_char in ' ':
            total_spaces += 1
            self.advance()
            while self.current_char == '\n':
                total_spaces = 0
                self.advance()

        if total_spaces == 1:
            total_spaces = 0

        if total_spaces % 4 != 0:
            return InvalidSyntaxError(
                pos_start, self.pos, "Identation problem"
            )
        self.current_ident_level = max(0, total_spaces)

    def make_string(self):
        string = ''
        pos_start = self.pos.copy()
        escape_character = False
        self.advance()

        escape_characters = {
            'n': '\n',
            't': '\t'
        }

        while self.current_char != None and (self.current_char not in ["'", '"'] or escape_character):
            if escape_character:
                string += escape_characters.get(self.current_char, self.current_char)
            else:
                if self.current_char == '\\':
                    escape_character = True
                else:
                    string += self.current_char
            self.advance()
            escape_character = False

        self.advance()
        return Token(TT_STRING, self.current_ident_level, string, pos_start, self.pos.copy())

    def make_number(self):
        num_str = ''
        dot_count = 0
        pos_start = self.pos.copy()

        while self.current_char is not None and self.current_char in DIGISTS + '._':
            if self.current_char == '.':
                if dot_count == 1: break
                dot_count += 1
                num_str += '.'
            elif self.current_char != '_':
                num_str += self.current_char
            self.advance()

        if dot_count == 0:
            return Token(TT_INT, self.current_ident_level, int(num_str), pos_start, self.pos.copy())
        else:
            return Token(TT_FLOAT, self.current_ident_level, float(num_str), pos_start, self.pos.copy())

    def make_do_or_atom(self):
        pos_start = self.pos.copy()
        self.advance()

        if self.current_char in LETTERS:
            # its a atom
            atom = ''
            while self.current_char is not None and self.current_char in LETTERS_DIGITS:
                atom += self.current_char
                self.advance()

            return Token(
                TT_ATOM,
                self.current_ident_level,
                value=atom,
                pos_start=pos_start,
                pos_end=self.pos.copy()
            ), None

        elif self.current_char is None or self.current_char in '\n; ':
            return Token(TT_DO, self.current_ident_level, pos_start=self.pos), None
        else:
            return None, ExpectedCharError(
                pos_start,
                self.pos, "expected letters or digits (to create an atom), new line or space after ':'"
            )

    def make_identifier(self):
        id_str = ''
        pos_start = self.pos.copy()

        while self.current_char != None and self.current_char in LETTERS_DIGITS + '_.':
            id_str += self.current_char
            self.advance()

        tok_type = TT_KEYWORD if id_str in KEYWORDS else TT_IDENTIFIER
        return Token(tok_type, self.current_ident_level, id_str, pos_start, self.pos.copy())

    def make_mul_or_power(self):
        token_type = TT_MUL
        pos_start = self.pos.copy()
        self.advance()

        if self.current_char == '*':
            self.advance()
            token_type = TT_POW

        return Token(token_type, self.current_ident_level, pos_start=pos_start)

    def make_not_equals(self):
        pos_start = self.pos.copy()
        self.advance()

        if self.current_char == '=':
            self.advance()
            return Token(TT_NE, self.current_ident_level, pos_start=pos_start, pos_end=self.pos.copy()), None

        self.advance()
        return None, ExpectedCharError(pos_start, self.pos, "'=' (after '!')")

    def make_equals(self):
        toke_type = TT_EQ
        pos_start = self.pos.copy()
        self.advance()

        if self.current_char == '=':
            self.advance()
            toke_type = TT_EE

        return Token(toke_type, self.current_ident_level, pos_start=pos_start, pos_end=self.pos.copy())

    def make_less_than(self):
        toke_type = TT_LT
        pos_start = self.pos.copy()
        self.advance()

        if self.current_char == '=':
            self.advance()
            toke_type = TT_LTE

        return Token(toke_type, self.current_ident_level, pos_start=pos_start, pos_end=self.pos.copy())

    def make_greater_than(self):
        toke_type = TT_GT
        pos_start = self.pos.copy()
        self.advance()

        if self.current_char == '=':
            self.advance()
            toke_type = TT_GTE

        return Token(toke_type, self.current_ident_level, pos_start=pos_start, pos_end=self.pos.copy())

    def skip_comment(self):
        self.advance()

        while self.current_char != '\n':
            self.advance()

        self.advance()

    def make_pipe(self):
        pos_start = self.pos.copy()
        self.advance()

        if self.current_char == '>':
            self.advance()
            return Token(TT_PIPE, self.current_ident_level, pos_start=pos_start, pos_end=self.pos.copy()), None

        self.advance()
        return None, ExpectedCharError(pos_start, self.pos, "'>' after '|'")