from typing import Annotated
from fastapi import APIRouter, Depends
from transformers.pipelines import pipeline
from transformers.pipelines.base import Pipeline

from routers.models.text_gen.simple_input import SimpleInput

router = APIRouter(prefix="/text")


def text_gen_pipeline() -> Pipeline:
    return pipeline("text-generation", model="HuggingFaceTB/SmolLM2-360M")


@router.post("/simple-gen")
def simple_gen(
    input: SimpleInput,
    pipeline: Annotated[Pipeline, Depends(text_gen_pipeline)],
):
    return pipeline(input.input)
