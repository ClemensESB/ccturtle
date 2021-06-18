const WebSocket = require("ws");
const mysql = require('mysql');

const wss = new WebSocket.Server({port : 2256});


var con = mysql.createConnection({
    host: "localhost",
    user: "turtle",
    password: "",
    database: "turtle"
});

con.connect(function (err) {
    if (err) throw err;
    console.log("connected to database");
});



wss.on("connection", ws =>{
    console.log("new Client connected!")

    ws.on("message",data=>{
        console.log(`client send ${data}`);
        var sentObj = JSON.parse(data);
        //console.log(sentObj.db);
        if(sentObj.db !== undefined){
            con.query(sentObj.db,function(err,result,fields){
                if(err) throw err;
                console.log(JSON.stringify(result));
                ws.send(JSON.stringify(result));
            });
        }else{
            wss.clients.forEach(function each(client) {
                if (client != ws && client.readyState == WebSocket.OPEN) {
                    client.send(data);
                }
            });
        }
    });
    
    ws.on("close",()=>{
        console.log("Client has disconnected!");
    });
});

