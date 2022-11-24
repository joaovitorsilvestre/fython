struct User:
    name = None

def test_struct_user():
    user = Tests.Struct.User(name="João")
    assert user.name == "João"
