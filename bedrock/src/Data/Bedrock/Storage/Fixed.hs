module Data.Bedrock.Storage.Fixed where

import Data.Bedrock
import Data.Bedrock.Storage.Pluggable
import           LLVM.AST.Type          as LLVM

{- Allocate a fixed buffer at program start, bump allocate into it.

gc_init =
    pagesize <- sysconf _SC_PAGESIZE;
    mem <- @ccall mmap(null, 1024*pagesize, PROT_READ|PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS , -1, 0);
    writeGlobal "hp" mem

gc_allocate n =
    return success

-}

fixedGC :: GC StorageManager
fixedGC = do
    pushForeign $ Foreign
        { foreignName = "calloc"
        , foreignReturn = ptr i8
        , foreignArguments = [i32, i32] }
    initName <- newName "fixed_gc_init"
    rawPtr <- newVariable "ptr" (Primitive (ptr i8))
    hp <- newVariable "hp" NodePtr
    wordSize <- newVariable "size" (Primitive i32)
    heapSize <- newVariable "heapSize" (Primitive i32)
    beginName <- newName "fixed_gc_begin"
    endName <- newName "fixed_gc_end"
    markName <- newName "fixed_gc_mark"
    markFrameName <- newName "fixed_gc_mark_frame"
    markPtr  <- newVariable "root" NodePtr
    markFrame  <- newVariable "frame" FramePtr
    let initFn = Function initName [] [] [] $
            Bind [wordSize] (Literal (LiteralInt 8)) $
            Bind [heapSize] (Literal (LiteralInt 134217728)) $
            Bind [rawPtr] (CCall "calloc" [heapSize, wordSize]) $
            Bind [hp] (TypeCast rawPtr) $
            Bind [] (WriteGlobal "hp" hp) $
            Return []
        beginFn = Function beginName [] [] [] $
            Panic "FixedGC: Collection not supported!"
        endFn = Function endName [] [] [NodePtr] $
            Panic "FixedGC: Collection not supported!"
        markFn = Function markName [] [markPtr] [NodePtr] $
            Panic "FixedGC: Collection not supported!"
        markFrameFn = Function markFrameName [] [markFrame] [FramePtr] $
            Panic "FixedGC: Collection not supported!"
        allocate _hp _size = Literal (LiteralInt 1)
    return StorageManager
        { smInit     = initFn
        , smBegin    = beginFn
        , smEnd      = endFn
        , smMark     = markFn
        , smMarkFrame = markFrameFn
        , smAllocate = allocate
        }
