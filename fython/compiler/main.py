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
        self.project_name = self.folder.split('/')[-1]
        self.files = []

    def read_project(self):
        for root, subdirs, files in os.walk(self.folder):
            # print('--\nroot = ' + root)

            for subdir in subdirs:
                pass
                # print('\t- subdirectory ' + subdir)

            for filename in files:
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



def execute_in_elixir(compiled: str):
    with open('/tmp/compiled_fython', 'w+') as f:
        f.write(compiled)

    try:
        command = f'elixir fython.exs'
        stream = os.popen(command)
        output = stream.read()
        print(output)
    except Exception as e:
        raise e
    finally:
        os.remove('/tmp/compiled_fython')


def run():
    c = Compiler('example_project')
    c.compile()

    for i in c.files:
        if i.error:
            print(i.error.as_string())
            return

    compiled = c.merge_compiled()

    print('compiled::')
    print(compiled)
    print('elixir result:')
    execute_in_elixir(compiled)


if __name__ == '__main__':
    run()