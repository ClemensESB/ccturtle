import asyncio
import websockets


async def hello():
    uri = "ws://66568dd80de6.ngrok.io:80"
    async with websockets.connect(uri) as websocket:
        await websocket.send("Hello world!")
        await websocket.recv()

asyncio.get_event_loop().run_until_complete(hello())
