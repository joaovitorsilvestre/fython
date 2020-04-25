from collections import namedtuple
from typing import List, Tuple, Union, Dict


class Node:
    def to_json(self):
        return {
            "NodeType": self.__class__.__name__,
            **{
                k: v for k, v in self.__dict__.items()
                if k not in ['to_json', 'gen_import']
            }
        }

    def get_all_child_nodes_flatten(self):
        def flatten(l):
            import collections
            for el in l:
                if isinstance(el, collections.Iterable) and not isinstance(el, (str, bytes)):
                    yield from flatten(el)
                else:
                    yield el

        if isinstance(self, StatementsNode):
            sts = [
                i.get_all_child_nodes_flatten()
                for i in self.statement_nodes
            ]

            result = [*sts]
        elif isinstance(self, ListNode):
            return [i.get_all_child_nodes_flatten() for i in self.element_nodes]
        elif isinstance(self, MapNode):
            result = [
                [k.get_all_child_nodes_flatten(), v.get_all_child_nodes_flatten()]
                for k, v in self.pairs_list
            ]
        elif isinstance(self, CaseNode):
            result = [
                self.expr.get_all_child_nodes_flatten() if self.expr else [],
                *[[k.get_all_child_nodes_flatten(), v.get_all_child_nodes_flatten()] for k, v in self.cases]
            ]
        elif isinstance(self, (BinOpNode, PipeNode)):
            result = [*self.left_node.get_all_child_nodes_flatten(),
                      *self.right_node.get_all_child_nodes_flatten()]
        elif isinstance(self, FuncDefNode):
            result = [
                self,
                *self.arg_name_toks,
                *self.body_node.get_all_child_nodes_flatten()
            ]
        elif isinstance(self, VarAssignNode):
            result = [self, self.value_node.get_all_child_nodes_flatten()]
        elif isinstance(self, CallNode):
            result = [
                self,
                *[i.get_all_child_nodes_flatten() for i in self.arg_nodes],
                *[
                    v.get_all_child_nodes_flatten()
                    for v in self.keywords.values()
                ]
            ]
        elif isinstance(self, IfNode):
            result = [
                self.comp_expr.get_all_child_nodes_flatten(),
                self.true_case.get_all_child_nodes_flatten(),
                self.false_case.get_all_child_nodes_flatten()
            ]
        else:
            result = [self]

        return list(flatten(result))


class NumberNode(Node):
    def __init__(self, tok):
        self.tok = tok
        self.pos_start = tok.pos_start
        self.pos_end = tok.pos_end

    def __repr__(self):
        return f'{self.tok}'


class StringNode(Node):
    def __init__(self, tok):
        self.tok = tok
        self.pos_start = tok.pos_start
        self.pos_end = tok.pos_end

    def __repr__(self):
        return f'{self.tok}'


class VarAccessNode(Node):
    def __init__(self, var_name_tok):
        self.var_name_tok = var_name_tok
        self.pos_start = var_name_tok.pos_start
        self.pos_end = var_name_tok.pos_end

    def __repr__(self):
        return f'{self.var_name_tok}'


class FuncAsVariableNode(Node):
    def __init__(self, var_name_tok, arity: int, pos_start, pos_end):
        self.var_name_tok = var_name_tok
        self.arity = arity
        self.pos_start = pos_start
        self.pos_end = pos_end

    def __repr__(self):
        return f'function as variable: f{self.var_name_tok.value}/{self.arity}'


class AtomNode(Node):
    def __init__(self, tok):
        self.tok = tok
        self.pos_start = tok.pos_start
        self.pos_end = tok.pos_end

    def __repr__(self):
        return f'atom:{self.tok.value}'


class VarAssignNode(Node):
    def __init__(self, var_name_tok, value_node):
        self.var_name_tok = var_name_tok
        self.value_node = value_node
        self.pos_start = var_name_tok.pos_start
        self.pos_end = var_name_tok.pos_end

    def __repr__(self):
        return f'(VAR_ASSIGN, ({self.var_name_tok}, {self.value_node})'


class ListNode(Node):
    def __init__(self, element_nodes, pos_start, pos_end):
        self.element_nodes = element_nodes
        self.pos_start = pos_start
        self.pos_end = pos_end

    def __repr__(self):
        return f"[{', '.join(self.element_nodes)}]"


class StatementsNode(Node):
    def __init__(self, statement_nodes, pos_start, pos_end):
        self.statement_nodes = statement_nodes
        self.pos_start = pos_start
        self.pos_end = pos_end

    def __repr__(self):
        return f"StatementsNode: {len(self.statement_nodes)} statemens"


class BinOpNode(Node):
    def __init__(self, left_node, op_tok, right_node):
        self.left_node = left_node
        self.op_tok = op_tok
        self.right_node = right_node

        self.pos_start = left_node.pos_start
        self.pos_end = right_node.pos_end

    def __repr__(self):
        return f'({self.left_node}, {self.op_tok}, {self.right_node})'


class UnaryOpNode(Node):
    def __init__(self, op_tok, node):
        self.op_tok = op_tok
        self.node = node

        self.pos_start = self.op_tok.pos_start
        self.pos_end = self.op_tok.pos_end

    def __repr__(self):
        return f'({self.op_tok}, {self.node})'


class IfNode(Node):
    def __init__(self, comp_expr, true_case, false_case):
        self.comp_expr = comp_expr
        self.true_case = true_case
        self.false_case = false_case

        self.pos_start = self.comp_expr.pos_start
        self.pos_end = self.false_case.pos_end

    def __repr__(self):
        return f"{self.true_case} if {self.comp_expr} else {self.false_case}"


class FuncDefNode(Node):
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

    def get_defined_variables(self) -> List[str]:
        return [
            i.var_name_tok.value for i in self.body_node.statement_nodes
            if isinstance(i, VarAssignNode)
        ] + [
            i.value for i in self.arg_name_toks
        ]

    def __repr__(self):
        return f"def {self.var_name_tok.value}/{len(self.arg_name_toks)}"

    def get_name(self):
        return f'{self.var_name_tok.var_name_tok.value}/{self.arity}'


class LambdaNode(FuncDefNode):
    def __repr__(self):
        return f"def inline func {self.var_name_tok.value}/{len(self.arg_name_toks)}"

    def get_name(self):
        return f'inline func {self.var_name_tok.var_name_tok.value}/{self.arity}'


class CallNode(Node):
    def __init__(self, node_to_call: VarAccessNode, arg_nodes, keywords: Union[Dict, None]):
        self.node_to_call = node_to_call
        self.arg_nodes = arg_nodes
        self.keywords = keywords
        self.arity = len(arg_nodes)
        self.pos_start = self.node_to_call.pos_start
        self.local_call = False

        if len(self.arg_nodes) > 0:
            self.pos_end = self.arg_nodes[len(self.arg_nodes) - 1].pos_end
        else:
            self.pos_end = self.node_to_call.pos_end

    def set_to_local_call(self):
        self.local_call = True

    def get_name(self):
        return f'{self.node_to_call.var_name_tok.value}/{self.arity}'

    def __repr__(self):
        return f"call: {self.get_name()}"


class ReturnNode(Node):
    def __init__(self, node_to_return, pos_start, pos_end):
        self.node_to_return = node_to_return

        self.pos_start = pos_start
        self.pos_end = pos_end


class PipeNode(Node):
    def __init__(self, left_node, right_node, pos_start, pos_end):
        self.left_node = left_node
        self.right_node = right_node
        self.pos_start = pos_start
        self.pos_end = pos_end

    def __repr__(self):
        return f"{self.left_node} |> {self.right_node}"


class MapNode(Node):
    def __init__(self, pairs_list: List[Tuple["AnyNode", "AnyNode"]], pos_start, pos_end):
        self.pairs_list = pairs_list
        self.pos_start = pos_start
        self.pos_end = pos_end

    def __repr__(self):
        return "{map}"


class ImportNode(Node):
    def __init__(self,
         modules_import: Union[None, List[Dict[str, Union[int, str, None]]]],
         functions_import: Union[None, List[Dict[str, Union[int, str, None]]]],
         pos_start,
         pos_end,
    ):
        # {"arity": arity or None, "name": to_import_name, "alias": alias}

        assert (modules_import is None and functions_import) or \
               (modules_import and functions_import is None)

        self.modules_import = modules_import
        self.functions_import = functions_import
        self.pos_start = pos_start
        self.pos_end = pos_end

    def get_imported_names(self):
        if self.modules_import:
            return [i['name'] for i in self.modules_import]

        return [
            f"{i['names']}/{i['arity']}" for i in self.functions_import
        ]


class CaseNode(Node):
    def __init__(self, expr: Union[None, Node], cases: List[Tuple[Node, Node]], pos_start, pos_end,):
        self.expr = expr
        self.cases = cases
        self.pos_start = pos_start
        self.pos_end = pos_end

    def __repr__(self):
        return f"case {str(self.expr)} do: {len(self.cases)} cases"


class RaiseNode(Node):
    def __init__(self, expr, pos_start, pos_end,):
        self.expr = expr
        self.pos_start = pos_start
        self.pos_end = pos_end

    def __repr__(self):
        return f"raise : {self.expr()}"


class InNode(Node):
    def __init__(self, left_expr, right_expr, pos_start, pos_end,):
        self.left_expr = left_expr
        self.right_expr = right_expr
        self.pos_start = pos_start
        self.pos_end = pos_end

    def __repr__(self):
        return f"raise : {self.expr()}"