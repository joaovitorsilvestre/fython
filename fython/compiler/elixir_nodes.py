import re

from fython.core.lexer.tokens import TT_POW, TT_PLUS, TT_MINUS, TT_MUL, TT_DIV, TT_LTE, TT_LT, TT_GTE, TT_GT, TT_EE, \
    TT_KEYWORD, TT_NE
from fython.core.parser import NumberNode, ListNode, BinOpNode, \
    UnaryOpNode, VarAccessNode, VarAssignNode, StatementsNode, IfNode, FuncDefNode, CallNode, StringNode, PipeNode, \
    MapNode, AtomNode, ImportNode, LambdaNode, CaseNode, FuncAsVariableNode, InNode, RaiseNode


class ElixirAST:
    def __add__(self, other):
        return str(self) + other

    def __radd__(self, other):
        return other + str(self)

    def __str__(self):
        return self.__repr__()


class Line(ElixirAST):
    def __init__(self, value):
        self.value = str(value)

    def __str__(self):
        return self.__repr__()

    def __repr__(self):
        return "[line: " + self.value + "]"


class EModule(ElixirAST):
    def __init__(self, module_name, node: ListNode):
        self.module_name = module_name[0].upper() + module_name[1:]
        self.node = node
        self.line = Line(1)

    def alias(self):
        return "{:__aliases__, " + self.line + ", [:" + self.module_name + "]}"

    def __repr__(self):
        # return str(Conversor().convert(self.node))
        return "{:defmodule, [line: 1],\
         [\
           {:__aliases__, [line: 1],\
            [:" + self.module_name + "]},\
           [\
             do: " + Conversor().convert(self.node) + "\
           ]\
         ]}"


class Conversor:
    def convert(self, node) -> ElixirAST:
        conver_func = f"convert_{type(node).__name__}"

        return getattr(self, conver_func, self.invalid_node)(node)

    @staticmethod
    def pairwise(it):
        it = iter(it)
        while True:
            yield next(it), next(it, None)

    def invalid_node(self, node):
        raise Exception(f"No conversor for node type: {type(node).__name__}")

    def convert_NumberNode(self, node: NumberNode):
        return str(node.tok.value)

    def convert_AtomNode(self, node: AtomNode):
        return ':' + node.tok.value

    def convert_StatementsNode(self, node: StatementsNode):
        line = Line(node.pos_start.ln)
        content = [Conversor().convert(i) for i in node.statement_nodes]

        if len(content) == 1:
            return str(content[0])

        return "{:__block__, " + line + ",\
         [" + ', '.join(content) + "]}"

    def convert_ListNode(self, node: ListNode):
        return "[" + ", ".join(self.convert(i) for i in node.element_nodes) + "]"

    def convert_VarAssignNode(self, node: VarAssignNode):
        # probably the pattern match core is here
        return "{:=, [], [{:" + node.var_name_tok.value + ", [], Elixir}" \
                ", " + self.convert(node.value_node) + "]}"

    def convert_IfNode(self, node: IfNode):
        comp_expr = self.convert(node.comp_expr)
        true_case = self.convert(node.true_case)
        false_case = self.convert(node.false_case)

        return "{:if, [context: Elixir, import: Kernel], " \
               "[" + comp_expr + ", [do: " + true_case + ", else: " + false_case + "]]}"

    def convert_VarAccessNode(self, node: VarAccessNode):
        if node.var_name_tok.value == 'False':
            return "false"
        elif node.var_name_tok.value == 'True':
            return "true"
        elif node.var_name_tok.value == 'None':
            return "nil"

        return "{:" + node.var_name_tok.value + ", [], Elixir}"

    def convert_UnaryOpNode(self, node: UnaryOpNode):
        value = self.convert(node.node)

        if node.op_tok.matches(TT_KEYWORD, 'not'):
            return "{:__block__, [], [{:!, [context: Elixir, import: Kernel], [" + value + "]}]}"
        else:
            op = ({TT_PLUS: '+', TT_MINUS: '-'})[node.op_tok.type]
            return "{:" + op + ", [context: Elixir, import: Kernel], [" + value + "]}"

    def convert_BinOpNode(self, node: BinOpNode):
        a, b = self.convert(node.left_node), self.convert(node.right_node)

        simple_ops = {
            TT_PLUS: '+', TT_MINUS: '-', TT_MUL: '*', TT_DIV: '/',
            TT_GT: '>', TT_GTE: '>=', TT_LT: '<', TT_LTE: '<=',
            TT_EE: '==', TT_NE: '!='
        }

        if node.op_tok.type in simple_ops:
            op = simple_ops[node.op_tok.type]
            return "{:" + op + ", [context: Elixir, import: Kernel], [" + a + ", " + b + "]}"
        elif node.op_tok.type == TT_POW:
            return "{{:., [], [:math, :pow]}, [], [" + a + ", " + b + "]}"
        elif node.op_tok.matches(TT_KEYWORD, 'or'):
            return "{:or, [context: Elixir, import: Kernel], [" + a + ", " + b + "]}"
        elif node.op_tok.matches(TT_KEYWORD, 'and'):
            return "{:and, [context: Elixir, import: Kernel], [" + a + ", " + b + "]}"
        else:
            raise Exception(f"Invalid BinOpType: {node.op_tok.type}")

    def convert_FuncDefNode(self, node: FuncDefNode):
        name = node.var_name_tok.value
        statements_node = node.body_node
        line = Line(node.pos_start.ln)
        arguments = ["{:" + i.value + ", [], Elixir}" for i in node.arg_name_toks]

        return "{:def, " + line + ",\
         [\
           {:" + name +", " + line + ", [" + ', '.join(arguments) + "]},\
           [do: " + self.convert(statements_node) + "]\
         ]}"

    def convert_LambdaNode(self, node: LambdaNode):
        params = []
        for p in node.arg_name_toks:
            params.append("{:"+p.value+", [context: Elixir, import: IEx.Helpers], Elixir}")

        params = "[" + ','.join(params) + "]"

        return "{:fn, [],\
                 [\
                   {:->, [],\
                    [\
                      " + params + ",\
                      " + self.convert(node.body_node) + "\
                    ]}\
                 ]}"

    def convert_CallNode(self, node: CallNode):
        args = [self.convert(i) for i in node.arg_nodes]
        keywords = [f"[{k}: {self.convert(v)}]" for k, v in node.keywords.items()]

        arguments = "[" + ', '.join([*args, *keywords]) + "]"

        if node.local_call:
            return "{{:., [], [{:" + node.node_to_call.var_name_tok.value + ", [], Elixir}]}, [], " + arguments + "}"
        elif '.' in node.get_name():
            *modules, func_name = node.get_name().split('.')
            func_name, _ = func_name.split('/')

            modules = "[" + ', '.join([':' + i for i in modules]) + "]"

            return "{{:., [], [{:__aliases__, [alias: false], " + modules + "}, :"+func_name+"]}, [], " + arguments + "}"
        else:
            return "{:" + node.node_to_call.var_name_tok.value + ", [], " + arguments + "}"

    def convert_StringNode(self, node: StringNode):
        import json
        return json.dumps(node.tok.value)

    def convert_PipeNode(self, node: PipeNode):
        assert not isinstance(node.left_node, PipeNode), "" \
         "This function must resolve all children pipe nodes. Its not suppose to run recursively"

        def build_one_pipe(left_node, right_node):
            left_node = self.convert(left_node)
            right_node = self.convert(right_node)
            return "{:|>, [context: Elixir, import: Kernel], ["+left_node+", "+right_node+"]}"

        if not isinstance(node.right_node, PipeNode):
            return build_one_pipe(node.left_node, node.right_node)
        else:
            nodes_order = [node.left_node]

            current_node = node.right_node
            while isinstance(current_node, PipeNode):
                nodes_order = [*nodes_order, current_node.left_node]
                current_node = current_node.right_node

            if not isinstance(current_node, PipeNode):
                nodes_order = [*nodes_order, current_node]

            last = None
            for left, right in Conversor.pairwise(nodes_order):
                if last is None:
                    last = build_one_pipe(left, right)
                else:
                    left = self.convert(left)
                    last = "{:|>, [context: Elixir, import: Kernel], [" + last + ", " + left + "]}"
                    if right:
                        right = self.convert(right)
                        last = "{:|>, [context: Elixir, import: Kernel], [" + last + ", " + right + "]}"


            return last

    def convert_MapNode(self, node: MapNode):
        values = []

        for k, v in node.pairs_list:
            values.append("{" + self.convert(k) + ", " +  self.convert(v) + "}")

        return "{:%{}, [], [" + ', '.join(values) + "]}"

    def convert_ImportNode(self, node: ImportNode):
        if node.modules_import:
            import_commands = []

            for imp in node.modules_import:
                if imp.get('alias'):
                    import_commands.append(
                        "{:import, [context: Elixir],\
                        [\
                          {:__aliases__, [alias: false], [:" + imp['name'] + "]},\
                          [as: {:__aliases__, [alias: false], [:" + imp['alias'] + "]}]\
                        ]}"
                    )
                else:
                    import_commands.append(
                        "{:import, [context: Elixir], [{:__aliases__, [alias: false], [:" + imp['name'] + "]}]}"
                    )
            return "{:__block__, [], [" + ', '.join(import_commands) + "]}"
        else:
            raise NotImplemented()

        # if node.type == 'import':
        #     for imp in node.imports_list:
        #         if imp.alias:
        #             import_commands.append(
        #                 "{:import, [context: Elixir],\
        #                 [\
        #                   {:__aliases__, [alias: false], [:" + imp.name + "]},\
        #                   [as: {:__aliases__, [alias: false], [:" + imp.alias + "]}]\
        #                 ]}"
        #             )
        #         else:
        #             import_commands.append(
        #                 "{:import, [context: Elixir], [{:__aliases__, [alias: false], [:" + imp.name + "]}]}"
        #             )
        # elif node.type == 'from':
        #     for imp in node.imports_list:
        #         if imp.alias:
        #             raise Exception('no suported')
        #         elif '.' not in imp.from_:
        #             import_commands.append(
        #                 "{:import, [context: Elixir],\
        #                  [{:__aliases__, [alias: false], [:"+imp.from_+"]}, [only: ["+ imp.name +": "+str(imp.arity)+"]]]}\
        #                "
        #            )
        # else:
        #     raise "Should not get here"
        #
        # if len(import_commands) == 1:
        #     return import_commands[0]
        #
        # return "{:__block__, [], [" + ''.join(import_commands) + "]}"

    def convert_CaseNode(self, node: CaseNode):
        if node.expr is not None:
            expr = self.convert(node.expr)
        else:
            expr = None

        arguments = [
            "{:->, [], [[" + self.convert(left) + "], " + self.convert(right) + "]}"
            for left, right in node.cases
        ]

        arguments = ", ".join(arguments)

        if expr:
            return "{:case, [], [" + expr + ", [do: [" + arguments + "]]]}"
        else:
            return "{:cond, [], [[do: [" + arguments + "]]]}"

    def convert_FuncAsVariableNode(self, node: FuncAsVariableNode):
        name = node.var_name_tok.value
        arity = str(node.arity)
        return "{:&, [], [{:/, [context: Elixir, import: Kernel], [{:"+name+", [], Elixir}, "+arity+"]}]}"

    def convert_InNode(self, node: InNode):
        left = self.convert(node.left_expr)
        right = self.convert(node.right_expr)
        return "{:in, [context: Elixir, import: Kernel], [" + left + ", " + right + "]}"

    def convert_RaiseNode(self, node: RaiseNode):
        expr = self.convert(node.expr)
        return "{:raise, [context: Elixir, import: Kernel], [" + expr + "]}"
