module Handler.Snippets where

import Import
import Model.Snippet.Api (listSnippets, listSnippetsByLanguage)
import Data.List (nub)
import Util.Handler (pageNo, title)
import Util.Snippet (iso8601Format)
import Widget.Pagination (paginationWidget)

getSnippetsR :: Handler Html
getSnippetsR = do
    currentPage <- pageNo <$> lookupGetParam "page"
    mLanguage <- lookupGetParam "language"
    (snippets, pagination) <- case mLanguage of
        Just lang ->
            liftIO $ listSnippetsByLanguage lang currentPage Nothing
        Nothing ->
            liftIO $ listSnippets currentPage Nothing
    profiles <- fetchProfiles $ nub $ map metaSnippetOwner snippets
    defaultLayout $ do
        setTitle $ title "Public snippets"
        $(widgetFile "snippets")

fetchProfiles :: [Text] -> Handler [Profile]
fetchProfiles owners = do
    entities <- runDB $ selectList [ProfileSnippetsApiId <-. owners] []
    return $ map (\(Entity _ x) -> x) entities

ownerName :: Text -> [Profile] -> Text
ownerName "anonymous" _ = "Anonymous"
ownerName ownerId profiles =
    case find (\x -> profileSnippetsApiId x == ownerId) profiles of
        Just profile -> profileName profile
        Nothing -> "Unknown"

ownerUsername :: Text -> [Profile] -> Maybe Text
ownerUsername ownerId profiles =
    profileUsername <$> find (\x -> profileSnippetsApiId x == ownerId) profiles
