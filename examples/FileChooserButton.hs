{-# LANGUAGE OverloadedLabels  #-}
{-# LANGUAGE OverloadedLists   #-}
{-# LANGUAGE OverloadedStrings #-}

module FileChooserButton where

import           Control.Monad                 (void)
import qualified Data.Text                     as Text

import           GI.Gtk                        (Box (..), Button (..),
                                                FileChooserButton (..),
                                                Label (..), Orientation (..),
                                                Window (..),
                                                fileChooserGetFilename)
import           GI.Gtk.Declarative
import           GI.Gtk.Declarative.App.Simple

data State = Started (Maybe FilePath) | Done FilePath

data Event = FileSelectionChanged (Maybe FilePath) | ButtonClicked | Closed

view' :: State -> AppView Window Event
view' s =
  bin
      Window
      [ #title := "File Chooser Button"
      , on #deleteEvent (const (True, Closed))
      , #widthRequest := 400
      , #heightRequest := 300
      ]
    $ case s of
        Done path ->
          widget Label [#label := (Text.pack path <> " was selected.")]
        Started currentFile -> container
          Box
          [#orientation := OrientationVertical]
          [ BoxChild defaultBoxChildProperties { expand = True, fill = True }
            $ widget
                Label
                [#label := maybe "No file yet." Text.pack currentFile]
          , BoxChild defaultBoxChildProperties { padding = 10 } $ widget
            FileChooserButton
            [ onM #selectionChanged
                  (fmap FileSelectionChanged . fileChooserGetFilename)
            ]
          , BoxChild defaultBoxChildProperties { padding = 10 } $ widget
            Button
            [ #label := "Select"
            , #tooltipText := "Select the chosen file"
            , on #clicked ButtonClicked
            ]
          ]

update' :: State -> Event -> Transition State Event
update' (Started _) (FileSelectionChanged p) =
  Transition (Started p) (return Nothing)
update' (Started (Just path)) ButtonClicked =
  Transition (Done path) (return Nothing)
update' _ Closed = Exit
update' s _      = Transition s (return Nothing)

main :: IO ()
main = void $ run App
  { view         = view'
  , update       = update'
  , inputs       = []
  , initialState = Started Nothing
  }
