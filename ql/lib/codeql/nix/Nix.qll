/**
 * Top-level Nix AST library. Provides convenience aliases for the
 * auto-generated tree-sitter node classes and a few helpers for
 * extracting common values.
 */

import codeql.nix.ast.internal.TreeSitter

/** Any AST node — base class for every element in the Nix tree-sitter CST. */
class AstNode = NIX::AstNode;

/**
 * Any Nix expression. Corresponds to the tree-sitter `_expression`
 * hidden supertype: function application, attribute sets, strings,
 * variables, `if`, `with`, `let`, etc.
 */
class Expr = NIX::UnderscoreExpression;

/** A function application: `f x` or `f { ... }`. */
class ApplyExpression = NIX::ApplyExpression;

/** A `select` expression: `expr.attr`, `expr.attr or default`. */
class SelectExpression = NIX::SelectExpression;

/** A bare variable reference: `x`, `pkgs`, `builtins`, etc. */
class VariableExpression = NIX::VariableExpression;

/** A non-recursive attribute set literal: `{ a = ...; b = ...; }`. */
class AttrsetExpression = NIX::AttrsetExpression;

/** A recursive attribute set literal: `rec { a = ...; b = a; }`. */
class RecAttrsetExpression = NIX::RecAttrsetExpression;

/** An attribute path: the `a.b.c` in `foo.a.b.c = …` or `foo.a.b.c`. */
class Attrpath = NIX::Attrpath;

/** A single `attrpath = expression;` binding inside an attrset or `let`. */
class Binding = NIX::Binding;

/** A `{ ... }` body holding bindings (used in attrsets and `let`-blocks). */
class BindingSet = NIX::BindingSet;

/** A double-quoted string literal: `"…"`. */
class StringExpression = NIX::StringExpression;

/** An indented (two-single-quote) string literal: `'' … ''`. */
class IndentedStringExpression = NIX::IndentedStringExpression;

/** A `${...}` interpolation embedded inside a string. */
class Interpolation = NIX::Interpolation;

/** An identifier token (any unquoted name in source). */
class Identifier = NIX::Identifier;

/** A literal fragment of string content (the parts between `${...}` interpolations). */
class StringFragment = NIX::StringFragment;

/** A list literal: `[ a b c ]`. */
class ListExpression = NIX::ListExpression;

/** An `inherit a b c;` binding. */
class Inherit = NIX::Inherit;

/** An `inherit (expr) a b;` binding. */
class InheritFrom = NIX::InheritFrom;

/**
 * Holds if `attrset` is either a plain or `rec` attribute set whose
 * top-level bindings include `bindingSet`.
 */
predicate attrsetBindings(Expr attrset, BindingSet bindingSet) {
  bindingSet = attrset.(AttrsetExpression).getChild()
  or
  bindingSet = attrset.(RecAttrsetExpression).getChild()
}

/**
 * Holds if `attrset` contains a top-level `Binding` whose attrpath is
 * a single identifier matching `name`.
 *
 * Only handles the simple `name = …;` shape, not `name1.name2 = …;`
 * dotted paths or `inherit name;`.
 */
predicate hasTopLevelBinding(Expr attrset, string name) {
  exists(BindingSet bs, Binding b, Attrpath ap |
    attrsetBindings(attrset, bs) and
    b = bs.getBinding(_) and
    ap = b.getAttrpath() and
    name = ap.getAttr(0).(Identifier).getValue() and
    not exists(ap.getAttr(1))
  )
  or
  // `inherit name;` — the binding inherits the value of `name` from the
  // enclosing scope, which counts as the attrset having that attribute.
  exists(BindingSet bs, Inherit inh |
    attrsetBindings(attrset, bs) and
    inh = bs.getBinding(_) and
    name = inh.getAttrs().getAttr(_).(Identifier).getValue()
  )
}

/**
 * Gets the textual content of `s` if it is a string with no
 * interpolations (and therefore a single `StringFragment` child).
 */
string getStringLiteralValue(StringExpression s) {
  result = s.getChild(0).(StringFragment).getValue() and
  not exists(s.getChild(1))
}
