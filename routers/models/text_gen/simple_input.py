from typing import Annotated
from pydantic import BaseModel, Field


class SimpleInput(BaseModel):
    input: Annotated[str, Field()]
