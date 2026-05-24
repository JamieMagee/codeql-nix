let
  badAttrset = {
    a = 1;
    a = 2;
  };

  badRec = rec {
    dup1 = {
      a = 1;
      a = 2;
    };
  };

  goodNested = {
    a.b = 1;
    a.c = 2;
  };

  x = "a";

  goodDynamic = {
    "${x}" = 1;
    "${x}" = 2;
  };

  goodQuoted = {
    "a" = 1;
    "a" = 2;
  };

  goodSingle = {
    a = 1;
  };

  outer = {
    a = 1;
  };

  inner = {
    a = 2;
  };
in
outer
