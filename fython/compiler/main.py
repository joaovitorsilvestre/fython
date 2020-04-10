import os

from fython.compiler.conversors import convert
from fython.core.parser.nodes import FuncDefNode, ListNode


class File:
    def __init__(self, name, parent, full_path):
        self.name = name.replace('.fy', '').strip()
        self.parent = parent
        self.full_path = full_path
        with open(full_path, 'r') as f:
            self.content = f.read()

    def __repr__(self):
        return f"File: {self.full_path}"

    def compile(self):
        from fython.core import lex_and_parse

        ast, error = lex_and_parse(self.name, self.content)
        print(ast, error)

        if error:
            return

        # create main defmodule
        return self.create_module(self.name, ast)

    def create_module(self, module_name, statements):
        return "{:defmodule, [line: 1], \n\
            [{:__aliases__, [line: 1], \n\
            [:" + module_name + "]}, " + self.parse_statements(statements) + "]}"

    def parse_statements(self, statements: ListNode):
        sts = []

        for st in statements.element_nodes:
            assert type(st) == FuncDefNode
            sts.append(convert(st))

        return f"[{''.join(sts)}]"


class Compiler:
    def __init__(self, folder):
        self.folder = folder
        self.project_structured = {
            "name": self.folder.split('/')[-1],
            "files": []
        }

    def read_project(self):
        for root, subdirs, files in os.walk(self.folder):
            # print('--\nroot = ' + root)

            for subdir in subdirs:
                pass
                # print('\t- subdirectory ' + subdir)

            for filename in files:
                file_path = os.path.join(root, filename)

                self.project_structured['files'].append(
                    File(filename, None, file_path)
                )

    def compile(self):
        self.read_project()
        for file in self.project_structured['files']:
            compiled_file = file.compile()
            print(f'result of file: {file}')
            print(compiled_file)


if __name__ == '__main__':
    c = Compiler('example_project')
    c.compile()
