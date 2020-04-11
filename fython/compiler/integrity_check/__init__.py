from fython.compiler.integrity_check.errors import UndefinedFunction
from fython.compiler.integrity_check.result_integrity import InterityResult
from fython.core.parser import ImportNode, FuncDefNode, CallNode, ParseResult, StatementsNode


class IntegrityChecks:
    def __init__(self, node: StatementsNode):
        self.node = node

        self.import_statements = [
            i for i in self.node.statement_nodes if isinstance(i, ImportNode)
        ]
        self.functions = [
            i for i in self.node.statement_nodes if isinstance(i, FuncDefNode)
        ]

    def validate(self):
        res = InterityResult(self.node)

        for func in self.functions:
            res.register(self.integrity_FuncDefNode(func))

        return res

    def imported_functions(self):
        return [i.alias or i.name for i in sum([imp.imports_list for imp in self.import_statements], [])]

    def integrity_FuncDefNode(self, func: FuncDefNode):
        res = InterityResult(self.node)

        # 1º Search for undefined functions

        # todo check funcitons defined inside function

        func_calls = [
            i for i in func.body_node.statement_nodes if isinstance(i, CallNode)
        ]

        # is function imported?
        for func in func_calls:
            func_name = func.node_to_call.var_name_tok.value

            if not func_name in self.imported_functions():
                return res.failure(UndefinedFunction(
                    func.pos_start.copy(), func.pos_end.copy(),
                    f"{func_name}"
                ))

        return res.success(self.node)

