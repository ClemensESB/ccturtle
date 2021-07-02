const WebSocket = require("ws");
const mysql = require('mysql');

const wss = new WebSocket.Server({port : 2256});


var clients = new Object();

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
        //console.log(data.data);
        //clients[data.]
        console.log(`client send ${data}`);
        var sentObj = JSON.parse(data);
        if (sentObj.data == "connected") {
            clients[sentObj.sender] = ws;
        }
        //console.log(clients);
        //console.log(sentObj.db);
        if(sentObj.db !== undefined){
            con.query(sentObj.db,function(err,result,fields){
                if(err) throw err;
                console.log(JSON.stringify(result));
                ws.send(JSON.stringify(result));
            });
        }else{
            if (clients[sentObj.receiver] !== undefined && clients[sentObj.receiver].readyState == WebSocket.OPEN) {
                clients[sentObj.receiver].send(data);
            }
        }
    });
    
    ws.on("close",()=>{
        console.log("Client has disconnected!");
    });
});

