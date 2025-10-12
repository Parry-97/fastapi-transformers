import pytest
import requests
from ray import serve
from serve_app import deployment_graph


@pytest.fixture
def serve_start_and_shutdown():
    serve.start()
    serve.run(deployment_graph)
    yield
    serve.shutdown()


def test_ray_serve_app(serve_start_and_shutdown):
    response = requests.post(
        "http://localhost:8000/text/simple-gen", json={"input": "What's up my man ?"}
    )
    assert response.status_code == 200
    assert response.json()
