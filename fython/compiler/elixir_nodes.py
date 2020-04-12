from fython.core.lexer.tokens import TT_POW, TT_PLUS, TT_MINUS, TT_MUL, TT_DIV, TT_LTE, TT_LT, TT_GTE, TT_GT, TT_EE, \
    TT_KEYWORD
from fython.core.parser import NumberNode, ListNode, BinOpNode, \
    UnaryOpNode, VarAccessNode, VarAssignNode, StatementsNode, IfNode, FuncDefNode, CallNode, StringNode, PipeNode, \
    MapNode, AtomNode, ImportNode


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
            TT_EE: '==',
        }

        if node.op_tok.type in simple_ops:
            op = simple_ops[node.op_tok.type]
            return "{:" + op + ", [context: Elixir, import: Kernel], [" + a + ", " + b + "]}"
        elif node.op_tok.type == TT_POW:
            return "{{:., [], [:math, :pow]}, [], [" + a + ", " + b + "]}"
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

    def convert_CallNode(self, node: CallNode):
        arguments = "[" + ','.join([self.convert(i) for i in node.arg_nodes]) + ']'

        if '.' in node.get_name():
            module, func_name = node.get_name().split('.')
            func_name, _ = func_name.split('/')
            return "{{:., [], [{:__aliases__, [alias: false], [:"+module+"]}, :"+func_name+"]}, [], " + arguments + "}"
        else:
            return "{:" + node.node_to_call.var_name_tok.value + ", [], " + arguments + "}"

    def convert_StringNode(self, node: StringNode):
        return f'"{node.tok.value}"'

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
                nodes_order = [*nodes_order, current_node.left_node, current_node.right_node]
                current_node = current_node.right_node

            last = None
            for left, right in Conversor.pairwise(nodes_order):
                if right is not None:
                    last = build_one_pipe(left, right)
                else:
                    last_one = self.convert(left)
                    last = "{:|>, [context: Elixir, import: Kernel], [" + last + ", " + last_one + "]}"

            return last

    def convert_MapNode(self, node: MapNode):
        values = []

        for k, v in node.pairs_list:
            values.append("{" + self.convert(k) + ", " +  self.convert(v) + "}")

        return "{:%{}, [], [" + ', '.join(values) + "]}"

    def convert_ImportNode(self, node: ImportNode):
        import_commands = []

        if node.type == 'import':
            for imp in node.imports_list:
                if imp.alias:
                    import_commands.append(
                        "{:import, [context: Elixir],\
                        [\
                          {:__aliases__, [alias: false], [:" + imp.name + "]},\
                          [as: {:__aliases__, [alias: false], [:Oi]}]\
                        ]}"
                    )
                else:
                    import_commands.append(
                        "{:import, [context: Elixir], [{:__aliases__, [alias: false], [:" + imp.name + "]}]}"
                    )
        elif node.type == 'from':
            for imp in node.imports_list:
                if imp.alias:
                    continue
                else:
                    import_commands.append(
                        "{:import, [context: Elixir],\
                         [{:__aliases__, [alias: false], [:"+imp.from_+"]}, [only: ["+ imp.name +": "+str(imp.arity)+"]]]}\
                       "
                   )
        else:
            raise "Should not get here"

        if len(import_commands) == 1:
            return import_commands[0]

        return "{:__block__, [], [" + ''.join(import_commands) + "]}"
