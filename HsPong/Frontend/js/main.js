const settings = {
    "ballRadius":30,
    "racketDim": [30,200], // Width, Height
    "canvasDim": [2000,1000] // Width, Height
}

const ids = ["comp","quick","s0","s1","info","playField","canvas","ui","ingame","roomCode","gameId","givenCode","join","link","copy","helpText","helpBtn","home","slideInput"]
ids.forEach(id=>{
    eval(`const ${id}=document.getElementById("${id}")`)
})
function setInfo(text){ info.innerHTML = text }

const ctx = canvas.getContext("2d")
ctx.fillStyle = "#FFFFFF";


let ws = undefined
const game = new pongGame()
const client = new Client()
gameId.innerHTML = client.gameId

window.addEventListener("load",()=>{
    join.addEventListener("click",()=>client.connectTo(givenCode.value))
    const hash = window.location.hash
    window.location.hash = "#"
    if(hash != ""){
        client.competitive()
        client.connectTo(hash)
    }
})

function addListeners(){
    ws.onopen = ()=>client.connected()
    ws.onmessage = (e)=>game.received(e)
}
function send(message){
    ws.send(message)
}

function switchGameUi(bool) {
    if(bool){
        ui.classList.add("hidden")
        ingame.classList.remove("hidden")
        const m = canvas.clientHeight + canvas.offsetTop
        slideInput.setAttribute("max",m) // Setting parameters for mobile input slider
        slideInput.setAttribute("value",m/2)
    }else{        
        ui.classList.remove("hidden")
        ingame.classList.add("hidden")
    }
}

function genId(){
    return Math.round((Date.now()*0.00001) * Math.random())
}

copy.addEventListener("click",()=>{copyLink()})
function copyLink(){
    link.select();
    link.setSelectionRange(0, 9999999); 
    navigator.clipboard.writeText(link.value);
}

function setHelpText(bool){
    if(bool) {
        helpText.style.transform = "translateX(0px)"
        helpBtn.classList.add("hidden")
    }else {
        helpText.style.transform = "translateX(-1000px)"
        helpBtn.classList.remove("hidden")
    }
}

// Keyboard input
let keySpeed = 20
let pressed = [false,false]
window.addEventListener("keydown",e=>{
    if(e.code == "ArrowDown") pressed[0] = true
    if(e.code == "ArrowUp") pressed[1] = true
})
window.addEventListener("keyup",e=>{
    if(e.code == "ArrowDown") pressed[0] = false
    if(e.code == "ArrowUp") pressed[1] = false
})

function evalInput(){
    if(pressed[0]) game.clientY = game.clampPos(game.clientY + keySpeed)
    if(pressed[1]) game.clientY = game.clampPos(game.clientY - keySpeed)
}

// mobile Slider input
slideInput.setAttribute("min",Math.round(settings.racketDim[1]/2))
slideInput.addEventListener("input",(e)=>{
    game.clientY = slideInput.value
})