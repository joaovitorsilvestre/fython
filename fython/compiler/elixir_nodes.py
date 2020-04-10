from fython.core.parser import NumberNode, ListNode, FuncDefNode


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
        formated_statements = Conversor().convert(self.node)

        if len(self.node.element_nodes) == 0:
            return "{:defmodule, " + self.line + ", \
             [" + self.alias() + ", \
               [do: {:__block__, [], []}] \
             ]}"
        else:
            return "{:defmodule, " + self.line + ", \
             [" + self.alias() + ", \
               [do: {:__block__, [], []}] \
             ]}"


class EList(ElixirAST):
    def __init__(self, nodes):
        self.nodes = nodes
        self.content = None
        self.parse_content()

    def parse_content(self):
        self.content = [Conversor().convert(i) for i in self.nodes]

    def __repr__(self):
        if len(self.content) == 1:
            return str(self.content[0])
        else:
            return "[\n" + ",\n".join(map(str, self.content)) + "\n]"


class EFuncDef(ElixirAST):
    def __init__(self, node: FuncDefNode):
        self.func_name = node.var_name_tok.value
        self.list_node = node.body_node
        self.content = None
        self.line = Line(node.pos_start.ln)
        self.parse_content()

    def parse_content(self):
        self.content = Conversor().convert(self.list_node)

    def __repr__(self):
        return "do: {:def, " + self.line + ", \n  \
          [                           \n  \
            {:" + self.func_name + ", " + self.line + ", []}, \n  \
            [do: " + self.content + "] \n \
          ]}"


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

    def convert_FuncDefNode(self, node: FuncDefNode):
        return EFuncDef(node)

    def convert_ListNode(self, node: ListNode):
        return EList(node.element_nodes)