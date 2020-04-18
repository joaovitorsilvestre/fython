from fython.core.lexer.tokens import *
from fython.core.lexer.errors import InvalidSyntaxError

from fython.core.parser.nodes import *
from fython.core.parser.result_parser import ParseResult


class Parser:
    def __init__(self, tokens):
        self.tokens = tokens
        self.tok_index = -1
        self.advance()

    def advance(self):
        self.tok_index += 1
        self.update_current_tok()
        return self.current_tok

    def reverse(self, ammount=1):
        self.tok_index -= ammount
        self.update_current_tok()
        return self.current_tok

    def update_current_tok(self):
        if self.tok_index >= 0 and self.tok_index < len(self.tokens):
            self.current_tok = self.tokens[self.tok_index]

    def get_next_token(self, ignore_new_line=False):
        # this function doest modify any state
        # it is useful to get the next toke info when
        # you cant use advance

        tok_index = self.tok_index + 1
        current_tok = self.current_tok

        if tok_index < len(self.tokens):
            current_tok = self.tokens[tok_index]

            if current_tok.type == TT_NEWLINE and ignore_new_line:
                tok_index += 1
                current_tok = self.tokens[tok_index]

        return current_tok

    ###################
    def parse(self):
        from fython.core.parser.pos_parser import PosParser

        if self.tokens[0].type == TT_EOF:
            # handle empty files
            res = ParseResult()
            return res.success(StatementsNode(
                [],
                self.current_tok.pos_start.copy(),
                self.current_tok.pos_end.copy()
            ))

        res = self.statements()
        if not res.error and self.current_tok.type != TT_EOF:
            return res.failure(InvalidSyntaxError(
                self.current_tok.pos_start, self.current_tok.pos_end,
                "Expected '+' or '-' or '*' or '/'"
            ))

        if not res.error:
            check = PosParser(res.node).validate()
            if check.error:
                return check.error

        return res

    def list_expr(self):
        res = ParseResult()
        element_nodes = []
        pos_start = self.current_tok.pos_start.copy()

        if self.current_tok.type != TT_LSQUARE:
            return res.failure(InvalidSyntaxError(
                self.current_tok.pos_start, self.current_tok.pos_end,
                f"Expected '['"
            ))

        res.register_advancement()
        self.advance()

        while self.current_tok.type == TT_NEWLINE:
            res.register_advancement()
            self.advance()

        if self.current_tok.type == TT_RSQUARE:
            res.register_advancement()
            self.advance()
        else:
            element_nodes.append(res.register(self.expr()))
            if res.error:
                return res.failure(InvalidSyntaxError(
                    self.current_tok.pos_start, self.current_tok.pos_end,
                    "Expected ']', 'VAR', 'IF', 'FOR', 'WHILE', 'FUN', "
                    "int, float, identifier, '+', '-', '(', '[' or 'NOT'"
                ))

            while self.current_tok.type == TT_COMMA:
                res.register_advancement()
                self.advance()

                while self.current_tok.type == TT_NEWLINE:
                    res.register_advancement()
                    self.advance()

                if self.get_next_token().type == TT_RSQUARE:
                    res.register_advancement()
                    self.advance()
                    break

                element_nodes.append(res.register(self.expr()))
                if res.error:
                    return res

            while self.current_tok.type == TT_NEWLINE:
                res.register_advancement()
                self.advance()

            if self.current_tok.type != TT_RSQUARE:
                return res.failure(InvalidSyntaxError(
                    self.current_tok.pos_start, self.current_tok.pos_end,
                    f"Expected ',' or ']'"
                ))

        res.register_advancement()
        self.advance()

        return res.success(ListNode(
            element_nodes, pos_start, self.current_tok.pos_end.copy()
        ))

    def if_expr(self, expr_for_true):
        res = ParseResult()

        if not self.current_tok.matches(TT_KEYWORD, 'if'):
            return res.failure(InvalidSyntaxError(
                self.current_tok.pos_start, self.current_tok.pos_end,
                f"Expected 'if'"
            ))

        res.register_advancement()
        self.advance()

        condition = res.register(self.expr())
        if res.error: return res

        if not self.current_tok.matches(TT_KEYWORD, 'else'):
            return res.failure(InvalidSyntaxError(
                self.current_tok.pos_start, self.current_tok.pos_end,
                f"Expected 'else'"
            ))

        res.register_advancement()
        self.advance()

        else_case = res.register(self.expr())
        if res.error:
            return res

        return res.success(IfNode(condition, expr_for_true, else_case))

    def call(self):
        res = ParseResult()
        atom = res.register(self.atom())
        if res.error: return res

        if self.current_tok.type == TT_LPAREN:
            res.register_advancement()
            self.advance()
            arg_nodes = []

            if self.current_tok.type == TT_RPAREN:
                res.register_advancement()
                self.advance()
            else:
                arg_nodes.append(res.register(self.expr()))
                if res.error:
                    return res.failure(InvalidSyntaxError(
                        self.current_tok.pos_start, self.current_tok.pos_end,
                        "Expected ')', 'VAR', 'IF', 'FOR', 'WHILE', 'FUN', int, float, identifier, '+', '-', '(' or 'NOT'"
                    ))

                while self.current_tok.type == TT_COMMA:
                    res.register_advancement()
                    self.advance()

                    arg_nodes.append(res.register(self.expr()))
                    if res.error: return res

                if self.current_tok.type != TT_RPAREN:
                    return res.failure(InvalidSyntaxError(
                        self.current_tok.pos_start, self.current_tok.pos_end,
                        f"Expected ',' or ')'"
                    ))

                res.register_advancement()
                self.advance()
            return res.success(CallNode(atom, arg_nodes))

        return res.success(atom)

    def atom(self):
        from fython.core.lexer.consts import LETTERS, LETTERS_DIGITS

        res = ParseResult()
        tok = self.current_tok

        if tok.type in (TT_FLOAT, TT_INT):
            res.register_advancement()
            self.advance()
            return res.success(NumberNode(tok))

        elif tok.type == TT_STRING:
            res.register_advancement()
            self.advance()
            return res.success(StringNode(tok))

        elif tok.type == TT_IDENTIFIER:
            res.register_advancement()
            self.advance()
            return res.success(VarAccessNode(tok))

        elif tok.type == TT_ATOM:
            res.register_advancement()
            self.advance()
            return res.success(AtomNode(tok))

        elif tok.type == TT_LPAREN:
            res.register_advancement()
            self.advance()

            while self.current_tok.type == TT_NEWLINE:
                res.register_advancement()
                self.advance()

            expr = res.register(self.expr())
            if res.error:
                return res

            while self.current_tok.type == TT_NEWLINE:
                res.register_advancement()
                self.advance()

            if self.current_tok.type == TT_RPAREN:
                res.register_advancement()
                self.advance()
                return res.success(expr)
            else:
                return res.failure(InvalidSyntaxError(
                    self.current_tok.pos_start, self.current_tok.pos_end,
                    "Expected ')'"
                ))

        elif tok.type == TT_LSQUARE:
            list_expr = res.register(self.list_expr())
            if res.error:
                return res
            return res.success(list_expr)

        elif tok.type == TT_LCURLY:
            list_expr = res.register(self.map_expr())
            if res.error:
                return res
            return res.success(list_expr)

        elif tok.matches(TT_KEYWORD, 'def'):
            func_def = res.register(self.func_def())
            if res.error:
                return res
            return res.success(func_def)
        elif tok.matches(TT_KEYWORD, 'lambda'):
            func_def = res.register(self.lambda_def())
            if res.error:
                return res
            return res.success(func_def)

        elif tok.matches(TT_KEYWORD, 'case'):
            case_def = res.register(self.case_def())
            if res.error:
                return res
            return res.success(case_def)
        elif self.current_tok.type == TT_ECOM:
            func_as_var_expr = res.register(self.func_as_var_expr())
            if res.error:
                return res

            return res.success(func_as_var_expr)

        return res.failure(InvalidSyntaxError(
            tok.pos_start, tok.pos_end,
            "Expected int, float, identifier, '+', '-', '(', '[', if, def, lambda or case"
        ))

    def power(self):
        return self.bin_op(self.call, (TT_POW,), self.factor)

    def factor(self):
        res = ParseResult()
        tok = self.current_tok

        if tok.type in (TT_PLUS, TT_MINUS):
            res.register_advancement()
            self.advance()
            factor = res.register(self.factor())
            if res.error:
                return res
            return res.success(UnaryOpNode(tok, factor))

        return self.power()

    def term(self):
        return self.bin_op(self.factor, (TT_MUL, TT_DIV))

    def comp_expr(self):
        res = ParseResult()

        if self.current_tok.matches(TT_KEYWORD, 'not'):
            op_tok = self.current_tok
            res.register_advancement()
            self.advance()

            node = res.register(self.comp_expr())
            if res.error:
                return res

            return res.success(UnaryOpNode(op_tok, node))

        node = res.register(self.bin_op(self.arith_expr, (TT_EE, TT_NE, TT_LT, TT_LTE, TT_GT, TT_GTE)))

        if res.error:
            return res.failure(InvalidSyntaxError(
                self.current_tok.pos_start, self.current_tok.pos_end,
                "Expected int, float, identifier, '+', '-', '(' or '[', 'not'"
            ))

        return res.success(node)

    def arith_expr(self):
        return self.bin_op(self.term, (TT_PLUS, TT_MINUS))

    def statements(self, stop_if_no_more_statements=False):
        res = ParseResult()
        statements = []
        pos_start = self.current_tok.pos_start.copy()

        while self.current_tok.type == TT_NEWLINE:
            res.register_advancement()
            self.advance()

        first_node = self.current_tok

        statement = res.register(self.statement())
        if res.error: return res
        statements.append(statement)

        while True:
            while self.current_tok.type == TT_NEWLINE:
                res.register_advancement()
                self.advance()

            if self.current_tok.ident >= first_node.ident:
                more_statements = True
            else:
                more_statements = False

            if self.current_tok.type == TT_RPAREN:
                # no more statements. Its like the end of a lamda inside Enum.map
                more_statements = False

            if not more_statements or self.current_tok.type == TT_EOF:
                break

            statement = res.try_register(self.statement())

            if not statement:
                break

            statements.append(statement)

        return res.success(StatementsNode(
            statements,
            pos_start,
            self.current_tok.pos_end.copy()
        ))

    def statement(self):
        res = ParseResult()
        pos_start = self.current_tok.pos_start.copy()

        while self.current_tok.type == TT_NEWLINE:
            res.register_advancement()
            self.advance()

        if self.current_tok.matches(TT_KEYWORD, 'import') or \
            self.current_tok.matches(TT_KEYWORD, 'from'):

            expr = res.register(self.make_import())
            if res.error:
                return res
            return res.success(expr)

        if self.current_tok.matches(TT_KEYWORD, 'return'):
            res.register_advancement()
            self.advance()

            expr = res.register(self.expr())
            if not expr:
                self.reverse(res.to_reverse_count)
            return res.success(ReturnNode(
                expr, pos_start, self.current_tok.pos_start.copy()
            ))

        while self.current_tok.type == TT_NEWLINE:
            res.register_advancement()
            self.advance()

        expr = res.register(self.expr())

        if res.error:
            return res.failure(InvalidSyntaxError(
                self.current_tok.pos_start.copy(), self.current_tok.pos_end.copy(),
                "Expected return, int, float, variable, 'not', '+', '-', '(' or '['"
            ))

        return res.success(expr)

    def expr(self):
        res = ParseResult()

        next_token = self.get_next_token()

        if self.current_tok.type == TT_IDENTIFIER and (next_token.type in [TT_EQ, TT_EOF]):
            var_name = self.current_tok
            res.register_advancement()
            self.advance()

            if self.current_tok.type != TT_EQ:
                if self.current_tok.type == TT_EOF:
                    return res.success(VarAccessNode(var_name))
                else:
                    return res.failure(InvalidSyntaxError(
                        self.current_tok.pos_start, self.current_tok.pos_end,
                        "Expected '='"
                    ))

            res.register_advancement()
            self.advance()
            expr = res.register(self.expr())
            if res.error:
                return res

            return res.success(VarAssignNode(var_name, expr))

        node = res.register(self.bin_op(self.comp_expr, ((TT_KEYWORD, "and"), (TT_KEYWORD, "or"))))

        if self.current_tok.matches(TT_KEYWORD, 'if'):
            node = res.register(self.if_expr(node))
            if res.error:
                return res
            return res.success(node)

        if self.current_tok.type in [TT_PIPE, TT_NEWLINE]:
            new_lines_skiped = 0

            while self.current_tok.type == TT_NEWLINE:
                res.register_advancement()
                self.advance()
                new_lines_skiped += 1

            if self.current_tok.type == TT_PIPE:
                pipe_expr = res.register(self.pipe_expr(node))
                if res.error:
                    return res

                return res.success(pipe_expr)
            else:
                self.reverse(new_lines_skiped)

        if res.error:
            return res.failure(InvalidSyntaxError(
                self.current_tok.pos_start, self.current_tok.pos_end,
                "Expected int, float, variable, 'not', '+', '-', '(' or '['"
            ))

        return res.success(node)

    def bin_op(self, func_a, ops, func_b=None):
        if func_b is None:
            func_b = func_a

        res = ParseResult()
        left = res.register(func_a())
        if res.error:
            return res

        while self.current_tok.type in ops or (self.current_tok.type, self.current_tok.value) in ops:
            op_tok = self.current_tok
            res.register_advancement()
            self.advance()
            right = res.register(func_b())
            if res.error:
                return res
            left = BinOpNode(left, op_tok, right)

        return res.success(left)

    def func_def(self):
        res = ParseResult()

        if not self.current_tok.matches(TT_KEYWORD, 'def'):
            return res.failure(InvalidSyntaxError(
                self.current_tok.pos_start, self.current_tok.pos_end,
                f"Expected 'def'"
            ))

        if self.current_tok.ident != 0:
            # if enters here, causes a infinite loop in some while loop
            print('Entered in a errors message that causes inifinite loop. You need to fix it.')
            return res.failure(InvalidSyntaxError(
                self.current_tok.pos_start, self.current_tok.pos_end,
                f"'def' is not allowed inside functions. Use 'lambda' instead."
            ))

        res.register_advancement()
        self.advance()

        if self.current_tok.type == TT_IDENTIFIER:
            var_name_tok = self.current_tok
            res.register_advancement()
            self.advance()
            if self.current_tok.type != TT_LPAREN:
                return res.failure(InvalidSyntaxError(
                    self.current_tok.pos_start, self.current_tok.pos_end,
                    f"Expected '('"
                ))
        else:
            var_name_tok = None

            if self.current_tok.type != TT_LPAREN:
                return res.failure(InvalidSyntaxError(
                    self.current_tok.pos_start, self.current_tok.pos_end,
                    f"Expected identifier or '('"
                ))

        res.register_advancement()
        self.advance()

        arg_name_toks = []

        if self.current_tok.type == TT_IDENTIFIER:
            arg_name_toks.append(self.current_tok)
            res.register_advancement()
            self.advance()

            while self.current_tok.type == TT_COMMA:
                res.register_advancement()
                self.advance()

                if self.current_tok.type != TT_IDENTIFIER:
                    return res.failure(InvalidSyntaxError(
                        self.current_tok.pos_start, self.current_tok.pos_end,
                        f"Expected identifier"
                    ))

                arg_name_toks.append(self.current_tok)
                res.register_advancement()
                self.advance()

            if self.current_tok.type != TT_RPAREN:
                return res.failure(InvalidSyntaxError(
                    self.current_tok.pos_start, self.current_tok.pos_end,
                    f"Expected ',' or ')'"
                ))
        else:
            if self.current_tok.type != TT_RPAREN:
                return res.failure(InvalidSyntaxError(
                    self.current_tok.pos_start, self.current_tok.pos_end,
                    f"Expected identifier or ')'"
                ))

        res.register_advancement()
        self.advance()

        if self.current_tok.type != TT_DO:
            return res.failure(InvalidSyntaxError(
                self.current_tok.pos_start, self.current_tok.pos_end,
                f"Expected ':'"
            ))

        res.register_advancement()
        self.advance()

        body = res.register(self.statements())
        if res.error:
            return res

        return res.success(FuncDefNode(
            var_name_tok,
            arg_name_toks,
            body,
            False
        ))

    def lambda_def(self):
        res = ParseResult()

        if not self.current_tok.matches(TT_KEYWORD, 'lambda'):
            return res.failure(InvalidSyntaxError(
                self.current_tok.pos_start, self.current_tok.pos_end,
                f"Expected 'lambda'"
            ))

        if self.current_tok.ident == 0:
            return res.failure(InvalidSyntaxError(
                self.current_tok.pos_start, self.current_tok.pos_end,
                f"'lambda' are only allowed to be defined inside functions."
            ))

        res.register_advancement()
        self.advance()

        opened_parenteses = False
        if self.current_tok.type == TT_LPAREN:
            res.register_advancement()
            self.advance()
            opened_parenteses = True

        arg_name_toks = []

        if self.current_tok.type == TT_IDENTIFIER:
            arg_name_toks.append(self.current_tok)
            res.register_advancement()
            self.advance()

            while self.current_tok.type == TT_COMMA:
                res.register_advancement()
                self.advance()

                if self.current_tok.type != TT_IDENTIFIER:
                    return res.failure(InvalidSyntaxError(
                        self.current_tok.pos_start, self.current_tok.pos_end,
                        f"Expected identifier"
                    ))

                arg_name_toks.append(self.current_tok)
                res.register_advancement()
                self.advance()

            if opened_parenteses and self.current_tok.type != TT_RPAREN:
                return res.failure(InvalidSyntaxError(
                    self.current_tok.pos_start, self.current_tok.pos_end,
                    f"Expected ',' or ')'"
                ))
        elif opened_parenteses:
            if self.current_tok.type != TT_RPAREN:
                return res.failure(InvalidSyntaxError(
                    self.current_tok.pos_start, self.current_tok.pos_end,
                    f"Expected identifier or ')'"
                ))

        if opened_parenteses:
            res.register_advancement()
            self.advance()

        if self.current_tok.type != TT_DO:
            return res.failure(InvalidSyntaxError(
                self.current_tok.pos_start, self.current_tok.pos_end,
                f"Expected ':'"
            ))

        res.register_advancement()
        self.advance()

        if self.current_tok.type == TT_NEWLINE:
            body = res.register(self.statements())
        else:
            body = res.register(self.statement())

        if res.error:
            return res

        return res.success(LambdaNode(
            None,
            arg_name_toks,
            body,
            False
        ))


    def pipe_expr(self, left_node):
        res = ParseResult()
        pos_start = self.current_tok.pos_start.copy()

        if self.current_tok.type != TT_PIPE:
            return res.failure(InvalidSyntaxError(
                self.current_tok.pos_start, self.current_tok.pos_end,
                f"Expected '|>'"
            ))

        res.register_advancement()
        self.advance()

        right_node = res.register(self.expr())

        if res.error:
            return res.failure(InvalidSyntaxError(
            pos_start, self.current_tok.pos_end,
            f"Expected an expression after '|>' "
        ))

        return res.success(PipeNode(
            left_node,
            right_node,
            pos_start,
            self.current_tok.pos_start.copy()
        ))

    def map_expr(self):
        res = ParseResult()
        element_nodes = []
        pos_start = self.current_tok.pos_start.copy()

        if self.current_tok.type != TT_LCURLY:
            return res.failure(InvalidSyntaxError(
                self.current_tok.pos_start, self.current_tok.pos_end,
                "Expected '{'"
            ))

        res.register_advancement()
        self.advance()

        while self.current_tok.type == TT_NEWLINE:
            res.register_advancement()
            self.advance()

        pairs_list = []

        if self.current_tok.type != TT_RCURLY:
            def get_key_and_value_pair():
                while self.current_tok.type == TT_NEWLINE:
                    res.register_advancement()
                    self.advance()

                key = res.register(self.expr())
                if res.error:
                    return None, None, res

                if self.current_tok.type != TT_DO:
                    return None, None, res.failure(InvalidSyntaxError(
                        self.current_tok.pos_start, self.current_tok.pos_end,
                        "Expected ':'"
                    ))

                res.register_advancement()
                self.advance()

                value = res.register(self.expr())
                if res.error:
                    return None, None, res

                return key, value, None

            key, value, error = get_key_and_value_pair()

            if error:
                return error

            pairs_list.append((key, value))

            # Duplicated code from above
            while self.current_tok.type == TT_COMMA:
                res.register_advancement()
                self.advance()

                while self.current_tok.type == TT_NEWLINE:
                    res.register_advancement()
                    self.advance()

                # to support comma after the last value in map
                if self.current_tok.type == TT_RCURLY:
                    break

                key, value, error = get_key_and_value_pair()

                if error:
                    return error

                pairs_list.append((key, value))

        while self.current_tok.type == TT_NEWLINE:
            res.register_advancement()
            self.advance()

        res.register_advancement()
        self.advance()

        return res.success(MapNode(
            pairs_list, pos_start, self.current_tok.pos_end.copy()
        ))

    def make_import(self):
        res = ParseResult()
        pos_start = self.current_tok.pos_start.copy()

        def resolve_module(from_=None, check_arity=True):
            if self.current_tok.type != TT_IDENTIFIER:
                return None, res.failure(InvalidSyntaxError(
                    pos_start, self.current_tok.pos_end,
                    "Expected a module name"
                ))

            module_name = self.current_tok.value
            alias = None

            res.register_advancement()
            self.advance()

            arity = None

            if check_arity:
                if self.current_tok.type != TT_DIV:
                    return None, res.failure(InvalidSyntaxError(
                        self.current_tok.pos_start, self.current_tok.pos_end,
                        "Expected / with the arity number of each function being imported"
                    ))

                res.register_advancement()
                self.advance()

                if self.current_tok.type != TT_INT:
                    return None, res.failure(InvalidSyntaxError(
                        pos_start, self.current_tok.pos_end,
                        "Expected arity number of the function to be imported"
                    ))

                arity = self.current_tok.value

            res.register_advancement()
            self.advance()

            if self.current_tok.matches(TT_KEYWORD, 'as'):
                res.register_advancement()
                self.advance()

                if self.current_tok.type != TT_IDENTIFIER:
                    return None, res.failure(InvalidSyntaxError(
                        pos_start, self.current_tok.pos_end,
                        "Expected a module name"
                    ))

                alias = self.current_tok.value

                res.register_advancement()
                self.advance()

            return ImportNode.gen_import(
                name=module_name,
                alias=alias,
                arity=arity,
                from_=from_
            ), None

        if self.current_tok.matches(TT_KEYWORD, "import"):
            # import foo
            # import foo, poo
            # import foo as oii, foo2 as 33

            res.register_advancement()
            self.advance()

            if self.current_tok.type != TT_IDENTIFIER:
                return res.failure(InvalidSyntaxError(
                    pos_start, self.current_tok.pos_end,
                    "Expected a module name"
                ))

            modules = []

            module, error = resolve_module(check_arity=False)
            if error:
                return res

            modules.append(module)

            if self.current_tok.type == TT_NEWLINE:
                pass
            elif self.current_tok.type == TT_COMMA:
                while self.current_tok.type == TT_COMMA:
                    res.register_advancement()
                    self.advance()
                    module, error = resolve_module(check_arity=False)
                    if error:
                        return res
                    modules.append(module)

                if self.current_tok.type != TT_NEWLINE:
                    return res.failure(InvalidSyntaxError(
                        pos_start, self.current_tok.pos_start.copy(),
                        "Expected ',' or new line"
                    ))
            else:
                return res.failure(InvalidSyntaxError(
                    self.current_tok.pos_start.copy(), self.current_tok.pos_end.copy(),
                    "Expected ',' or new line"
                ))

            return res.success(ImportNode(
                modules, 'import', pos_start, self.current_tok.pos_end.copy()
            ))
        elif self.current_tok.matches(TT_KEYWORD, 'from'):
            # from Foo import aaa
            # from Foo import aaa as oii, bbb

            res.register_advancement()
            self.advance()

            if self.current_tok.type != TT_IDENTIFIER:
                return res.failure(InvalidSyntaxError(
                    pos_start, self.current_tok.pos_end,
                    "Expected a module name"
                ))

            _from_module = self.current_tok.value

            res.register_advancement()
            self.advance()

            if not self.current_tok.matches(TT_KEYWORD, 'import'):
                return res.failure(InvalidSyntaxError(
                    pos_start, self.current_tok.pos_end,
                    "Expected 'import'"
                ))

            res.register_advancement()
            self.advance()

            modules_or_functions = []

            m_or_f, error = resolve_module(_from_module, check_arity=True)
            if error:
                return res

            modules_or_functions.append(m_or_f)

            if self.current_tok.type == TT_NEWLINE:
                pass
            elif self.current_tok.type == TT_COMMA:
                while self.current_tok.type == TT_COMMA:
                    res.register_advancement()
                    self.advance()
                    module, error = resolve_module(_from_module, check_arity=True)
                    if error:
                        return res
                    modules_or_functions.append(module)

                if self.current_tok.type != TT_NEWLINE:
                    return res.failure(InvalidSyntaxError(
                        pos_start, self.current_tok.pos_start.copy(),
                        "Expected ',' or new line"
                    ))

            return res.success(ImportNode(
                modules_or_functions,
                'from',
                pos_start,
                self.current_tok.pos_end.copy()
            ))
        else:
            return res.failure(InvalidSyntaxError(
                pos_start, self.current_tok.pos_start.copy(),
                "Expected 'import' or 'from'"
            ))

    def case_def(self):
        res = ParseResult()
        pos_start = self.current_tok.pos_start.copy()

        initial_ident = self.current_tok.ident

        res.register_advancement()
        self.advance()

        expr = res.register(self.expr())
        if res.error:
            return res

        if self.current_tok.type != TT_DO:
            return res.failure(InvalidSyntaxError(
                pos_start, self.current_tok.pos_start.copy(),
                "Expected ':'"
            ))

        res.register_advancement()
        self.advance()

        if self.current_tok.type != TT_NEWLINE:
            return res.failure(InvalidSyntaxError(
                pos_start, self.current_tok.pos_start.copy(),
                "Expected new line after ':'"
            ))

        res.register_advancement()
        self.advance()

        def check_ident(tok):
            if tok.ident <= initial_ident:
                return res.failure(InvalidSyntaxError(
                    pos_start, self.current_tok.pos_start.copy(),
                    "The expresions of case must be idented 4 spaces forward in reference to 'case' keyword"
                ))

        cases = []

        while True:
            check_ident(self.current_tok)
            if res.error:
                return res

            left_expr = res.register(self.expr())

            if res.error:
                return res

            if self.current_tok.type != TT_ARROW:
                return res.failure(InvalidSyntaxError(
                    pos_start, self.current_tok.pos_start.copy(),
                    "Expected '->'"
                ))

            res.register_advancement()
            self.advance()

            result_value = res.register(self.expr())
            if res.error:
                return res

            cases.append((left_expr, result_value))

            res.register_advancement()
            self.advance()

            if self.current_tok.ident != initial_ident + 4:
                break

        while self.current_tok.type == TT_NEWLINE:
            res.register_advancement()
            self.advance()

        return res.success(
            CaseNode(expr, cases, pos_start, self.current_tok.pos_start.copy())
        )

    def func_as_var_expr(self):
        res = ParseResult()
        pos_start = self.current_tok.pos_start.copy()

        res.register_advancement()
        self.advance()

        var_name_tok = self.current_tok

        if self.current_tok.type != TT_IDENTIFIER:
            return res.failure(InvalidSyntaxError(
                pos_start, self.current_tok.pos_start.copy(),
                "Expected the function name and arity. E.g: &sum/2"
            ))

        res.register_advancement()
        self.advance()

        if self.current_tok.type != TT_DIV:
            return res.failure(InvalidSyntaxError(
                pos_start, self.current_tok.pos_start.copy(),
                "Expected '/"
            ))

        res.register_advancement()
        self.advance()

        if self.current_tok.type != TT_INT:
            return res.failure(InvalidSyntaxError(
                pos_start, self.current_tok.pos_start.copy(),
                "Expected arity number as int"
            ))

        arity = int(self.current_tok.value)

        res.register_advancement()
        self.advance()

        return res.success(FuncAsVariableNode(
            var_name_tok, arity, pos_start, self.current_tok.pos_start.copy()
        ))