FROM haskell:8.10-slim

# Update and install libs
RUN cabal update
RUN cabal install --lib websockets

# Generell enviroment options
EXPOSE 9160
WORKDIR /pong

# copy sourcecode and compile
COPY ./Backend .
RUN ghc ./server.hs

# Start server
CMD ./server

# docker build -t hs-pong .