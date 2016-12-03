module Main where

import App
import Prelude
import PRNG.Xorshift128
import PRNG.PRNG
import Block as Block
import Board as Board
import Cell as Cell
import Control.Monad.Eff.Random as Random
import Data.List.Lazy as IL
import Matrix as Matrix
import Control.Monad.Aff (Aff, later')
import Control.Monad.Eff (Eff)
import GameState (GameState(..))
import GameStats (GameStats(..))
import GameStats (initial) as GameStats
import Halogen (HalogenEffects, action, runUI, query)
import Halogen.Util (awaitBody, runHalogenAff)

type InitialConstantState = {
  gameState :: GameState
  , gameStats :: GameStats
  , gameBoard :: Board.Board
  , hintBoard :: Board.Board
}

initialState :: InitialConstantState
initialState = { gameState: NotYetStarted
  , gameStats: GameStats.initial
  , gameBoard: Board.Board { cells: Matrix.repeat 10 20 Cell.Free }
  , hintBoard: Board.Board { cells: Matrix.repeat 5 5 Cell.Free }
}

setBlocks :: InitialConstantState -> IL.List (Block.Block) -> State
setBlocks state blocks = {
  gameState: state.gameState
  , gameStats: state.gameStats
  , blocks: blocks
  , gameBoard: state.gameBoard
  , hintBoard: state.hintBoard
}

gen :: { value :: Int, state :: Xorshift128 } -> { value :: Int, state :: Xorshift128 }
gen { value, state } = generate state

getAllBlocks :: Eff
  (HalogenEffects(random :: Random.RANDOM))
  (IL.List Int)
getAllBlocks = do
  seeds <- IL.replicateM 4 (Random.randomInt (-10000000) 100000000)
  pure $ IL.drop 1 $ map (\x -> x.value) $  IL.iterate gen { state: (initialize seeds), value: 0 }

main :: Eff (HalogenEffects (random :: Random.RANDOM)) Unit
main = do
  blocks <- getAllBlocks
  runHalogenAff do
    body <- awaitBody
    app <- runUI app (setBlocks initialState $ map Block.arbitraryBlock blocks) body
    setInterval 500 $ app (action Tick)

setInterval :: forall e a. Int -> Aff e a -> Aff e Unit
setInterval ms f = later' ms $ do
  f
  setInterval ms f
