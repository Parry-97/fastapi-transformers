from fastapi import FastAPI
from routers.text.router import router as text_gen_router
import uvicorn

app = FastAPI()

app.include_router(router=text_gen_router)


def main():
    uvicorn.run(app=app, host="0.0.0.0", port=80)


if __name__ == "__main__":
    main()
