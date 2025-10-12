from ray import serve
from fastapi import FastAPI
from transformers.pipelines import pipeline
from transformers.pipelines.base import Pipeline

from routers.models.text_gen.simple_input import SimpleInput

# This is a new Ray Serve application that replaces the original FastAPI app.
# It serves the same text generation model, but now it's managed by Ray Serve
# for better scalability and performance.

app = FastAPI()


@serve.deployment
@serve.ingress(app)
class TextGenService:
    def __init__(self):
        # Load the text generation pipeline when the deployment is initialized.
        self._pipeline: Pipeline = pipeline("text-generation")

    @app.post("/text/simple-gen")
    def simple_gen(self, input: SimpleInput):
        # The input is a Pydantic model, so we access the 'input' attribute.
        return self._pipeline(input.input)


# This is the entrypoint for the Ray Serve application.
# It binds the TextGenService to the deployment graph.
deployment_graph = TextGenService.bind()
