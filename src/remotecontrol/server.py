import asyncio
from asyncio.windows_events import NULL

from asyncio.queues import Queue
import websockets #works fine
import json
import string
from pprint import pprint
#32 zeichen label turtle
#TODO
#datenbank
#gui
#vordefinierte prozeduren für inspect,inventory,craft




def is_json(myjson):
  try:
    json_object = json.loads(myjson)
  except ValueError as e:
    return False
  return True

connected = set()
async def command(ws):
  print("command: ")
  turtleCommand = input()
  con = '{"func": "'+turtleCommand+'"}'
  await ws.send(con)



async def handler(websocket, path):
  try:
    connected.add(websocket)
    counter = 0
    async for message in websocket:
      if is_json(message):
        pyobj = json.loads(message)
        print(pyobj)
      else:
        print(message)
      for conn in connected:
        if conn != websocket:
          await conn.send(message)
        await command(websocket)
      counter += 1
  except Exception as ex:
      connected.remove(websocket)
      print(ex)


start_server = websockets.serve(handler, 'localhost', 2256)

asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()

