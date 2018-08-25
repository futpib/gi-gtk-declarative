{-# LANGUAGE OverloadedLabels  #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

module AddBoxes where

import qualified Data.Text                     as Text

import           GI.Gtk                        (Box (..), Button (..),
                                                Label (..), Orientation (..),
                                                PolicyType (..),
                                                ScrolledWindow (..))
import           GI.Gtk.Declarative
import           GI.Gtk.Declarative.App.Simple


data Event = AddLeft | AddRight

data Model = Model { lefts :: [Int], rights :: [Int], next :: Int }

addBoxesView :: Model -> Widget Event
addBoxesView Model {..} = container
  ScrolledWindow
  [ #hscrollbarPolicy := PolicyTypeAutomatic
  , #vscrollbarPolicy := PolicyTypeNever
  ]
  windowContents
 where
  windowContents :: Widget Event
  windowContents = container Box [#orientation := OrientationVertical] $ do
    renderLane AddLeft  lefts
    renderLane AddRight rights
  renderLane :: Event -> [Int] -> MarkupOf BoxChild Event ()
  renderLane onClick children = boxChild True True 10 $ do
    container Box [] $ do
      boxChild False False 10 $ do
        node Button [#label := "Add", on #clicked onClick]
      (mapM_ (boxChild False False 0 . renderChild) children)
  renderChild :: Int -> Widget Event
  renderChild n =
    node Label [#label := Text.pack ("Box " <> show n)]

update' :: Model -> Event -> (Model, IO (Maybe Event))
update' model@Model {..} AddLeft =
  (model { lefts = lefts ++ [next], next = succ next }, return Nothing)
update' model@Model {..} AddRight =
  (model { rights = rights ++ [next], next = succ next }, return Nothing)

main :: IO ()
main =
  let app = App {view = addBoxesView, update = update', inputs = []}
  in run "AddBoxes" (Just (640, 480)) app (Model [1] [2] 3)
