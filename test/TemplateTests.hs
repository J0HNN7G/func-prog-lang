module TemplateTests (templateTests) where

import Comp.Eval
import Comp.Template
import Comp.TemplateBase
import Lang.Syntax
import Lang.Parser
import Utils.Heap

import Test.Hspec
import Control.Exception (evaluate)

templateTests :: IO ()
templateTests = hspec $ do
  describe "Template" $ do
    describe "compile" $ do
      it "can create an initial template state for a simple program." $ do
        (tiEqual (compile prog1) p1Init) `shouldBe` True

  describe "Eval" $ do
    describe "eval" $ do
      it "can evaluate a simple SKI combinator expression." $ do
        (res.last.eval.compile.parse $ skiProg) `shouldBe` (NNum 3)
    describe "scStep" $ do
      it "throws an error if a supercombinator or primitive has too few arguments." $ do
        evaluate (runProg fewArgProg) `shouldThrow` errorCall "Supercombinator S has too few arguments applied!"

-- | Comparison functions

-- | Check if the given TiStates are equal. 'TiHeap' can only be approximately
-- compared as it holds an infinite list of unused addresses.
tiEqual :: TiState -> TiState -> Bool
tiEqual (stack, dump, heap, globals, stats) (stack', dump', heap', globals', stats')
  = stack == stack'
 && dump  == dump'
 && hEqual heap heap'
 && globals == globals'
 && stats == stats'

-- | Check if given heaps are equal. Unused addresses can only be approximately
-- compared as they are infinite lists.
hEqual :: Eq a => Heap a -> Heap a -> Bool
hEqual (Heap size free accs) (Heap size' free' accs') = size == size'
                                                    && equalInfs free free'
                                                    && accs == accs'

-- | Check if two infinite integer lists are approximately equal (first 10000 elements are equal).
equalInfs :: [Int] -> [Int] -> Bool
equalInfs xs ys = take 10000 xs == take 10000 ys

-- | See the contents a heap (for debugging only).
pprHeap :: Show a => Heap a -> String
pprHeap (Heap size _ accs) = concat ["Heap ", show size, " [..] ", show accs]


-- | 'compile' can handle a simple program (2.3.4).

prog1 :: CoreProgram
prog1 = [ ("main",[],ENum 3)
        , ("g",["x","y"], ELet False [("z",EVar "x")] (EVar "z"))
        , ("h",["x"], ECase (ELet False [("y",EVar "x")] (EVar "y")) [(1,[],ENum 2), (2,[],ENum 5)])]

p1Init :: TiState
p1Init = ( [1]
         , DummyTiDump
         , Heap (9,9,0,0) [10..]
             [ (9, NSupercomb "twice" ["f"] (EAp (EAp (EVar "compose") (EVar "f")) (EVar "f")) )
             , (8, NSupercomb "compose" ["f","g","x"] (EAp (EVar "f") (EAp (EVar "g") (EVar "x"))) )
             , (7, NSupercomb "S" ["f","g","x"] (EAp (EAp (EVar "f") (EVar "x")) (EAp (EVar "g") (EVar "x"))) )
             , (6, NSupercomb "K1" ["x","y"] (EVar "y") )
             , (5, NSupercomb "K" ["x","y"] (EVar "x") )
             , (4, NSupercomb "I" ["x"] (EVar "x") )
             , (3, NSupercomb "h" ["x"] (ECase (ELet False [("y",EVar "x")] (EVar "y")) [(1,[],ENum 2), (2,[],ENum 5)]) )
             , (2, NSupercomb "g" ["x","y"] (ELet False [("z",EVar "x")] (EVar "z")) )
             , (1, NSupercomb "main" [] (ENum 3) )
             ]
         , [ ("main", 1)
           , ("g", 2)
           , ("h", 3)
           , ("I", 4)
           , ("K", 5)
           , ("K1", 6)
           , ("S", 7)
           , ("compose", 8)
           , ("twice", 9)
           ]
         , initialTiStat )


-- | The interpreter can a run a simple program (EX 2.4).
skiProg :: String
skiProg = "main = S K K 3"

-- | The interpreter will throw an error if a supercombinator or primitive has too few arguments (EX 2.5).
fewArgProg :: String
fewArgProg = "main = S K K"
