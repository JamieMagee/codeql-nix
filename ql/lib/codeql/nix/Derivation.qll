/**
 * Recognises calls to nixpkgs-style derivation wrappers
 * (`stdenv.mkDerivation`, `stdenvNoCC.mkDerivation`,
 * `buildPythonPackage`, `buildPythonApplication`) and exposes a small
 * API for inspecting the derivation's top-level attribute set.
 *
 * The wrapper list deliberately matches `nixpkgs-hammering`'s scope so
 * that downstream lints inherit the same false-positive characteristics
 * as the upstream linter. Broader recognition (`buildGoModule`,
 * `buildRustPackage`, `buildNpmPackage`, `mkYarnPackage`, …) is a
 * Phase 3b candidate — it requires wrapper-specific attr allowlists for
 * `AttributeTypo` and `AttributeOrdering` to remain low-noise.
 *
 * `DerivationCall.getAttrs` peels through parens, the
 * `(finalAttrs: { … })` callback shape (used by `mkDerivation`'s
 * `finalAttrs` /`overrideAttrs` contract), and `let … in { … }` bodies.
 * It does NOT attempt to follow `with`-bound identifiers or other
 * dynamic shapes.
 *
 * There is intentionally no `getEnclosingDerivation(AstNode)` predicate
 * — the Phase 2 performance retrospective documents how a recursive
 * ancestor-of-any-node predicate joined against the whole AST is a
 * predictable performance trap on full nixpkgs. Queries that need to
 * walk a derivation drive from `DerivationCall` → `getADirectBinding`
 * → the binding's RHS.
 */

import codeql.nix.Nix

/**
 * Holds if `name` is a derivation wrapper recognised by this library.
 * Used by the `DerivationCall` selector for the variable-application
 * shape (`buildPythonPackage args`).
 */
predicate isDerivationWrapperName(string name) {
  name = ["buildPythonPackage", "buildPythonApplication"]
}

/**
 * Holds if `apply` matches the dotted shape `<stdenv>.mkDerivation arg`
 * where `<stdenv>` is `stdenv` or `stdenvNoCC`. Captures the stdenv
 * variable name in `stdenvName` so the kind can be reported back to
 * the user.
 *
 * Recognises both `stdenv.mkDerivation` (single-segment attrpath with
 * `stdenv` as the SelectExpression's LHS) and the deeper form
 * `pkgs.stdenv.mkDerivation` (multi-segment attrpath; the immediate
 * predecessor of `mkDerivation` is `stdenv`).
 */
private predicate isStdenvMkDerivationCall(ApplyExpression apply, string stdenvName) {
  exists(SelectExpression sel, Attrpath ap, int last |
    sel = apply.getFunction() and
    ap = sel.getAttrpath() and
    ap.getAttr(last).(Identifier).getValue() = "mkDerivation" and
    not exists(ap.getAttr(last + 1)) and
    (
      // `stdenv.mkDerivation`: single-segment attrpath, stdenv is the LHS
      last = 0 and
      stdenvName = sel.getExpression().(VariableExpression).getName().getValue()
      or
      // `pkgs.stdenv.mkDerivation` etc.: multi-segment, stdenv is the predecessor
      last > 0 and
      stdenvName = ap.getAttr(last - 1).(Identifier).getValue()
    ) and
    stdenvName = ["stdenv", "stdenvNoCC"]
  )
}

/**
 * A call to one of the `nixpkgs-hammering`-recognised derivation
 * wrappers. The set is:
 *   - `stdenv.mkDerivation arg`
 *   - `stdenvNoCC.mkDerivation arg`
 *   - `buildPythonPackage arg`
 *   - `buildPythonApplication arg`
 *
 * `arg` is the actual derivation attrset and may be wrapped in parens,
 * a `finalAttrs:` callback, or a `let … in …` — use `getAttrs` to peel.
 */
class DerivationCall extends ApplyExpression {
  string kind;

  DerivationCall() {
    isStdenvMkDerivationCall(this, kind)
    or
    exists(VariableExpression v, string name |
      v = this.getFunction() and
      name = v.getName().getValue() and
      isDerivationWrapperName(name) and
      kind = name
    )
  }

  /**
   * Gets the wrapper name used to invoke this derivation
   * (`mkDerivation`, `buildPythonPackage`, …). Suitable for user-facing
   * messages.
   */
  string getKind() { result = kind }

  /**
   * Gets the attrset literal — either a non-recursive `{ … }` or a
   * recursive `rec { … }` — that holds this derivation's top-level
   * attributes.
   *
   * Peels through:
   *   - parens: `mkDerivation ( { … } )`
   *   - callback: `mkDerivation (finalAttrs: { … })`
   *   - callback + rec: `mkDerivation (finalAttrs: rec { … })`
   *   - let-in body: `mkDerivation (let helper = …; in { … })`
   *   - nested combinations of the above
   *
   * Returns no result when the argument isn't statically a literal
   * attrset (e.g. `mkDerivation (callPackage ./. {})` — uncommon).
   */
  Expr getAttrs() { result = peelToAttrset(this.getArgument()) }

  /**
   * Gets the `BindingSet` (sequence of `name = …;` and `inherit …;`
   * clauses) for this derivation's top-level attribute set.
   */
  BindingSet getBindingSet() {
    result = this.getAttrs().(AttrsetExpression).getChild()
    or
    result = this.getAttrs().(RecAttrsetExpression).getChild()
  }

  /**
   * Holds if this derivation defines attribute `name`, either via a
   * direct binding `name = …;` or via `inherit name;` /
   * `inherit (expr) name;`.
   */
  predicate hasAttr(string name) {
    exists(this.getDirectBinding(name))
    or
    exists(Inherit inh, Identifier attr |
      inh = this.getBindingSet().getBinding(_) and
      attr = inh.getAttrs().getAttr(_) and
      attr.getValue() = name
    )
    or
    exists(InheritFrom inh, Identifier attr |
      inh = this.getBindingSet().getBinding(_) and
      attr = inh.getAttrs().getAttr(_) and
      attr.getValue() = name
    )
  }

  /**
   * Gets the direct `name = …;` binding for `name` at the top level of
   * this derivation, if any. Excludes `inherit` clauses — use
   * `hasAttr` if presence-via-inherit is sufficient.
   */
  Binding getDirectBinding(string name) {
    result = this.getBindingSet().getBinding(_) and
    not exists(result.getAttrpath().getAttr(1)) and
    result.getAttrpath().getAttr(0).(Identifier).getValue() = name
  }

  /**
   * Gets some direct top-level binding of this derivation. Excludes
   * `inherit` clauses and dotted attrpath bindings
   * (`meta.description = …;` is excluded; `meta = { … };` is included).
   */
  Binding getADirectBinding() {
    result = this.getBindingSet().getBinding(_) and
    not exists(result.getAttrpath().getAttr(1))
  }

  /**
   * Gets the `i`-th top-level attribute name in source order. Counts
   * direct bindings only — `inherit name;` and dotted-attrpath
   * bindings are not numbered. Used by `AttributeOrdering` to compare
   * actual order against the canonical order.
   */
  string getNthAttrName(int i) {
    exists(Binding b |
      b = this.getBindingSet().getBinding(i) and
      not exists(b.getAttrpath().getAttr(1)) and
      result = b.getAttrpath().getAttr(0).(Identifier).getValue()
    )
  }
}

/**
 * Peels an argument expression down to the underlying attrset literal,
 * following parens, the `finalAttrs:` callback shape, and `let … in …`
 * wrappers. Used internally by `DerivationCall.getAttrs`.
 *
 * Returns no result if the chain doesn't bottom out at a literal
 * attrset (e.g. the argument is a function call result, a variable
 * reference, or a with-expression body).
 */
private Expr peelToAttrset(Expr e) {
  e instanceof AttrsetExpression and result = e
  or
  e instanceof RecAttrsetExpression and result = e
  or
  result = peelToAttrset(e.(ParenthesizedExpression).getExpression())
  or
  result = peelToAttrset(e.(FunctionExpression).getBody())
  or
  result = peelToAttrset(e.(LetExpression).getBody())
}
