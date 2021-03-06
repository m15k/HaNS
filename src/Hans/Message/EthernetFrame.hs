{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Hans.Message.EthernetFrame (
    EtherType(..)
  , parseEtherType, renderEtherType

  , EthernetFrame(..)
  , parseEthernetFrame, renderEthernetFrame
  ) where

import Hans.Address.Mac (Mac,parseMac,renderMac)

import Control.Applicative ((<$>),(<*>))
import Data.Serialize.Get (Get,remaining,getWord16be,getBytes)
import Data.Serialize.Put (Putter,Put,putWord16be,putLazyByteString)
import Data.Word (Word16)
import Numeric (showHex)
import qualified Data.ByteString.Lazy as L
import qualified Data.ByteString      as S


-- Ether Type ------------------------------------------------------------------

newtype EtherType = EtherType { getEtherType :: Word16 }
  deriving (Eq,Num,Ord)

instance Show EtherType where
  showsPrec _ (EtherType et) = showString "EtherType 0x" . showHex et

parseEtherType :: Get EtherType
parseEtherType  = EtherType <$> getWord16be

renderEtherType :: Putter EtherType
renderEtherType  = putWord16be . getEtherType


-- Ethernet Frames -------------------------------------------------------------

data EthernetFrame = EthernetFrame
  { etherDest   :: !Mac
  , etherSource :: !Mac
  , etherType   :: !EtherType
  } deriving (Eq,Show)

parseEthernetFrame :: Get (EthernetFrame,S.ByteString)
parseEthernetFrame = (,) <$> header <*> (getBytes =<< remaining)
  where
  header =  EthernetFrame
        <$> parseMac
        <*> parseMac
        <*> parseEtherType

renderEthernetFrame :: EthernetFrame -> L.ByteString -> Put
renderEthernetFrame frame body = do
  renderMac         (etherDest   frame)
  renderMac         (etherSource frame)
  renderEtherType   (etherType   frame)
  putLazyByteString body
