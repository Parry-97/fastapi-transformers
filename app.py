from fastapi import FastAPI
import uvicorn

app = FastAPI()


def main():
    uvicorn.run(app=app, port=5000)


if __name__ == "__main__":
    main()
