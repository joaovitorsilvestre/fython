from typing import List

from fython.core.parser.pos_parser.errors import UndefinedFunction
from fython.core.parser.pos_parser.pos_parser_result import PosParserResult
from fython.core.parser import ImportNode, FuncDefNode, CallNode, StatementsNode, VarAssignNode


class PosParser:
    def __init__(self, node: StatementsNode):
        self.node = node

        self.functions = [
            i for i in self.node.statement_nodes if isinstance(i, FuncDefNode)
        ]

    def validate(self):
        res = PosParserResult(self.node)

        for func in self.functions:
            res.register(self.integrity_FuncDefNode(func))
            if res.error:
                return res

            res.register(self.ensure_local_call_nodes(func))
            if res.error:
                return res

        return res

    def is_this_function_avaliable_in_this_context(
        self, func_call: CallNode, function_context: FuncDefNode
    ):
        global_imported = sum([
            i.get_imported_names() for i in self.node.statement_nodes
            if isinstance(i, ImportNode)
        ], [])

        local_imported = function_context.get_defined_variables()

        if func_call.get_name() in local_imported + global_imported:
            return True
        else:
            # lets finds for this function in the global imported without
            # specific functions. eg: import Main
            # TODO this is more complex. We neet to check if any of the
            # TODO imported modules has any function defined considering arity
            return True

    def integrity_FuncDefNode(self, function: FuncDefNode):
        res = PosParserResult(self.node)

        # 1º Search for undefined functions

        # todo check funcitons defined inside function

        func_calls = [
            i for i in function.body_node.statement_nodes if isinstance(i, CallNode)
        ]

        # is function imported?
        for fc in func_calls:
            if not self.is_this_function_avaliable_in_this_context(fc, function):
                return res.failure(UndefinedFunction(
                    fc.pos_start.copy(), fc.pos_end.copy(),
                    f"{fc.get_name()}"
                ))

        return res.success(self.node)

    def ensure_local_call_nodes(self, func: FuncDefNode):
        # This function has a important job
        # Check if the function that is being called was defined inside this function or received by parameters
        # if this function is local the syntax in elixir is different, therefore is ast
        # e.g in elixir local call:  func_local.()   << notice the dot

        res = PosParserResult(self.node)

        func_calls = [
            i for i in func.body_node.get_all_child_nodes_flatten() if isinstance(i, CallNode)
        ]

        for func_call in func_calls:
            if func_call.node_to_call.var_name_tok.value in func.get_defined_variables():
                func_call.set_to_local_call()

        return res
