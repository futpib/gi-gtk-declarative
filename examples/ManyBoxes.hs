{-# LANGUAGE OverloadedLabels  #-}
{-# LANGUAGE OverloadedLists   #-}
{-# LANGUAGE OverloadedStrings #-}

module ManyBoxes where

import           Control.Monad                 (void)
import           Data.Functor                  ((<&>))
import           Data.Text                     (pack)
import           Data.Vector                   (Vector)
import qualified Data.Vector                   as Vector

import           GI.Gtk                        (Box (..), Button (..),
                                                ScrolledWindow (..),
                                                Window (..))
import           GI.Gtk.Declarative
import           GI.Gtk.Declarative.App.Simple

type State = Vector Int

data Event
  = IncrAll
  | Closed

view' :: State -> AppView Window Event
view' ns =
  bin
      Window
      [ #title := "Many Boxes"
      , on #deleteEvent (const (True, Closed))
      , #widthRequest := 400
      , #heightRequest := 300
      ]
    $   bin ScrolledWindow []
    $   container Box []
    $   ns
    <&> \n -> BoxChild defaultBoxChildProperties { padding = 10 }
          $ widget Button [#label := pack (show n), on #clicked IncrAll]

update' :: State -> Event -> Transition State Event
update' ns IncrAll = Transition (succ <$> ns) (return Nothing)
update' _ Closed   = Exit

main :: IO ()
main = void $ run App
  { view         = view'
  , update       = update'
  , inputs       = []
  , initialState = Vector.enumFromN 0 500
  }
