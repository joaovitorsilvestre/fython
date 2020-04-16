from fython.core.parser.pos_parser.errors import UndefinedFunction
from fython.core.parser.pos_parser.result_integrity import InterityResult
from fython.core.parser import ImportNode, FuncDefNode, CallNode, StatementsNode


class PosParser:
    def __init__(self, node: StatementsNode):
        self.node = node

        self.functions = [
            i for i in self.node.statement_nodes if isinstance(i, FuncDefNode)
        ]

    def validate(self):
        res = InterityResult(self.node)

        for func in self.functions:
            res.register(self.integrity_FuncDefNode(func))

        return res

    def is_this_function_avaliable_in_this_context(
        self, func_call: CallNode, function_context: FuncDefNode
    ):
        local_imports = [
            i for i in function_context.body_node.statement_nodes
            if isinstance(i, ImportNode)
        ]
        global_imports = [
            i for i in self.node.statement_nodes
            if isinstance(i, ImportNode)
        ]

        local_imported = [
            i.get_name() for i in sum([imp.imports_list for imp in local_imports], [])
        ]

        global_imported =  [
            i.get_name() for i in sum([imp.imports_list for imp in global_imports], [])
        ]

        if func_call.get_name() in local_imported + global_imported:
            return True
        else:
            # lets finds for this function in the global imported without
            # specific functions. eg: import Main
            # TODO this is more complex. We neet to check if any of the
            # TODO imported modules has any function defined considering arity
            return True

    def integrity_FuncDefNode(self, function: FuncDefNode):
        res = InterityResult(self.node)

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

