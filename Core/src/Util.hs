module Util where
import Data.Char
import System.IO.Error (tryIOError)
import Data.Time.Clock.POSIX
import Data.Time.Clock
import Data.Time.Format
import Text.Printf

if' :: Bool -> a -> a -> a
if' True  x _ = x
if' False _ y = y

splitAt' _ [] = ([], [])
splitAt' target (x:xs)
  | x == target = ([], xs)
  | otherwise = (x:follows, rest)
  where
    (follows, rest) = splitAt' target xs

urlEncodeChar :: Char -> String
urlEncodeChar x = printf "&#%04i;" (ord x)

shouldEncode :: Char -> Bool
shouldEncode '<' = True
shouldEncode '>' = True
shouldEncode _ = False

urlEncode [] = []
urlEncode (x:xs)
  | shouldEncode x = (urlEncodeChar x) ++ (urlEncode xs)
  | otherwise = x:(urlEncode xs)

{-|
 Read all of input from stdin
-}
input :: IO String
input = do
  c <- tryIOError getChar
  case c of
    Right(c) -> do
      remain <- input
      return (c:remain)
    Left(_) ->
      return []

{-|
 Some time strings include a floating point (they include milliseconds)
 Truncate that time string to a integer
-}
truncateStringAt :: Char -> String -> String
truncateStringAt _ [] = []
truncateStringAt delim (x:xs)
  | delim == x = []
  | otherwise = x:(truncateStringAt delim xs)

{-|
 - If convert the article time string to epoch time (since it may be either epoch time or a date string)
 -}
asUTCTime :: String -> UTCTime
asUTCTime timeStr
  | all isDigit truncatedTimeStr = timestamp 
  | otherwise = parseTimeOrError True defaultTimeLocale "%d-%m-%Y" timeStr
  where truncatedTimeStr = truncateStringAt '.' timeStr
        timeFloat = read truncatedTimeStr :: Float
        truncMilli = round timeFloat
        timestamp = posixSecondsToUTCTime $ fromInteger truncMilli

{-|
 If the time string at the top of an article is in epoch time we convert it to a d-m-Y string
 Otherwise, we leave it as is and print it directly into the article
-}
showTime :: String -> String
showTime timeStr = formatTime defaultTimeLocale "%d-%m-%Y" (asUTCTime timeStr)

endOfLine :: String -> String
endOfLine [] = []
endOfLine ('\n':xs) = []
endOfLine (x:xs) = x:(endOfLine xs)

matches :: String -> String -> Bool
matches target string = take (length target) string == target

type StringReplacer = (String, String)

{-|
 - Replace a target string with another in the source string
 - Arguments: source target replaceWith
 -}
replaceInString :: String -> StringReplacer -> String
replaceInString [] _ = []
replaceInString (x:xs) (target,with)
  | matches target (x:xs) = replaceInString (with ++ (drop (length target) (x:xs))) (target,with)
  | otherwise = x:(replaceInString xs (target,with))

{-|
  Applies a series of string replacements to a target string from left to right
-}
multiReplaceInString :: String -> [StringReplacer] -> String
multiReplaceInString origin [] = origin
multiReplaceInString origin (replacer:xs) = multiReplaceInString (replaceInString origin replacer) xs

readToNext :: String -> (String -> Bool) -> Maybe (String, String)
readToNext [] _        = Nothing
readToNext (x:xs) y = if y(x:xs)
  then Just ([], xs)
  else case (readToNext xs y) of
    Just (part1, remaining) -> Just (x:part1, remaining)
    Nothing -> Nothing

trimWhiteLine :: String -> String
trimWhiteLine [] = []
trimWhiteLine('\n':xs) = ('\n':xs)
trimWhiteLine (x:xs) = if isSpace x then (trimWhiteLine xs) else (x:xs)

trimLeft :: String -> String
trimLeft [] = []
trimLeft (x:xs)
  | isSpace x = xs
  | otherwise = (x:xs)

trimRight :: String -> String
trimRight xs = reverse (trimLeft (reverse xs))

trim :: String -> String
trim xs = trimRight (trimLeft xs)

skipLine :: String -> String
skipLine [] = []
skipLine ('\n':xs) = xs
skipLine (x:xs) = skipLine xs

fromString :: String -> String -> String
fromString target (x:xs) =
  case matches target (x:xs) of
    True -> (x:xs)
    False -> fromString target xs

untilString :: String -> String -> String
untilString target xs = reverse (fromString (reverse target) (reverse xs))

findLine :: String -> String -> String
findLine target source = endOfLine (fromString target source)

unique [] = []
unique (x:xs) = if elem x r then r else x:r
  where r = unique xs 

titleToFilename [] = ""
titleToFilename (' ':xs) = '_':(titleToFilename xs)
titleToFilename (x:xs) 
  | (isLetter x) || (isNumber x) = x:(titleToFilename xs)
  | otherwise = titleToFilename xs

indexedReverse [] = []
indexedReverse (x:[]) = [(0, x)]
indexedReverse (x:xs) = (l + 1, x):(indexedReverse xs)
  where
    ((l, _):_) = indexedReverse xs

indexed xs = reverse (indexedReverse (reverse xs))

removeAll :: (Eq a) => a -> [a] -> [a]
removeAll _ [] = []
removeAll t (x:xs)
  | t == x = removeAll t xs
  | otherwise = x:(removeAll t xs)

dedup :: (Eq a) => [a] -> [a]
dedup [] = []
dedup (x:xs) = x:(removeAll x xs)
