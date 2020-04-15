import json
import os
import shutil
from typing import List
import pathlib
from fython.compiler.elixir_nodes import EModule
from fython.compiler.integrity_check import IntegrityChecks

CURRENT_PATH = pathlib.Path(__file__).parent.absolute()


class File:
    def __init__(self, name, parent, full_path):
        self.name = name.replace('.fy', '').strip()
        self.parent = parent
        self.full_path = full_path
        with open(full_path, 'r') as f:
            self.content = f.read()
        self.error = None
        self.compiled = None

    def __repr__(self):
        return f"File: {self.full_path}"

    def compile(self):
        from fython.core import lex_and_parse

        ast, error = lex_and_parse(self.name, self.content)
        print(ast, error)

        if error:
            self.error = error
            return

        check = IntegrityChecks(ast).validate()
        if check.error:
            self.error = check.error
            return

        self.compiled = str(EModule(self.name, check.node))


class Compiler:
    def __init__(self, folder):
        self.folder = folder
        self.project_name = self.folder.split('/')[-1]
        self.files = []

    def read_project(self):
        for root, subdirs, files in os.walk(self.folder):
            # print('--\nroot = ' + root)

            for subdir in subdirs:
                pass
                # print('\t- subdirectory ' + subdir)

            for filename in files:
                if filename[-3:] == '.fy':
                    file_path = os.path.join(root, filename)

                    self.files.append(
                        File(filename, None, file_path)
                    )

    def compile(self):
        compiled = []

        self.read_project()
        for file in self.files:
            compiled.append(file.compile())

        return self.files

    def merge_compiled(self):
        assert all(i.compiled for i in self.files), " Files no compiled"

        if len(self.files) == 1:
            return self.files[0].compiled
        else:
            compiled = (i.compiled for i in self.files)
            return "{:__block__, [], [" + ','.join(compiled) + "]}"


def run(project_path):
    project_name = project_path.split('/')[-1]

    c = Compiler(project_path)
    c.compile()

    try:
        shutil.rmtree(f"{project_path}/compiled")
    except:
        pass

    os.mkdir(f"{project_path}/compiled")

    for i in c.files:
        if i.error:
            print(i.error.as_string())
            return

    compiled = c.merge_compiled()
    print('Compiled to elixir!. Resulting quoted:')
    print(compiled)
    print("Generating beam files")

    quoted_name = f'{project_path}/{project_name}.fyc'

    with open(quoted_name, 'w+') as f:
        f.write(compiled)

    project_path = f"{project_path}/{project_name}.fyc".replace('/', ' ')

    output = os.popen(f'elixir {CURRENT_PATH}/compile_quoted.exs {project_path}').read()

    print(output)

    os.remove(quoted_name)


if __name__ == '__main__':
    run('/home/joao/fython/fython/compiler/bootstrap')
