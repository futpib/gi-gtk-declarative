{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE RecordWildCards #-}
module MainLoop
  ( App(..)
  , runInWindow
  )
where

import           Data.Typeable
import           Control.Concurrent
import           Control.Concurrent.Async                 ( race )
import           Control.Monad
import qualified GI.Gdk                        as Gdk
import qualified GI.GLib.Constants             as GLib
import           GI.Gtk.Declarative                hiding ( main )
import qualified GI.Gtk.Declarative            as Gtk
import           GI.Gtk.Declarative.EventSource

runUI :: IO a -> IO a
runUI f = do
  r <- newEmptyMVar
  void . Gdk.threadsAddIdle GLib.PRIORITY_DEFAULT $ do
    f >>= putMVar r
    return False
  takeMVar r

data App model event =
  App
    { update :: model -> event -> (model, IO (Maybe event))
    , view :: model -> Markup event
    , input :: Chan event
    }

runInWindow :: Typeable event => Gtk.Window -> App model event -> model -> IO ()
runInWindow window App {..} initialModel = do
  let firstMarkup = view initialModel
  subscription <- runUI $ do
    widget <- Gtk.toWidget =<< create firstMarkup
    Gtk.containerAdd window widget
    Gtk.widgetShowAll window
    subscribe firstMarkup widget
  loop firstMarkup subscription initialModel
 where
  loop oldMarkup oldSubscription oldModel = do
    event <- either return return
      =<< race (readChan (events oldSubscription)) (readChan input)
    let (newModel, action) = update oldModel event
        newMarkup          = view newModel
    sub <-
      runUI (patchContainer window oldMarkup newMarkup) >>= \case
        Just newSubscription -> cancel oldSubscription *> pure newSubscription
        Nothing -> pure oldSubscription
    void . forkIO $ action >>= maybe (return ()) (writeChan input)
    loop newMarkup sub newModel

patchContainer
  :: Typeable event
  => Gtk.Window
  -> Markup event
  -> Markup event
  -> IO (Maybe (Subscription event))
patchContainer w o1 o2 = case patch o1 o2 of
  Modify f -> Gtk.containerGetChildren w >>= \case
    []      -> return Nothing
    (c : _) -> do
      widget <- Gtk.toWidget c
      f widget
      Gtk.widgetShowAll w
      Just <$> subscribe o2 widget
  Replace createNew -> do
    Gtk.containerForall w (Gtk.containerRemove w)
    newWidget <- createNew
    Gtk.containerAdd w newWidget
    Gtk.widgetShowAll w
    Just <$> subscribe o2 newWidget
  Keep -> return Nothing
