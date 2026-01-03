class pongGame{
    constructor(){
        this.gs = {
            "player" : [],
            "ball" : {"posX":settings.canvasDim[0]/2,"posY":settings.canvasDim[1]/2}
        }
        this.halfRacketHeight = settings.racketDim[1]/2
        this.isPlaying = false
        this.clientY = 0
        this.listener = undefined
        this.timer = undefined
    }

    received(m){
        switch(true) {
            case (/{"player.*/g.test(m.data)):
                this.gs = JSON.parse(m.data)
                this.update()
                break
            case (/.*/g.test(m.data)): // default
                ws.close()
                console.log(m.data)
            case (/Partner disconnected/g.test(m.data)):
                clearInterval(this.timer)
                client.goHome("Partner disconnected, resetting")
                break
            case (/No matching msg!/g.test(m.data)):
                alert("Server received no matching message:\n"+ m.data)
                break
            default:
                alert("Client received no matching message:\n"+ m.data)
                break
        }
    }

    update(){
        this.updateUi()
        if(this.isPlaying) return; 
        if(this.gs.player.length == 2){ // starting sequence
            this.isPlaying = true
            switchGameUi(true)
            for(let i=0;i<4;i++){setTimeout(()=>{setInfo(i+"")},(4-i)*1000)}
            setTimeout(()=>{
                this.timer = setInterval(this.publishPos.bind(this),30)
                this.listener = canvas.addEventListener("mousemove",e=> this.clientY = e.clientY)
                setInfo("")
            },4*1000)
            this.clientY = canvas.offsetTop + canvas.clientHeight /2
        }else{
            setInfo("Waiting for another player")
        }
    }

    publishPos(){
        evalInput()
        send("pos"+Math.round(this.clampPos((this.clientY-canvas.offsetTop)/canvas.clientHeight*settings.canvasDim[1])))
    }

    clampPos(int){
        if(int > settings.canvasDim[1] - this.halfRacketHeight) return 1000 - this.halfRacketHeight
        if(int < this.halfRacketHeight) return this.halfRacketHeight
        return int
    }

    // drawing stuff
    updateUi(){
        ctx.clearRect(0,0,settings.canvasDim[0],settings.canvasDim[1])
        this.gs.player.forEach((p,i)=>{
            eval(`s${i}.innerHTML = p.score`)
            if(p.score >= 10){
                clearInterval(this.timer)
                i==0?client.goHome("Left player won!"):client.goHome("Right player won!")
            }
            this.drawRacket(ctx,p.posX,p.posY)
        })
        this.drawBall(ctx)
    }
    drawRacket(ctx,posX,posY){
        ctx.fillRect(posX,posY,settings.racketDim[0],settings.racketDim[1])
    }
    drawBall(ctx){
        ctx.beginPath();
        ctx.arc(this.gs.ball.posX, this.gs.ball.posY, settings.ballRadius, 0, 2 * Math.PI);
        ctx.fill();
    }
}