class InterityResult:
    def __init__(self, node):
        self.node = node
        self.error = None

    def register(self, res):
        if res.error:
            self.error = res.error
        return res.node

    def success(self, node):
        self.node = node
        return self

    def failure(self, error):
        if not self.error:
            self.error = error
        return self
