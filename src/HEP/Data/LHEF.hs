{-# LANGUAGE RecordWildCards #-}
--------------------------------------------------------------------------------
-- |
-- Module      :  HEP.Data.LHEF
-- Copyright   :  (c) 2014 Chan Beom Park
-- License     :  BSD-style
-- Maintainer  :  Chan Beom Park <cbpark@gmail.com>
-- Stability   :  experimental
-- Portability :  GHC
--
-- Helper functions to use in analyses of LHEF data files.
--
--------------------------------------------------------------------------------

module HEP.Data.LHEF
    (
      module LT
    , module LP
    , module HV
    , module LV
    , module TV

    , energyOf
    , idOf
    , is
    , finalStates
    , initialStates
    , getDaughters
    , particlesFrom
    ) where

import           Control.Monad              (liftM)
import           Control.Monad.Trans.Reader
import qualified Data.IntMap                as M
import           Data.Sequence              (Seq, empty, (<|), (><))

import           HEP.Vector                 as HV
import           HEP.Vector.LorentzTVector  as TV (setXYM)
import           HEP.Vector.LorentzVector   as LV (setEtaPhiPtM, setXYZT)

import           HEP.Data.LHEF.Parser       as LP
import           HEP.Data.LHEF.Type         as LT

energyOf :: Particle -> Double
energyOf Particle { pup = (_, _, _, e, _) } = e

idOf :: Particle -> Int
idOf Particle { .. } = idup

is :: Particle -> ParticleType -> Bool
p `is` pid = (`elem` getParType pid) . abs . idup $ p

initialStates :: Reader EventEntry [Particle]
initialStates = liftM M.elems $
                asks (M.filter (\Particle { .. } -> fst mothup == 1))

finalStates :: Reader EventEntry [Particle]
finalStates = liftM M.elems $ asks (M.filter (\Particle { .. } -> istup == 1))

particlesFrom :: ParticleType -> Reader EventEntry [Seq Particle]
particlesFrom pid = asks (M.keys . M.filter (`is` pid)) >>= mapM getDaughters

getDaughters :: Int -> Reader EventEntry (Seq Particle)
getDaughters i = do
  pm <- ask
  daughters <- asks $ M.filter (\Particle { .. } -> fst mothup == i)
  return $ M.foldrWithKey
             (\k p acc -> case istup p of
                            1 -> p <| acc
                            _ -> runReader (getDaughters k) pm >< acc) empty
             daughters
