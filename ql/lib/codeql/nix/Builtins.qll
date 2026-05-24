/**
 * Recognition of Nix builtin function calls — `builtins.X` and
 * (best-effort) bare `X` references under a `with builtins;` scope.
 *
 * Used by queries that target specific builtin behaviour such as
 * `builtins.getEnv` (impurity), `builtins.fetchTarball` (supply-chain
 * hygiene, see `Fetchers.qll`), and so on.
 *
 * The dotted form (`builtins.X`) is precise. The bare form is detected
 * best-effort using the textual ancestor presence of `with builtins;`
 * and does NOT account for inner shadowing — e.g. `with builtins; let
 * getEnv = x: x; in getEnv "X"` would falsely match. This is an
 * acceptable Phase 1 trade-off; full scope resolution lands with the
 * `Scope.qll` library in Phase 2.
 */

import codeql.nix.Nix

/**
 * Holds if `call` is a `builtins.<name> ARG` invocation: a function
 * application whose function position is a single-step attribute
 * select from a variable named `builtins`.
 *
 * Does NOT match deeper paths like `pkgs.builtins.foo` or
 * `builtins.foo.bar` — the dotted prefix must be exactly `builtins.X`.
 */
predicate isDottedBuiltinCall(ApplyExpression call, string name) {
  exists(SelectExpression sel, Attrpath ap |
    sel = call.getFunction() and
    ap = sel.getAttrpath() and
    sel.getExpression().(VariableExpression).getName().getValue() = "builtins" and
    name = ap.getAttr(0).(Identifier).getValue() and
    not exists(ap.getAttr(1))
  )
}

/**
 * Holds if `call` is a bare `<name> ARG` invocation that occurs
 * textually inside the body of a `with builtins;` expression.
 *
 * Best-effort: does not check for inner shadowing (e.g. an inner
 * `let name = …; in …` will produce a false positive here).
 */
predicate isBareBuiltinCallUnderWith(ApplyExpression call, string name) {
  name = call.getFunction().(VariableExpression).getName().getValue() and
  exists(WithExpression w |
    w.getEnvironment().(VariableExpression).getName().getValue() = "builtins" and
    isStrictDescendantOf(call, w.getBody())
  )
}

/**
 * Holds if `n` is the same node as, or transitively a child of, `ancestor`.
 *
 * Helper for `isBareBuiltinCallUnderWith` — kept local because it has
 * O(depth) cost and we only want the cost paid on the small subset of
 * calls whose function-position is a bare identifier.
 */
private predicate isStrictDescendantOf(AstNode n, AstNode ancestor) {
  n = ancestor
  or
  isStrictDescendantOf(n.getParent(), ancestor)
}

/**
 * A call to a Nix builtin function `builtins.<name>` or (best-effort)
 * a bare `<name>` under a `with builtins;`.
 */
class BuiltinCall extends ApplyExpression {
  string name;

  BuiltinCall() {
    isDottedBuiltinCall(this, name)
    or
    isBareBuiltinCallUnderWith(this, name)
  }

  /** Gets the name of the called builtin (e.g. `"getEnv"`, `"fetchTarball"`). */
  string getName() { result = name }
}
