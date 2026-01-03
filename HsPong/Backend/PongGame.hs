module PongGame where
import qualified Network.WebSockets.Connection as WS
import Data.Bool
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as T
import Control.Monad (forM_)

data Seting = Seting {
  ballRadius :: Int,
  racketDim :: (Int,Int), -- Width, Height
  canvasDim :: (Int,Int) -- Width, Height
} deriving (Show)

data Player = Player {
  x :: Int,
  y :: Int,
  score :: Int,
  con :: WS.Connection,
  id :: String
} 

data Ball = Ball {
  bx :: Int,
  by :: Int,
  velX :: Int,
  velY :: Int
} deriving (Show)

data GameState = GameState {
  playerList :: [Player], 
  ball :: Ball,
  joined :: Int, -- current player count
  gameId :: String,
  gameType :: String
} 

settings :: Seting
settings = Seting {ballRadius = 30, racketDim = (30,200), canvasDim = (2000,1000)}

-- GameState management functions
initGameState :: String -> String -> GameState
initGameState gid gt = GameState [] (Ball bx by 5 3) 0 gid gt
  where
    bx = fst (canvasDim settings) `div` 2
    by = snd (canvasDim settings) `div` 2

addPlayer :: GameState -> Player -> GameState
addPlayer gs@(GameState p b j gid t) (Player _ _ sc c pid) 
  | j == 0 = GameState (p ++ [Player p1x py sc c pid]) b (j+1) gid t
  | j == 1 = GameState (p ++ [Player p2x py sc c pid]) b (j+1) gid t
  | otherwise = gs
  where
    py = snd (canvasDim settings) `div` 2 - snd (racketDim settings) `div` 2
    p1x = fst $ racketDim settings
    p2x = fst (canvasDim settings) - fst (racketDim settings) *2

-- Game logic
gameCycle :: GameState -> GameState
gameCycle gs@(GameState p b j id t) = GameState (snd ballPlayersScore) (fst ballPlayersScore) j id t
  where
    modifiedBallPos = ballBorderCollision $ ballMove b
    bPCollision = ballPlayerCollision (p!!1) $ ballPlayerCollision (p!!0) modifiedBallPos
    ballPlayersScore = ballScoreCollision bPCollision p
    ballMove (Ball x y vx vy) = Ball (x+vx) (y+vy) vx vy


ballBorderCollision :: Ball -> Ball
ballBorderCollision (Ball x y vx vy) = case y of
  _ | y < br -> Ball x br vx (vy*(-1))
    | y > ch - br -> Ball x (ch - br) vx (vy*(-1))
    | otherwise -> Ball x y vx vy
  where
    br = ballRadius settings
    ch = snd (canvasDim settings)

ballPlayerCollision ::  Player -> Ball -> Ball
ballPlayerCollision (Player px py _ _ _) b@(Ball bx by vx vy) = if noCollision then b else Ball (bx-vx) (by-vy) (-(modifyVelocity vx)) (modifyVelocity vy) 
  where
    noCollision = px > bx+br || px+pw < bx-br || py > by+br || py+ph < by-br
    br = ballRadius settings
    pw = fst $ racketDim settings -- Player width
    ph = snd $ racketDim settings -- Player height
    modifyVelocity x = if x < 0 then x-2 else x+2 -- modify speed

ballScoreCollision :: Ball -> [Player] -> (Ball,[Player])
ballScoreCollision b@(Ball x y vx vy) p = case x of
  _ | x < 0 -> (Ball bx by velX velY, (p!!0) : [scoreUp (p!!1)]) -- second player (index 1) => right player & ball reset and x direction change
    | x > fst (canvasDim settings) -> (Ball bx by velX velY, scoreUp (p!!0) : [p!!1]) -- first player (index 0) => left player & ball reset and x direction change
    | otherwise -> (b,p)
  where
    bx = fst (canvasDim settings) `div` 2
    by = snd (canvasDim settings) `div` 2
    velX = if vx < 0 then 5 else -5 -- reset speed, change starting direction
    velY = if vy < 0 then 3 else -3 -- reset speed, change starting direction
    scoreUp (Player x y s c id) = Player x y (s+1) c id  

modifyPos :: GameState -> Int -> String -> GameState
modifyPos gs@(GameState p b j i t) position id = GameState (map (\pl@(Player x y s c i)->if i == id then Player x pos s c id else pl) p) b j i t 
  where
    pos = position - snd ( racketDim settings) `div` 2


-- Communication Helpers
gsToJson :: GameState -> Text
gsToJson gs@(GameState p b j i t) = T.pack("{\"player\" : ["<> player <> "],\"ball\" : "<> showB b <>"}")
  where
    showP (Player x y score _ _) = T.pack("{\"posX\":"<> show x <>",\"posY\":"<> show y <> ",\"score\":"<> show score <> "}")
    showB (Ball x y _ _) = "{\"posX\":"<> show x <>",\"posY\":"<> show y <>"}"
    player = T.unpack $ T.intercalate (T.pack ", ") (map showP p)

broadcastGS :: GameState -> String -> IO()
broadcastGS g@(GameState p _ _ _ _) message = do
    forM_ p $ \(Player _ _ _ conn _) -> WS.sendTextData conn $ msg
  where 
    msg = if "game" == message then gsToJson g else T.pack message