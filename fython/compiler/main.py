import os

from fython.compiler.elixir_nodes import EModule


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

        self.compiled = str(EModule(self.name, ast))


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
        compiled = []

        self.read_project()
        for file in self.project_structured['files']:
            compiled.append(file.compile())

        return self.project_structured['files']


def execute_in_elixir(compiled: str):
    command = f'elixir -e "IO.inspect(Code.eval_quoted({compiled}))"'

    stream = os.popen(command)
    output = stream.read()
    print(output)


if __name__ == '__main__':
    c = Compiler('example_project')
    c.compile()

    if c.project_structured['files'][0].error:
        print(c.project_structured['files'][0].error.as_string())
    else:
        print('compiled::')
        print(c.project_structured['files'][0].compiled)
        print('elixir result:')
        execute_in_elixir(c.project_structured['files'][0].compiled)

