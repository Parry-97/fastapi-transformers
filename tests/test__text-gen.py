from fastapi.testclient import TestClient
from app import app
from routers.models.text_gen.simple_input import SimpleInput


client = TestClient(app)


def test_read_main():
    response = client.post(
        "/text/simple-gen",
        #  WARN: the json field takes a input a dict !
        json=SimpleInput(input="What's up my man ?").model_dump(),
    )
    assert response.status_code == 200
    assert response.content
