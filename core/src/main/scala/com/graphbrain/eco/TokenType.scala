package com.graphbrain.eco

object TokenType extends Enumeration {
  type TokenType = Value
	val Unknown,
      Symbol,
      Number,
      String,
      Consequence,
      LPar,
      RPar,
      LSPar,
      RSPar,
      Quote,
      Colon,
      Plus,
      Minus,
      Mul,
      Div = Value
}