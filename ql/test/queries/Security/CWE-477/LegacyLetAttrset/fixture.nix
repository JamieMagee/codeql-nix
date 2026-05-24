{
  # BAD: deprecated legacy `let { body = ...; }` attrset syntax.
  bad1 = let { body = 1; };

  # BAD: deprecated legacy syntax with additional bindings.
  bad2 = let { body = a; a = 1; };

  # GOOD: modern `let ... in ...`.
  good1 = let x = 1; in x;

  # GOOD: modern `let ... in ...` with multiple bindings.
  good2 = let x = 1; y = 2; in x + y;

  # GOOD: plain attrset.
  good3 = { a = 1; };
}
