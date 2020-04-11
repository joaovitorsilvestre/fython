from fython.compiler.integrity_check.errors import UndefinedFunction
from fython.compiler.integrity_check.result_integrity import InterityResult
from fython.core.parser import ImportNode, FuncDefNode, CallNode, ParseResult, StatementsNode


class IntegrityChecks:
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

    def avaliable_functons_in_context(self, function: FuncDefNode):
        local_imports = [
            i for i in function.body_node.statement_nodes if isinstance(i, ImportNode)
        ]
        global_imports = [
            i for i in self.node.statement_nodes if isinstance(i, ImportNode)
        ]

        local_imported = [
            i.alias or i.name for i in sum([imp.imports_list for imp in local_imports], [])
        ]

        global_imported =  [
            i.alias or i.name for i in sum([imp.imports_list for imp in global_imports], [])
        ]

        return local_imported + global_imported

    def integrity_FuncDefNode(self, function: FuncDefNode):
        res = InterityResult(self.node)

        # 1º Search for undefined functions

        # todo check funcitons defined inside function

        func_calls = [
            i for i in function.body_node.statement_nodes if isinstance(i, CallNode)
        ]

        # is function imported?
        for func_call in func_calls:
            func_name = func_call.node_to_call.var_name_tok.value

            if not func_name in self.avaliable_functons_in_context(function):
                return res.failure(UndefinedFunction(
                    func_call.pos_start.copy(), func_call.pos_end.copy(),
                    f"{func_name}"
                ))

        return res.success(self.node)

