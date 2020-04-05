from pprint import pprint
from typing import Union, List

from fython.lexer import tokenize_string, Token

simple_string = "if 3 + 2 == 3:\n" \
                "    a = 5"

tokenized = tokenize_string(simple_string)

pprint(tokenized)


class BlockIdent:
    def __init__(self, ident_value=None, tokens:List[Token]=None):
        if ident_value is None or tokens is None:
            raise "Missing params"

        self.ident_value = ident_value
        self.tokens = tokens

    def __repr__(self):
        return f"BLockIdent(ident_value={self.ident_value}, tokens={len(self.tokens)})"


class Node:
    def __init__(self, type:str=None, value:str=None, child: List=None):
        if type is None or value is None or child is None:
            raise "missing params"

        self.type = type
        self.value = value
        self.child = child

    def __repr__(self):
        return f"Node(type={self.type})"


################# MERGE PARENTESES BLOCKS #####################3
# To accomplish that, we're gonna remove ay identity between parentences pair

def find_parenteses_pairs_in_list_of_tokens(tokens):
    lpar_list = []
    rpar_list = []
    for token in tokens:
        if token.type == 'lpar':
            lpar_list.append(token)
        elif token.type == 'rpar':
            rpar_list.append(token)

    if len(lpar_list) != len(rpar_list):
        raise "parenteses missing start or end"

    return lpar_list, rpar_list[::-1]


def merge_parenteses_blocks(tokenized: List[Token]):
    idents_to_remove = []

    lpar_list, rpar_list = find_parenteses_pairs_in_list_of_tokens(tokenized)

    for lpar, rpar in zip(lpar_list, rpar_list):
        lpar_index, rpar_index = tokenized.index(lpar), tokenized.index(rpar)

        for token in tokenized[lpar_index+1:rpar_index]:
            if token.type == 'ident':
                idents_to_remove.append(token)

    return [i for i in tokenized if i not in idents_to_remove]


tokenized = merge_parenteses_blocks(tokenized)


################# CREATE IDENTY BLOCKS #####################3


def separate_tokens_in_ident_blocks(tokenized: List[Token]):
    blocks = []

    # create blocks for lines
    for i, token in enumerate(tokenized):
        if token.type == 'ident':
            next_block = next((i for i in tokenized[i+1:] if i.type == 'ident'), None)

            if next_block:
                next_block_index = tokenized.index(next_block)
                this_block = tokenized[i+1:next_block_index]
            else:
                this_block = tokenized[i+1:]

            blocks.append(BlockIdent(ident_value=token.value, tokens=this_block))

    return blocks

blocks = separate_tokens_in_ident_blocks(tokenized)

#################  PARSE EACH BLOCK #####################3

# ((2 - 1) + 3) == 3
# equals
#    sum
#        subtract
#           number (2)
#           number (1)
#        number (3)
#    number (3)
def create_node_fo_tokens(tokens: List):
    if any(i for i in tokens if i.type in ['equals', '+']):
        precedence = ['equals', '+']

        this_token_type = next(
            op for op in precedence if next((t for t in tokens if t.type == op), None)
        )

        this_token = next(i for i in tokens if i.type == this_token_type)
        index = tokens.index(this_token)

        return Node(
            type=this_token.type,
            value=this_token.value,
            child=[
                create_node_fo_tokens(tokens[0:index]),
                create_node_fo_tokens(tokens[index+1:])
            ]
        )

    if len(tokens) == 1:
        return Node(
            type=tokens[0].type,
            value=tokens[0].value,
            child=[]
        )


def create_tree_for_block(block: BlockIdent):
    if block.tokens[0].type == 'if':
        # if block
        assert block.tokens[-1].type == 'do', "If block must end with :"

        return Node(
            type=block.tokens[0].type,
            value=block.tokens[0].value,
            child=[create_node_fo_tokens(block.tokens[1:-1])],
        )
    elif block.tokens[0].type == 'name' and block.tokens[1].type == 'assign':
        # assign variable block

        return Node(
            type=block.tokens[1].type,
            value=block.tokens[1].value,
            child=[
                Node(
                    type=block.tokens[0].type,
                    value=block.tokens[0].value,
                    child=[]
                ),
                create_node_fo_tokens(block.tokens[2:])
            ],
        )


def pprint_tree(node, file=None, _prefix="", _last=True):

    if node.type in ['number']:
        print(_prefix, "|_ " if _last else "|_ ", f'{node.type} ({node.value})', sep="", file=file)
    else:
        print(_prefix, "|_ " if _last else "|_ ", node.type, sep="", file=file)

    _prefix += "    " if _last else "|  "
    child_count = len(node.child)
    for i, child in enumerate(node.child):
        _last = i == (child_count - 1)
        pprint_tree(child, file, _prefix, _last)

for b in blocks:
    pprint_tree(create_tree_for_block(b))