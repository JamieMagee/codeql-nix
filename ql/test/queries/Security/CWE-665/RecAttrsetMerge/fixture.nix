{ }:

let
  # BAD: `rec` attrset on the left-hand side of `//`
  badLeft = rec {
    a = 1;
    b = a + 1;
  } // {
    c = 2;
  };

  # BAD: `rec` attrset on the right-hand side of `//`
  badRight = {
    c = 2;
  } // rec {
    a = 1;
    b = a + 1;
  };

  # BAD: `rec` attrsets on both sides of `//`
  badBoth = rec {
    a = 1;
  } // rec {
    b = 2;
  };

  # BAD: parenthesized `rec` attrset on the left-hand side of `//`
  badParenthesizedLeft = (rec {
    a = 1;
    b = a + 1;
  }) // {
    c = 2;
  };

  # GOOD: plain attrsets merged with `//`
  goodMerge = {
    a = 1;
  } // {
    b = 2;
  };

  # GOOD: recursive attrset used alone
  goodRec = rec {
    a = 1;
    b = a;
  };

  # GOOD: different operator, should not be flagged
  goodOtherOperator = {
    a = 1;
  } ++ [ 1 2 ];
in
{
  inherit
    badLeft badRight badBoth badParenthesizedLeft
    goodMerge goodRec goodOtherOperator;
}
