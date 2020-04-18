import os
import shutil
import pathlib
from fython.compiler.elixir_nodes import EModule
from collections import defaultdict

CURRENT_PATH = pathlib.Path(__file__).parent.absolute()


class File:
    def __init__(self, name, full_path, path_from_root):
        self.name = name.replace('.fy', '').strip()
        self.full_path = full_path
        self.path_from_root = path_from_root
        with open(full_path, 'r') as f:
            self.content = f.read()
        self.error = None
        self.compiled = None

    def __repr__(self):
        return f"File: {self.path_from_root}"

    def module_name(self):
        if self.path_from_root:
            folders = [i for i in (self.path_from_root + '/' + self.name).split('/') if i]

            module =  ''
            for f in folders:
                if module:
                    module += '.' + f[0].upper() + f[1:]
                else:
                    module += f[0].upper() + f[1:]
        else:
            module =  self.name

        return module[0].upper() + module[1:]

    def compile(self):
        from fython.core import lex_and_parse

        ast, error = lex_and_parse(self.name, self.content)
        print(ast, error)

        if error:
            self.error = error
            return

        self.compiled = str(EModule(self.module_name(), ast))

    def get_imports(self):
        from fython.core import lex_and_parse
        from fython.core.parser import ImportNode

        ast, error = lex_and_parse(self.name, self.content)

        if error:
            self.error = error
            return

        return [
            i for i in ast.statement_nodes if isinstance(i, ImportNode)
        ]


class Compiler:
    def __init__(self, folder):
        self.folder = folder
        self.project_name = self.folder.split('/')[-1]
        self.files = []

    def read_project(self):
        for root, subdirs, files in os.walk(self.folder):
            path_from_root = root.replace(self.folder, '')

            for filename in files:
                if filename[-3:] == '.fy':
                    file_path = os.path.join(root, filename)

                    self.files.append(
                        File(filename, file_path, path_from_root)
                    )

    def compile(self):
        compiled = []

        self.read_project()
        for file in self.ordered_files_by_dependencies():
            compiled.append(file.compile())

        return self.files

    def ordered_files_by_dependencies(self):
        dependencies_by_file = defaultdict(list)

        for f in self.files:
            for imp in f.get_imports():
                for i in imp.imports_list:
                    dependencies_by_file[f.module_name()].append(i.name)

        need_order = []
        dependencies_by_file = dict(dependencies_by_file)

        for k, v in dependencies_by_file.items():
            for dep in v:
                if dep not in need_order:
                    need_order = [dep, *need_order]

        need_order = [i for i in need_order if i in [f.module_name() for f in self.files]]

        files_per_name = {f.module_name(): f for f in self.files}

        ordered_by_number_of_imports = sorted(
            need_order, key=lambda x: len(files_per_name[x].get_imports())
        )

        return [
            *[files_per_name[i] for i in ordered_by_number_of_imports],
            *[f for f in self.files if f.module_name() not in ordered_by_number_of_imports]
        ]

    def merge_compiled(self):
        assert all(i.compiled for i in self.files), " Files no compiled"

        if len(self.files) == 1:
            return self.files[0].compiled
        else:
            compiled = (i.compiled for i in self.files)
            return "{:__block__, [], [" + ','.join(compiled) + "]}"


def copy_jason(src, dest):
    for item in os.listdir(src):
        full_file_name = os.path.join(src, item)
        if os.path.isfile(full_file_name):
            shutil.copy(full_file_name, dest)


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

    for file in c.ordered_files_by_dependencies():
        compiled = file.compiled
        print('Compiled to elixir!. Resulting quoted:')
        print(compiled)
        print("Generating beam files")

        quoted_name = f'{project_path}/{project_name}.{file.name}.fyc'

        with open(quoted_name, 'w+') as f:
            f.write(compiled)

        project_path = f"{project_path}/{project_name}.{file.name}.fyc".replace('/', ' ')

        output = os.popen(f'elixir {CURRENT_PATH}/compile_quoted.exs {project_path}').read()

        if 'FAILED' in output:
            print(output)
            raise ValueError(f"Failed to compile file: {file.name}")

        os.remove(quoted_name)

    copy_jason('./jason_dep', f'./{project_name}/compiled/')

    print('OK')


if __name__ == '__main__':
    run('/home/joao/fython/fython/compiler/bootstrap')
