class Client{
    constructor(){
        this.id = genId()
        this.gameId = genId()
        this.connectionType = null
    }
    quickplay(){ // simply connect to random
        this.showHome()
        this.connectionType = "random"
        this.createConnection()
        switchGameUi(true)
    }
    competitive(){ // show Options
        this.showHome()
        this.connectionType = "competitive"
        this.createConnection()
        this.showComp("Tell your opponent the code<br> for him to join.")
    }


    createConnection(){
        eval(`ws = new WebSocket('wss://pongws.lsche.de')`)
        addListeners()
        setTimeout(()=>{
            if(ws.readyState != ws.OPEN) {
                setInfo("Server connection timeout")
                ws.close()
            }
        },5000)
    }
    connectTo(id){
        this.gameId = id.replaceAll("#","")
        send("gameId"+this.gameId)
    }
    // connected and error handler
    connected(){
        send(this.connectionType+":"+client.id+":"+client.gameId)
    }

    goHome(text){
        setInfo(text)
        info.classList.add("countDownBar")
        setTimeout(()=>{this.reload()},5*1000)
    }

    reload(){location.reload()}
    showHome(){home.classList.remove("hidden")}


    // Ui edit
    showComp(msg){
        comp.classList.remove("hoverLine")
        comp.removeAttribute("onclick")
        document.querySelector("#comp p").innerHTML = msg
        quick.classList.add("hidden")
        roomCodeArea.classList.remove("hidden")
        gameId.innerHTML = this.gameId
        link.value = window.location.href+"#"+this.gameId
        setTimeout(()=>{roomCodeArea.style.transform = "scaleY(1)"},1)
    }
}