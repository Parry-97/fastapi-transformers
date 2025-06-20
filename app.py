from fastapi import FastAPI
from routers.text.router import router as text_gen_router
import uvicorn

app = FastAPI()

app.include_router(router=text_gen_router)


def main():
    uvicorn.run(app=app, port=5000)


if __name__ == "__main__":
    main()
