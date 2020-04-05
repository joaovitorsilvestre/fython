from pprint import pprint
import re

todos = {
    "name": re.compile("[a-zA-Z_][a-zA-Z0-9_]*"),
    "ident": re.compile("^    "),
    "assign": re.compile("(?<!\=)=(?!\=)"),  # this will not match ==
    "equals": re.compile("\=\="),
    "number": re.compile("[0-9]+"),
    "lpar": re.compile("\("),
    "rpar": re.compile("\)"),
    "lbra": re.compile("\["),
    "rbra": re.compile("\]"),
    "lcurly": re.compile("\{"),
    "rcurly": re.compile("\}"),
    "comment": re.compile("#"),
    "+": re.compile("\+"),
    "-": re.compile("-"),
    "/": re.compile("\/"),
    "*": re.compile("\*"),
}

class Token:
    def __init__(self, type=None, value=None, index=None):
        if type is None or value is None or index is None:
            raise "Missing params"

        self.type=type
        self.value=value
        self.index=index

    def __repr__(self):
        return f"Token(type={self.type}, value={self.value}, index={self.index})"


def tokenize(text):
    result = []

    for token_name, regex in todos.items():
        for m in regex.finditer(text):
            m.start(), m.group()

            result += [
                Token(type=token_name, value=m.group(), index=m.start())
            ]

    # sort tokens by thery index
    result = sorted(result, key=lambda x: x.index)

    # fix indexes
    tokens_merged = [Token(index=index, value=i.value, type=i.type) for index, i in enumerate(result)]

    # remove any token after comment
    comment = next((i for i in tokens_merged if i.type == "comment"), None)

    if comment:
        index = tokens_merged.index(comment)
        tokens_merged = tokens_merged[0:index]

    # dont considear keywords as variable
    keyworkds = ['if', 'else']

    tokens_merged = [i for i in tokens_merged if not (i.type == 'name' and i.value in keyworkds)]

    # convert value of ident tokens form a string '    ' to int 4
    tokens_merged = [
        Token(index=i.index, value=len(i.value) if i.type=='ident' else i.value, type=i.type) for i in tokens_merged
    ]

    return tokens_merged


def tokenize_string(string):
    tokenized_lines = [tokenize(i) for i in string.split("\n")]

    initial_ident = Token(type='ident', value=0, index=0)

    # ad a ident token to first line
    tokenized_lines[0] = [initial_ident] + [
        Token(type=i.type, value=i.value, index=i.index+1) for i in tokenized_lines[0]
    ]

    return sum(tokenized_lines, [])


if __name__ == '__main__':
    env = {}
    lex = tokenize("123")

    lines = "a = (1 + (3 +3))"

    tokenized_lines = [tokenize(i) for i in lines.split("\n")]

    pprint(tokenized_lines)

    #while True:
    #    try:
    #        text = input('fython > ')
    #    except EOFError:
    #        break

    #    if text:
    #        lex = tokenize(text)
    #        pprint(lex)

