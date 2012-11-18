--------------------------------------------------------------------------------
module Hakyll.Core.Provider.Internal
    ( Provider (..)
    , newProvider

    , resourceList
    , resourceExists
    , resourceMetadataResource

    , resourceString
    , resourceLBS
    ) where


--------------------------------------------------------------------------------
import           Control.Applicative   ((<$>))
import qualified Data.ByteString.Lazy  as BL
import           Data.IORef
import           Data.Map              (Map)
import qualified Data.Map              as M
import           Data.Set              (Set)
import qualified Data.Set              as S
import           System.FilePath       (addExtension)


--------------------------------------------------------------------------------
import           Hakyll.Core.Store
import           Hakyll.Core.Util.File
import           Hakyll.Core.Identifier


--------------------------------------------------------------------------------
-- | Responsible for retrieving and listing resources
data Provider = Provider
    { -- | A list of all files found
      providerSet           :: Set Identifier
    , -- | Cache keeping track of modified files
      providerModifiedCache :: IORef (Map Identifier Bool)
    , -- | Underlying persistent store for caching
      providerStore         :: Store
    }


--------------------------------------------------------------------------------
-- | Create a resource provider
newProvider :: Store               -- ^ Store to use
            -> (FilePath -> Bool)  -- ^ Should we ignore this file?
            -> FilePath            -- ^ Search directory
            -> IO Provider         -- ^ Resulting provider
newProvider store ignore directory = do
    list  <- map fromFilePath . filter (not . ignore) <$>
        getRecursiveContents False directory
    cache <- newIORef M.empty
    return $ Provider (S.fromList list) cache store


--------------------------------------------------------------------------------
resourceList :: Provider -> [Identifier]
resourceList = S.toList . providerSet


--------------------------------------------------------------------------------
-- | Check if a given resource exists
resourceExists :: Provider -> Identifier -> Bool
resourceExists provider =
    (`S.member` providerSet provider) . setVersion Nothing


--------------------------------------------------------------------------------
-- | Each resource may have an associated metadata resource (with a @.metadata@
-- filename)
resourceMetadataResource :: Identifier -> Identifier
resourceMetadataResource =
    fromFilePath . flip addExtension "metadata" . toFilePath


--------------------------------------------------------------------------------
-- | Get the raw body of a resource as string
resourceString :: Identifier -> IO String
resourceString = readFile . toFilePath


--------------------------------------------------------------------------------
-- | Get the raw body of a resource of a lazy bytestring
resourceLBS :: Identifier -> IO BL.ByteString
resourceLBS = BL.readFile . toFilePath