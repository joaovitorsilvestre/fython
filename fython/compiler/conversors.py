from fython.core.parser.nodes import FuncDefNode, ReturnNode, NumberNode


def convert(node):
    if type(node) == FuncDefNode:
        return convert_def_func(node)
    elif type(node) == ReturnNode:
        return convert_return(node)
    elif type(node) == NumberNode:
        return convert_number(node)

    raise f"Not suported node type {type(node)}"


def convert_def_func(node: FuncDefNode):
    func_name = node.var_name_tok.value
    line = str(node.pos_start.ln)

    if len(node.body_node.element_nodes) == 0:
        content = "[]"
    else:
        content = ''.join(convert(i) for i in node.body_node.element_nodes)

    return "do: {:def, [line: " + line + " ], \n  \
      [                           \n  \
        {:" + func_name + ", [line: 2], []}, \n  \
        [do: " + content + "] \n \
      ]}"


def convert_return(node: ReturnNode):
    line = str(node.pos_start.ln)
    to_return = node.node_to_return

    return "[do: " + convert(to_return) +  "]"


def convert_number(node: NumberNode):
    return str(node.tok.value)