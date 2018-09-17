{-# LANGUAGE StrictData #-}

module Stellar.Types.Key.Public
  ( PublicKeyType (..)
  , PublicKey (..)
  , parsePublicKey
  , printPublicKey
  , Error (..)
  ) where

import           Control.Monad             (fail)
import           Control.Newtype           (Newtype, pack, unpack)
import qualified Crypto.Error              as CE
import qualified Crypto.PubKey.Ed25519     as ED
import           Data.Aeson                (FromJSON, parseJSON, withText)
import           Data.Binary.Extended
import           Data.Binary.Get           (getByteString, label)
import qualified Data.ByteArray            as BA
import qualified Data.ByteString.Extended  as BS
import           Prelude                   (show)
import           Protolude                 hiding (get, put, show)
import           Stellar.Types.Key.Parser
import           Stellar.Types.Key.Printer
import           Stellar.Types.Key.Version (KeyVersion (AccountId))


data PublicKeyType
  = PublicKeyTypeEd25519
  deriving (Eq, Show, Enum, Bounded)

instance Binary PublicKeyType where
  get = label "PublicKeyType" getEnum
  put = putEnum


newtype PublicKey
  = PublicKeyEd25519
  { _publicKeyEd25519 :: ED.PublicKey
  } deriving (Eq, BA.ByteArrayAccess)

instance Newtype PublicKey ED.PublicKey where
  pack = PublicKeyEd25519
  unpack = _publicKeyEd25519

instance Show PublicKey where
  show (PublicKeyEd25519 pk) =
    "PublicKeyEd25519 {_publicKeyEd25519 = "
    <> BS.showByteString (BA.convert pk) <> "}"

instance Binary PublicKey where
  put (PublicKeyEd25519 edPk) = do
    put PublicKeyTypeEd25519
    putFixLenByteString 32 $ BA.convert edPk
  get = label "PublicKey" $ get
    >>= \case PublicKeyTypeEd25519 -> do
                bs <- getByteString 32
                key <- ED.publicKey bs & CE.onCryptoFailure (fail . show) pure
                pure $ PublicKeyEd25519 key

instance FromJSON PublicKey where
  parseJSON = withText "Stellar Public Key" $
    either (fail . show) pure . parsePublicKey


parsePublicKey :: Text -> Either Error PublicKey
parsePublicKey = fmap PublicKeyEd25519 . fromText AccountId ED.publicKey

printPublicKey :: PublicKey -> Text
printPublicKey = toText AccountId . BA.convert
