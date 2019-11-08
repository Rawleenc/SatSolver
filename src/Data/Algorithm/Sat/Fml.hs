module Data.Algorithm.Sat.Fml (
    -- * Type
    Fml (..)

    -- * Creating
    , mkVar
    -- * Converting
    , toCNF
    -- * Querying
    , vars
    -- * Showing
    , prettyPrinter
) where

import qualified Data.Algorithm.Sat.Var as Var
import qualified Data.List as List

data Fml a = Or     (Fml a) (Fml a)
           | And    (Fml a) (Fml a)
           | Imply  (Fml a) (Fml a)
           | Equiv  (Fml a) (Fml a)
           | XOr    (Fml a) (Fml a)
           | Not    (Fml a)
           | Final  (Var.Var a)
           deriving (Show,Eq,Ord)

toCNF :: Fml a-> Fml a
toCNF f
    | Equiv a b         <- f = And (Or (toCNF a) (Not (toCNF b))) (Or (Not (toCNF a)) (toCNF b))
    | XOr   a b         <- f = And (Or (toCNF a) (toCNF b)) (Or (Not (toCNF a)) (Not (toCNF b)))
    | And   a (Or b  c) <- f = Or  (And (toCNF a) (toCNF b)) (And (toCNF a) (toCNF c))
    | Or    a (And b c) <- f = And (Or  (toCNF a) (toCNF b)) (Or  (toCNF a) (toCNF c))
    | Imply a b         <- f = Or  (Not (toCNF a)) (toCNF b)
    | Or    a b         <- f = Or  (toCNF a) (toCNF b)
    | And   a b         <- f = And (toCNF a) (toCNF b)
    | Not   a           <- f = Not (toCNF a)
    | Final a           <- f = f

getVars :: Fml a -> [Var.Var a]
getVars f
    | Or a b    <- f = getVars a ++ getVars b
    | And a b   <- f = getVars a ++ getVars b
    | Imply a b <- f = getVars a ++ getVars b
    | Equiv a b <- f = getVars a ++ getVars b
    | XOr a b   <- f = getVars a ++ getVars b
    | Not a     <- f = getVars a
    | Final a   <- f = [a]

vars :: (Eq a) => Fml a -> [Var.Var a]
vars f = List.nub (getVars f)

prettyPrinter :: (Show a) => Fml a -> String
prettyPrinter f
    | Or    a b <- f = "("    ++ prettyPrinter a ++ " OR "    ++ prettyPrinter b ++ ")"
    | And   a b <- f = "("    ++ prettyPrinter a ++ " AND "   ++ prettyPrinter b ++ ")"
    | Imply a b <- f = "("    ++ prettyPrinter a ++ " IMPLY " ++ prettyPrinter b ++ ")"
    | Equiv a b <- f = "("    ++ prettyPrinter a ++ " EQUIV " ++ prettyPrinter b ++ ")"
    | XOr   a b <- f = "("    ++ prettyPrinter a ++ " XOR "   ++ prettyPrinter b ++ ")"
    | Not   a   <- f = "NOT " ++ prettyPrinter a
    | Final a   <- f = show a

mkVar :: a -> Fml a
mkVar a = Final (Var.mk a)

multOr :: [Fml a] -> Fml a
multOr [f] = f
multOr (f:fs) = Or f (multOr fs)

multAnd :: [Fml a] -> Fml a
multAnd [f] = f
multAnd (f:fs) = And f (multAnd fs)