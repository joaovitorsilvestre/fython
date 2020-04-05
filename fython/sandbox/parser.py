from collections import namedtuple
from itertools import filterfalse, tee
from pprint import pprint
from typing import Union, List

from fython.lexer import tokenize_string, Token

simple_string = "if 3+2 == 3:\n" \
                "    a = 5"

tokenized = tokenize_string(simple_string)

pprint(tokenized)

BlockIdent = namedtuple("BlockIdent", ["ident_value", "tokens"])


def separate_tokens_in_ident_blocks(tokens):
    blocks = []

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

print("parse one block")

Node = namedtuple('Node', ['type', 'value', 'child'])


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