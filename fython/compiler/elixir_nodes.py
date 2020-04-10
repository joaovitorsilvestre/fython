from fython.core.lexer.tokens import TT_POW, TT_PLUS, TT_MINUS, TT_MUL, TT_DIV
from fython.core.parser import NumberNode, ListNode, BinOpNode, \
    UnaryOpNode, VarAccessNode, VarAssignNode


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
        return str(Conversor().convert(self.node))


class EList(ElixirAST):
    def __init__(self, node: ListNode):
        self.nodes = node.element_nodes
        self.content = None
        self.parse_content()

    def parse_content(self):
        self.content = [Conversor().convert(i) for i in self.nodes]

    def __repr__(self):
        if len(self.nodes) == 1:
            return str(self.content[0])

        return "{:__block__, [],\
         [" + ', '.join(self.content) + "]}"


class ENumber(ElixirAST):
    def __init__(self, value):
        self.value = value

    def __repr__(self):
        return str(self.value)


class Conversor:
    def convert(self, node) -> ElixirAST:
        conver_func = f"convert_{type(node).__name__}"

        return getattr(self, conver_func, self.invalid_node)(node)

    def invalid_node(self, node):
        raise Exception(f"No conversor for node type: {type(node).__name__}")

    def convert_NumberNode(self, node: NumberNode):
        return ENumber(node.tok.value)

    def convert_ListNode(self, node: ListNode):
        return EList(node)

    def convert_VarAssignNode(self, node: VarAssignNode):
        # probably the pattern match core is here
        return "{:=, [], [{:" + node.var_name_tok.value + ", [], Elixir}" \
                ", " + self.convert(node.value_node) + "]}"

    def convert_VarAccessNode(self, node: VarAccessNode):
        return "{:" + node.var_name_tok.value + ", [], Elixir}"

    def convert_UnaryOpNode(self, node: UnaryOpNode):
        value = self.convert(node.node)
        op = ({TT_PLUS: '+', TT_MINUS: '-'})[node.op_tok.type]
        return "{:" + op + ", [context: Elixir, import: Kernel], [" + value + "]}"

    def convert_BinOpNode(self, node: BinOpNode):
        a, b = self.convert(node.left_node), self.convert(node.right_node)

        math_ops = ({TT_PLUS: '+', TT_MINUS: '-', TT_MUL: '*', TT_DIV: '/'})

        if node.op_tok.type in math_ops:
            op = math_ops[node.op_tok.type]
            return "{:" + op + ", [context: Elixir, import: Kernel], [" + a + ", " + b + "]}"
        elif node.op_tok.type == TT_POW:
            return "{{:., [], [:math, :pow]}, [], [" + a + ", " + b + "]}"
        else:
            raise Exception(f"Invalid BinOpType: {node.op_tok.type}")