struct User:
    name = None
    email

def test_struct_user():
    user = Tests.Struct.User(name="John", email="john@example.com")
    assert user.name == "John"

    user = Tests.Struct.User(email="john@example.com")
    assert user.name == None
    assert user.email == "john@example.com"
