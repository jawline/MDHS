module Paragraph where
import Util
import Link

isParagraphEnd :: Char -> Bool
isParagraphEnd '\n' = True
isParagraphEnd n = False

transformParagraphInt :: String -> (String, String)
transformParagraphInt [] = ([], [])
transformParagraphInt (x:xs)
  | isParagraphEnd x = ([], xs)
  | isStartOfLink x = (link, remainingAfterLink)
  | otherwise = (x:paragraph, remaining)
    where
      (paragraph, remaining) = (transformParagraphInt xs)
      Just (link, remainingAfterLink) = (transformLink xs)

transformParagraph :: String -> (String, String)
transformParagraph source = ("<p>" ++ (trim paragraph) ++ "</p>", remaining)
  where
    (paragraph, remaining) = (transformParagraphInt source)