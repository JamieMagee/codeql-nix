/**
 * Lexical scope analysis for the Nix expression language.
 *
 * A `Scope` is any AST node that introduces names visible in some
 * lexical region — `let … in body`, `let { … }`, `rec { … }`, and
 * `x: body` / `{ a, b ? d, … }: body` function expressions.
 *
 * `NameReference` is any AST node that uses (rather than defines) a
 * name — a bare `VariableExpression`, or an identifier inside an
 * `inherit name;` clause (which references the same name in the
 * enclosing scope).
 *
 * `resolvesTo(NameReference, Scope)` matches each reference to the
 * lexically closest enclosing scope that defines its name, following
 * Nix's normal name-resolution order. References that fall through all
 * lexical scopes (e.g. top-level inputs, identifiers from a `with`
 * expression, or genuinely unbound names) do not resolve to any Scope.
 *
 * This library does NOT model `with expr; body` — `with` introduces
 * names dynamically based on `expr`'s evaluation, which is outside the
 * scope of static analysis. References that would have been satisfied
 * by a `with` are conservatively treated as resolving to the closer
 * lexical scope if one exists with the same name (which matches Nix's
 * evaluation order — `with` is consulted last).
 */

import codeql.nix.Nix

/**
 * A lexical scope.
 */
class Scope extends AstNode {
  Scope() {
    this instanceof LetExpression or
    this instanceof LetAttrsetExpression or
    this instanceof RecAttrsetExpression or
    this instanceof FunctionExpression
  }

  /**
   * Holds if this scope defines `name`, with `defNode` as the
   * canonical AST node introducing it (the `Identifier` in the
   * attrpath, the `Identifier` in an `inherit` clause, the formal
   * parameter `Identifier`, or the universal-arg `Identifier`).
   */
  predicate definesName(string name, Identifier defNode) {
    // `let X = …;`, `let { X = …; }`, `rec { X = …; }` — direct binding
    exists(BindingSet bs, Binding b, Attrpath ap |
      scopeBindingSet(this, bs) and
      b = bs.getBinding(_) and
      ap = b.getAttrpath() and
      not exists(ap.getAttr(1)) and
      defNode = ap.getAttr(0) and
      name = defNode.getValue()
    )
    or
    // `inherit a b c;`
    exists(BindingSet bs, Inherit inh |
      scopeBindingSet(this, bs) and
      inh = bs.getBinding(_) and
      defNode = inh.getAttrs().getAttr(_) and
      name = defNode.getValue()
    )
    or
    // `inherit (expr) a b c;`
    exists(BindingSet bs, InheritFrom inh |
      scopeBindingSet(this, bs) and
      inh = bs.getBinding(_) and
      defNode = inh.getAttrs().getAttr(_) and
      name = defNode.getValue()
    )
    or
    // `{ a, b ? default, … }: body` — formal parameters
    exists(Formal fml |
      fml = this.(FunctionExpression).getFormals().getFormal(_) and
      defNode = fml.getName() and
      name = defNode.getValue()
    )
    or
    // `x: body` simple, or `{…}@x: body` universal
    defNode = this.(FunctionExpression).getUniversal() and
    name = defNode.getValue()
  }
}

/** Holds if `bs` is the `BindingSet` belonging to `scope`. */
private predicate scopeBindingSet(Scope scope, BindingSet bs) {
  bs = scope.(LetExpression).getChild()
  or
  bs = scope.(LetAttrsetExpression).getChild()
  or
  bs = scope.(RecAttrsetExpression).getChild()
}

/**
 * A use of a name: either a `VariableExpression` (the usual bare
 * identifier in expression position), or an `Identifier` inside a
 * plain `inherit name;` clause (which means "look up `name` in the
 * enclosing scope and bind the result as an attribute here").
 *
 * Does NOT include identifiers inside `inherit (expr) name;` — those
 * are looked up against `expr`, not the enclosing scope.
 *
 * Does NOT include `Identifier`s under an `Attrpath` (those are
 * definition sites, not references).
 */
class NameReference extends AstNode {
  string name;

  NameReference() {
    name = this.(VariableExpression).getName().getValue()
    or
    exists(Inherit inh |
      this = inh.getAttrs().getAttr(_) and
      name = this.(Identifier).getValue()
    )
  }

  /** Gets the name being referenced. */
  string getName() { result = name }
}

/**
 * Gets a strict (non-reflexive) ancestor of `n`.
 *
 * Cached because this transitive ancestor relation is the inner loop
 * of `resolvesTo` (and therefore of every flow predicate built on top).
 * Materialising it once across the whole database is cheaper than
 * re-evaluating it for each call site.
 */
cached
private AstNode getAStrictAncestor(AstNode n) {
  result = n.getParent()
  or
  result = getAStrictAncestor(n.getParent())
}

/**
 * Holds if `ref` is an Identifier inside an `inherit name;` clause
 * whose direct enclosing scope is `enclosingScope`.
 *
 * An inherit-reference looks up the name in the scope *enclosing* its
 * own binding-set's scope: `let inherit x; in x` references the outer
 * scope's `x`, even though the let itself defines `x` via this very
 * `inherit` clause.
 */
private predicate isInheritReferenceInScope(NameReference ref, Scope enclosingScope) {
  exists(Inherit inh, BindingSet bs |
    ref = inh.getAttrs().getAttr(_) and
    bs = inh.getParent() and
    scopeBindingSet(enclosingScope, bs)
  )
}

/**
 * Holds if `scope` is a lexical scope visible from `ref` for the
 * purposes of name resolution — any strict ancestor scope, except
 * when `ref` is an inherit-reference, in which case the scope that
 * encloses the inherit itself is skipped (the inherit's `name` looks
 * up the value in the surrounding scope, not in the scope it's
 * defining into).
 */
private predicate isVisibleScope(NameReference ref, Scope scope) {
  scope = getAStrictAncestor(ref) and
  not isInheritReferenceInScope(ref, scope)
}

/**
 * Holds if `scope` is `ref`'s closest visible enclosing scope that
 * defines `ref.getName()`.
 *
 * If no enclosing lexical scope defines the name, `resolvesTo` has no
 * result for that reference — meaning the name is either a top-level
 * input, a builtin, or a `with`-introduced attribute.
 */
cached
predicate resolvesTo(NameReference ref, Scope scope) {
  scope.definesName(ref.getName(), _) and
  isVisibleScope(ref, scope) and
  not exists(Scope closer |
    closer.definesName(ref.getName(), _) and
    isVisibleScope(ref, closer) and
    scope = getAStrictAncestor(closer)
  )
}

/**
 * Holds if `name` is a conventional `mkDerivation` callback-argument
 * name (`finalAttrs`, `prevAttrs`, `oldAttrs`). These are introduced
 * by the `overrideAttrs` callback contract and may be declared even
 * when the package body itself does not reference them — external
 * `overrideAttrs` callers can still observe them through the callback
 * shape. Treat them as exempt from `UnusedBinding`, matching deadnix's
 * documented policy on callback arguments.
 */
predicate isCallbackArgName(string name) { name = ["finalAttrs", "prevAttrs", "oldAttrs"] }

/**
 * Holds if `scope` defines `name` at `defNode` but no in-scope
 * `NameReference` resolves there.
 *
 * Identifiers starting with `_` are exempt by the deadnix convention.
 *
 * Conventional `mkDerivation` callback-argument names (`finalAttrs`,
 * `prevAttrs`, `oldAttrs`) are exempt — they may be declared for
 * `overrideAttrs` callers even when not used in the body.
 *
 * Bindings inside a `rec { … }` attrset are exempt, because the whole
 * attrset is externally accessible — a `rec` binding that isn't used
 * by another binding in the same block may still be used by an
 * external `.attribute` access we cannot see statically.
 *
 * The `body` attribute of a legacy `let { … }` attrset is exempt for
 * the same reason: it IS the externally-visible result.
 */
predicate isUnusedBinding(Scope scope, string name, Identifier defNode) {
  scope.definesName(name, defNode) and
  not exists(NameReference ref | ref.getName() = name and resolvesTo(ref, scope)) and
  not name.regexpMatch("^_.*") and
  not isCallbackArgName(name) and
  not scope instanceof RecAttrsetExpression and
  not (scope instanceof LetAttrsetExpression and name = "body")
}
