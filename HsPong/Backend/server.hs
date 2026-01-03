{-# LANGUAGE OverloadedStrings #-}
module Main where
import Data.Bool
import Data.List
import Control.Exception (finally)
import Control.Monad (forM_, forever)
import Control.Concurrent (MVar, newMVar, modifyMVar_, modifyMVar, readMVar)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as T

import qualified Network.WebSockets as WS
import PongGame

newtype ServerState = ServerState {games :: [GameState]}


broadcast :: ServerState -> String -> String -> IO ()
broadcast s@(ServerState games) gid message = do
    broadcastGS (find games gid) message   
  where
    find [] _ = GameState [] (Ball (-1) (-1) 0 0) 0 "" ""
    find (g@(GameState _ _ _ id _):gs) gid = if id==gid then g else find gs gid

-- Game management
createJoinGame :: ServerState -> String -> Player -> String -> ServerState
createJoinGame s gid player gt = modGameStateWithId gid (\gs->addPlayer gs player) $ createGame s gid gt

createGame :: ServerState -> String -> String -> ServerState
createGame s@(ServerState games) gid gt 
  | not $ gameExists games gid = ServerState ( games ++ [initGameState gid gt])
  | otherwise = s
  where 
    gameExists [] _ = False
    gameExists ((GameState _ _ _ id _):xs) gid
      | gid == id = True
      | otherwise = gameExists xs gid 

removeGame :: ServerState -> String -> ServerState 
removeGame (ServerState games) gid = ServerState $ filter (\(GameState _ _ _ id _)->id/=gid) games 

-- Game management in ServerState HELPER
modGameState :: (GameState -> Bool) -> (GameState -> GameState) -> ServerState -> ServerState
modGameState boolFun gsModFun (ServerState games) = ServerState (map (\gs -> if boolFun gs then gsModFun gs else gs) games)

modGameStateWithId :: String -> (GameState->GameState) -> ServerState -> ServerState
modGameStateWithId gid = modGameState (\g@(GameState _ _ _ gid' _)->gid'==gid)

locatePlayerGameId :: Player -> ServerState -> String
locatePlayerGameId player@(Player _ _ _ _ pid) (ServerState games) = do
  let res = find (\(GameState p _ _ gid _)-> foldr (\(Player _ _ _ _ pid') y-> (pid == pid') || y ) False p) games
  case res of
    Just (GameState _ _ _ gid _) -> gid
    Nothing -> "NotFound" -- cant happen

findRandomGame :: ServerState -> String -> String
findRandomGame s@(ServerState games) gameId = locate games gameId 
  where
    locate [] gameId = gameId
    locate (g@(GameState _ _ j gid gt):gs) gameId = if j < 2 && gt == "random" then gid else locate gs gameId

-- show given GameState in console
listGames :: ServerState -> IO()
listGames s@(ServerState games) = do
  T.putStr "\ESC[2J" -- clears console
  T.putStrLn $ T.pack ("All current games: " <> show (length games))
  forM_ games $ \g@(GameState _ _ _ id _) -> T.putStrLn $ T.pack("Id: "<>id)<>"   "<>gsToJson g 



main :: IO ()
main = do
  T.putStrLn ("Server started")
  serverState <- newMVar $ ServerState []
  WS.runServer "0.0.0.0" 9160 $ pongWebsocketServer serverState

pongWebsocketServer :: MVar ServerState -> WS.ServerApp
pongWebsocketServer serverState pending = do
  conn <- WS.acceptRequest pending -- accepting connection
  msg <- WS.receiveData conn -- receiving first message
  s@(ServerState games) <- readMVar serverState -- getting ServerState
  case msg of
    _ | "random" == input!!0 -> flip finally disconnect $ do 
          let newId = findRandomGame s gameId -- finding game with type random and one player or keeping current id
          modifyMVar_ serverState $ \s -> do 
            return $ createJoinGame s newId player "random" -- creating Game and joining
          play player newId serverState -- starting play-loop
      | "competitive" == input!!0 -> flip finally disconnect $ do 
          modifyMVar_ serverState $ \s@(ServerState games) -> do 
            return $ createJoinGame s gameId player "competitive" -- creating Game and joining
          play player gameId serverState -- starting play-loop
      | otherwise -> WS.sendTextData conn ("Wrong announcement"::Text)
      where
        playerId = input!!1 -- extracting ids
        gameId = input!!2 -- extracting ids
        player = Player (-1) (-1) 0 conn playerId -- Initializing player with conn and pid
        input = map T.unpack $ T.splitOn ":" msg -- splitting first message from client into list
        disconnect = modifyMVar_ serverState $ \s@(ServerState games) -> do -- disconnecting function
          let gameId = locatePlayerGameId player s -- locating game id, might differ because of random join
          broadcast s gameId "Partner disconnected" -- tell all game is over
          let s' = removeGame s gameId -- remove from game list
          listGames s' -- show modified GameState in console
          return s'


play :: Player -> String -> MVar ServerState -> IO ()
play player@(Player _ _ _ conn pid) gameId serverState = do 
  s@(ServerState games) <- readMVar serverState -- getting ServerState
  broadcast s gameId "game" -- broadcast Game once for it to start
  listGames s -- show GameState in console
  forever $ do -- incoming message loop
    msg <- WS.receiveData conn
    case msg of -- deciding what message it was
      _ | "pos" `T.isPrefixOf` msg -> modifyMVar_ serverState $ \s -> do -- handling given position 
            let pos = read (T.unpack $ T.drop (T.length "pos") msg) -- extract pos
            return $ modGameStateWithId gameId (\g->modifyPos g pos pid) s -- running modifyPos on GameState from id
        | "gameId" `T.isPrefixOf` msg -> do 
            let givenId = T.unpack $ T.drop (T.length "gameId") msg
            modifyMVar_ serverState $ \s -> do -- join another game 
              return $ modGameStateWithId givenId (\gs->addPlayer gs player) $ removeGame s gameId -- remove old game, join new
            play player givenId serverState -- restart play-loop with new gameId
        | otherwise -> do -- invalid/unknown message handler
            s@(ServerState games) <- readMVar serverState
            broadcast s gameId "No matching msg!"
    modifyMVar_ serverState $ \s -> do 
      let s' = modGameStateWithId gameId gameCycle s
      broadcast s' gameId "game"
      return s'