/**
 * @name Duplicate attrset key
 * @description Two top-level bindings in the same attribute set literal use the same
 *              static name. Nix rejects duplicate keys when the attrset is
 *              evaluated, causing evaluation failures.
 * @kind problem
 * @problem.severity warning
 * @precision very-high
 * @id nix/duplicate-attrset-key
 * @tags correctness
 *       external/cwe/cwe-710
 *       maintainability
 */

import codeql.nix.Nix

/** Holds if `b` is a binding whose attrpath is a single static-named identifier `name`. */
predicate isSimpleBinding(Binding b, string name) {
  exists(Attrpath ap |
    ap = b.getAttrpath() and
    name = ap.getAttr(0).(Identifier).getValue() and
    not exists(ap.getAttr(1))
  )
}

from BindingSet bs, Binding first, Binding second, string name, int i, int j
where
  exists(Expr attrset | attrsetBindings(attrset, bs)) and
  first = bs.getBinding(i) and
  second = bs.getBinding(j) and
  i < j and
  isSimpleBinding(first, name) and
  isSimpleBinding(second, name)
select second, "Duplicate attrset key `" + name + "`; earlier definition at $@.", first, name
