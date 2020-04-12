from collections import namedtuple
from typing import List, Tuple, Union


class NumberNode:
    def __init__(self, tok):
        self.tok = tok
        self.pos_start = tok.pos_start
        self.pos_end = tok.pos_end

    def __repr__(self):
        return f'{self.tok}'


class StringNode:
    def __init__(self, tok):
        self.tok = tok
        self.pos_start = tok.pos_start
        self.pos_end = tok.pos_end

    def __repr__(self):
        return f'{self.tok}'


class VarAccessNode:
    def __init__(self, var_name_tok):
        self.var_name_tok = var_name_tok
        self.pos_start = var_name_tok.pos_start
        self.pos_end = var_name_tok.pos_end

    def __repr__(self):
        return f'{self.var_name_tok}'


class AtomNode:
    def __init__(self, tok):
        self.tok = tok
        self.pos_start = tok.pos_start
        self.pos_end = tok.pos_end

    def __repr__(self):
        return f'atom:{self.tok.value}'


class VarAssignNode:
    def __init__(self, var_name_tok, value_node):
        self.var_name_tok = var_name_tok
        self.value_node = value_node
        self.pos_start = var_name_tok.pos_start
        self.pos_end = var_name_tok.pos_end

    def __repr__(self):
        return f'(VAR_ASSIGN, ({self.var_name_tok}, {self.value_node})'


class ListNode:
    def __init__(self, element_nodes, pos_start, pos_end):
        self.element_nodes = element_nodes
        self.pos_start = pos_start
        self.pos_end = pos_end

    def __repr__(self):
        return f"[{', '.join(self.element_nodes)}]"

class StatementsNode:
    def __init__(self, statement_nodes, pos_start, pos_end):
        self.statement_nodes = statement_nodes
        self.pos_start = pos_start
        self.pos_end = pos_end

    def __repr__(self):
        return f"StatementsNode: {len(self.statement_nodes)} statemens"


class BinOpNode:
    def __init__(self, left_node, op_tok, right_node):
        self.left_node = left_node
        self.op_tok = op_tok
        self.right_node = right_node

        self.pos_start = left_node.pos_start
        self.pos_end = right_node.pos_end

    def __repr__(self):
        return f'({self.left_node}, {self.op_tok}, {self.right_node})'


class UnaryOpNode:
    def __init__(self, op_tok, node):
        self.op_tok = op_tok
        self.node = node

        self.pos_start = self.op_tok.pos_start
        self.pos_end = self.op_tok.pos_end

    def __repr__(self):
        return f'({self.op_tok}, {self.node})'


class IfNode:
    def __init__(self, comp_expr, true_case, false_case):
        self.comp_expr = comp_expr
        self.true_case = true_case
        self.false_case = false_case

        self.pos_start = self.comp_expr.pos_start
        self.pos_end = self.false_case.pos_end

    def __repr__(self):
        return f"{self.true_case} if {self.comp_expr} else {self.false_case}"


class FuncDefNode:
    def __init__(self, var_name_tok, arg_name_toks, body_node: StatementsNode, should_auto_return):
        self.var_name_tok = var_name_tok
        self.arg_name_toks = arg_name_toks
        self.arity = len(arg_name_toks)
        self.body_node = body_node
        self.should_auto_return = should_auto_return

        if self.var_name_tok:
            self.pos_start = self.var_name_tok.pos_start
        elif len(self.arg_name_toks) > 0:
            self.pos_start = self.arg_name_toks[0].pos_start
        else:
            self.pos_start = self.body_node.pos_start

        self.pos_end = self.body_node.pos_end

    def __repr__(self):
        return f"def {self.var_name_tok.value}/{len(self.arg_name_toks)}"

    def get_name(self):
        return f'{self.var_name_tok.var_name_tok.value}/{self.arity}'


class CallNode:
    def __init__(self, node_to_call, arg_nodes):
        self.node_to_call = node_to_call
        self.arg_nodes = arg_nodes
        self.arity = len(arg_nodes)
        self.pos_start = self.node_to_call.pos_start

        if len(self.arg_nodes) > 0:
            self.pos_end = self.arg_nodes[len(self.arg_nodes) - 1].pos_end
        else:
            self.pos_end = self.node_to_call.pos_end

    def get_name(self):
        return f'{self.node_to_call.var_name_tok.value}/{self.arity}'

    def __repr__(self):
        return f"call: {self.get_name()}"


class ReturnNode:
    def __init__(self, node_to_return, pos_start, pos_end):
        self.node_to_return = node_to_return

        self.pos_start = pos_start
        self.pos_end = pos_end


class PipeNode:
    def __init__(self, left_node, right_node, pos_start, pos_end):
        self.left_node = left_node
        self.right_node = right_node
        self.pos_start = pos_start
        self.pos_end = pos_end

    def __repr__(self):
        return f"{self.left_node} |> {self.right_node}"


class MapNode:
    def __init__(self, pairs_list: List[Tuple["AnyNode", "AnyNode"]], pos_start, pos_end):
        self.pairs_list = pairs_list
        self.pos_start = pos_start
        self.pos_end = pos_end

    def __repr__(self):
        return "{map}"


class ImportNode:
    def __init__(self,
         imports_list: List[namedtuple],
         type: str,
         pos_start,
         pos_end,
    ):
        self.imports_list = imports_list
        self.pos_start = pos_start
        self.pos_end = pos_end
        assert type in ['import', 'from']
        self.type = type

    _import_module = namedtuple("Simple", ['name', 'alias', 'from_', 'arity', 'get_name'])

    @staticmethod
    def gen_import(name, alias, arity, from_):
        return ImportNode._import_module(
            name=name,
            alias=alias,
            from_=from_,
            arity=arity,
            get_name=lambda: f'{alias or name}/{arity}'
        )

    def __repr__(self):
        modules = [
            f'{i.name} as {i.alias}' if i.alias else i.name for i in self.imports_list
        ]

        if self.type == 'import':
            return f"import {', '.join(modules)}"
        else:
            main_module = self.imports_list[0].from_
            return f"from {main_module} import {', '.join(modules)}"