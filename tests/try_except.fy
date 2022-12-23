def test_try():
    try:
        raise Tests.Try_except.MyException(required_field="test")
    except Tests.Try_except.MyException as e:
        assert e.message == "Error"
        assert e.required_field == "test"

exception MyException:
    message = "Error"
    required_field