let
  # BAD: x defined but never used
  unusedLetBinding = let
    x = 1;
    y = 2;
  in
  y;

  # GOOD: both bindings used
  goodLetBinding = let
    x = 1;
    y = 2;
  in
  x + y;

  # BAD: function formal `b` is unused
  unusedFormal = { a, b, c }: a + c;

  # GOOD: all formals used
  usedFormals = { a, b, c }: a + b + c;

  # GOOD: underscore prefix exempts the binding
  underscoreExempt = { _module, _ignore, p, ... }: p;

  # NEUTRAL: rec-attrset bindings are NEVER flagged (externally visible)
  recExempt1 = rec {
    helper = "internal";
    public = "exported";
  };
  recExempt2 = rec {
    helper = "internal";
    public = helper + " then exported";
  };

  # BAD: inherit `helper` inside an inner let, never referenced
  unusedInherit = let
    helper = 1;
    bar = 2;
  in
  let
    inherit helper;
  in
  bar;

  # GOOD: inherit `helper` inside inner let, referenced via the inner-let body
  usedInherit = let
    helper = 1;
    bar = 2;
  in
  let
    inherit helper;
  in
  helper + bar;

  # GOOD: simple lambda parameter is used
  usedLambdaParam = x: x + 1;

  # BAD: simple lambda parameter is unused
  unusedLambdaParam = x: 42;

  # GOOD: nested let — inner `x` shadows outer `x`; outer is used before the shadow
  shadowedButUsed = let
    x = 1;
  in
  x + (let
    x = 2;
  in
  x);

  # BAD: nested let — outer `x` is shadowed and never referenced (inner body
  # only references inner `x`)
  shadowedAndUnused = let
    x = 1;
  in
  let
    x = 2;
  in
  x;

  # GOOD: function returns its `inherit`-ed attribute set — `a` and `b` are
  # both used by the inherit (the inherit Identifier counts as a reference).
  inheritsParamsBack = { a, b }: { inherit a b; };
in
{
  inherit
    unusedLetBinding goodLetBinding
    unusedFormal usedFormals underscoreExempt
    recExempt1 recExempt2
    unusedInherit usedInherit
    usedLambdaParam unusedLambdaParam
    shadowedButUsed shadowedAndUnused
    inheritsParamsBack;
}
