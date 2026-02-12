from fastapi import FastAPI
from database import db

app = FastAPI()

db.do_your_thing()

print("Connected to the database successfully!")

@app.get("/")
async def root():    
    return {"message": "Hello World"}