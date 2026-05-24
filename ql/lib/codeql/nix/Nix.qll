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

/** A parenthesised expression: `(expr)`. */
class ParenthesizedExpression = NIX::ParenthesizedExpression;

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

/** A `let … in body` expression. */
class LetExpression = NIX::LetExpression;

/** A legacy `let { body = …; }` expression (deprecated form). */
class LetAttrsetExpression = NIX::LetAttrsetExpression;

/** A `x: body` or `{ a, b ? … }: body` function expression. */
class FunctionExpression = NIX::FunctionExpression;

/** The `{ a, b ? …, ... }` formals of a `FunctionExpression`. */
class Formals = NIX::Formals;

/** A single `a` or `a ? default` formal parameter. */
class Formal = NIX::Formal;

/** A `with expr; body` expression. */
class WithExpression = NIX::WithExpression;

/**
 * A `<...>`-style search-path lookup (e.g. `<nixpkgs>`).
 *
 * Represented as a token in tree-sitter-nix; this alias surfaces it
 * as a first-class expression class for queries.
 */
class LookupPath = NIX::SpathExpression;

/**
 * A bare (unquoted) URI literal token, e.g. `https://example.com`.
 *
 * Deprecated by Nix RFC 45 in favour of quoted strings. The bare-URI
 * lexer pattern is `[a-zA-Z][a-zA-Z0-9+.-]*:[a-zA-Z0-9%/?:@&=+$,_.!~*'-]+`.
 */
class BareUriLiteral = NIX::UriExpression;

/** A binary operator expression: `a + b`, `a // b`, `a -> b`, etc. */
class BinaryExpression = NIX::BinaryExpression;

/** A `${...}` interpolation, both inside strings and inside attrpaths. */
predicate hasInterpolation(StringExpression s) { s.getChild(_) instanceof Interpolation }

/**
 * Same as `hasInterpolation` but for indented (two-single-quote) strings.
 */
predicate indentedHasInterpolation(IndentedStringExpression s) {
  s.getChild(_) instanceof Interpolation
}

/** Holds if `e` is a `<...>`-style search-path lookup. */
predicate isLookupPath(AstNode e) { e instanceof LookupPath }

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
 * Recognises:
 *   - direct `name = …;` bindings
 *   - `inherit name;` (Inherit), where the binding takes its value from
 *     the enclosing scope
 *   - `inherit (expr) name;` (InheritFrom), where the binding takes its
 *     value from a specific source expression
 *
 * Does not recognise `name1.name2 = …;` dotted paths or `${dynamic} = …;`
 * dynamic attribute names — see `hasDynamicTopLevelBinding`.
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
  // `inherit name;`
  exists(BindingSet bs, Inherit inh |
    attrsetBindings(attrset, bs) and
    inh = bs.getBinding(_) and
    name = inh.getAttrs().getAttr(_).(Identifier).getValue()
  )
  or
  // `inherit (expr) name;`
  exists(BindingSet bs, InheritFrom inh |
    attrsetBindings(attrset, bs) and
    inh = bs.getBinding(_) and
    name = inh.getAttrs().getAttr(_).(Identifier).getValue()
  )
}

/**
 * Holds if `attrset` contains a top-level `Binding` whose attrpath
 * begins with a dynamically-named attribute — either a `${…}`
 * interpolation or a quoted string. Such bindings cannot be classified
 * by name statically; queries that ask "does this attrset have
 * attribute X?" must conservatively assume the answer may be yes.
 */
predicate hasDynamicTopLevelBinding(Expr attrset) {
  exists(BindingSet bs, Binding b, Attrpath ap, AstNode firstAttr |
    attrsetBindings(attrset, bs) and
    b = bs.getBinding(_) and
    ap = b.getAttrpath() and
    firstAttr = ap.getAttr(0) and
    (firstAttr instanceof Interpolation or firstAttr instanceof StringExpression)
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
