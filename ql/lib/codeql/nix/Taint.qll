/**
 * Lightweight taint tracking for the Nix expression language.
 *
 * Phase 2 ships a focused taint pass targeted specifically at the
 * shell-injection use case (`ShellInjectionInBuildPhase.ql` and
 * `MissingShellEscape.ql`). It deliberately does NOT implement the
 * full CodeQL `DataFlow::InputSig` shim — that's a Phase 3+ project.
 *
 * What this library models:
 *   - **Sources**: function formals whose name is not in the
 *     conventionally-trusted nixpkgs vocabulary (`stdenv`, `lib`, the
 *     fetchers, the common build tools); the results of
 *     `builtins.fetch*` / `builtins.getEnv` / `import`.
 *   - **Sinks**: `${expr}` interpolations whose enclosing string is
 *     bound to a shell-context attribute (`buildPhase`, `installPhase`,
 *     `postInstall`, `preInstall`, `preBuild`, `postBuild`,
 *     `configurePhase`, `checkPhase`, `preCheck`, `postCheck`,
 *     `preFixup`, `postFixup`, `unpackPhase`, `configureScript`,
 *     `buildCommand`).
 *   - **Sanitizers**: invocations of `lib.escapeShellArg` /
 *     `lib.escapeShellArgs` / bare `escapeShellArg(s)` (best-effort
 *     under `with lib;`).
 *   - **Propagation**: parenthesisation, the `+` operator on strings,
 *     and let-binding def-use chains (via `Scope.qll`'s `resolvesTo`).
 *
 * What this library does NOT model (vs the full shim):
 *   - Cross-file flow (NixOS module options → systemd `ExecStart`).
 *   - Higher-order functions (`map (x: ${x}) [src]`).
 *   - Attrset destructuring caller-supplied values.
 *   - Sound coverage of all builtins. `builtins.toString` is NOT a
 *     sanitizer — on path/int inputs it produces shell-safe values but
 *     on arbitrary strings it is the identity.
 */

import codeql.nix.Nix
import codeql.nix.Fetchers
import codeql.nix.Builtins
import codeql.nix.Scope

/**
 * Holds if `name` is a function-formal name conventionally bound by
 * nixpkgs to a Nix store path or a builder. Such formals are treated
 * as trusted and not sources of taint.
 *
 * This is a heuristic. Adding to this list reduces false positives.
 */
predicate isTrustedFormalName(string name) {
  name =
    [
      // Stdenv and cross-compilation infrastructure
      "stdenv", "stdenvNoCC", "buildPackages", "hostPlatform", "targetPlatform",
      "buildPlatform", "lib", "pkgs", "pkgs_i686", "callPackage", "callPackages",
      // Common derivation builders
      "mkDerivation", "mkShell", "mkShellNoCC", "writeText", "writeScript",
      "writeShellScript", "writeShellScriptBin", "runCommand", "runCommandLocal",
      "runCommandCC", "writers",
      // Fetchers (results are paths; the hash is what matters, not the call site)
      "fetchurl", "fetchgit", "fetchzip", "fetchpatch", "fetchpatch2",
      "fetchFromGitHub", "fetchFromGitLab", "fetchFromBitbucket",
      "fetchFromSourcehut", "fetchFromGitea", "fetchsvn", "fetchhg",
      "fetchCargoVendor", "fetchYarnDeps", "fetchPypi", "fetchTarball",
      "fetchGit", "fetchTree", "fetchClosure",
      // Wrappers, hooks, linkers
      "makeWrapper", "wrapProgram", "makeBinaryWrapper", "substituteAll",
      "autoreconfHook", "autoPatchelfHook", "copyDesktopItems",
      // Common nixpkgs build tooling
      "cmake", "meson", "ninja", "pkg-config", "pkgconf", "gnumake", "make",
      "automake", "autoconf", "libtool", "intltool", "gettext", "perl", "python",
      "qmake", "qt5", "qt6", "wrapQtAppsHook", "wrapGAppsHook",
      // Language toolchains
      "rustc", "cargo", "rustPlatform", "go", "buildGoModule", "buildGoPackage",
      "nodejs", "buildNpmPackage", "python3", "python2", "ruby", "ghc", "java",
      "jdk", "jre", "openjdk", "clang", "gcc", "binutils"
    ]
}

/**
 * Holds if `name` is the name of an attribute that, when used inside
 * `mkDerivation` (or equivalent), is fed to the shell as part of a
 * derivation's build phases.
 */
predicate isShellContextAttribute(string name) {
  name =
    [
      "buildPhase", "preBuild", "postBuild",
      "installPhase", "preInstall", "postInstall",
      "configurePhase", "preConfigure", "postConfigure",
      "checkPhase", "preCheck", "postCheck",
      "fixupPhase", "preFixup", "postFixup",
      "unpackPhase", "preUnpack", "postUnpack",
      "patchPhase", "prePatch", "postPatch",
      "distPhase", "preDist", "postDist",
      "configureScript", "buildCommand"
    ]
}

/**
 * An expression whose value should be treated as untrusted input. The
 * concrete shapes recognised:
 *
 * 1. A `VariableExpression` resolving to a function-formal whose name
 *    is not in `isTrustedFormalName`.
 * 2. A `FetcherCall` (its result includes the URL/content from a
 *    remote, even if pinned — the value crosses a trust boundary).
 * 3. A `builtins.getEnv` call (its result is the host environment).
 * 4. An `import` call whose argument is non-trivial (we treat all
 *    imports as taint sources to be safe; trivial pure-path imports
 *    rarely cause issues).
 */
class Source extends Expr {
  Source() {
    exists(
      VariableExpression v, Scope scope, string name, Identifier defNode, Formal fml
    |
      this = v and
      resolvesTo(v, scope) and
      scope instanceof FunctionExpression and
      scope.definesName(name, defNode) and
      fml = scope.(FunctionExpression).getFormals().getFormal(_) and
      defNode = fml.getName() and
      name = v.getName().getValue() and
      not isTrustedFormalName(name)
    )
    or
    this instanceof FetcherCall
    or
    exists(BuiltinCall c | this = c and c.getName() = "getEnv")
    or
    exists(ApplyExpression imp |
      this = imp and
      imp.getFunction().(VariableExpression).getName().getValue() = "import"
    )
  }
}

/**
 * Holds if `str` is the string expression that becomes the value of
 * `b`'s binding, possibly wrapped in `let-in` bodies or parentheses.
 *
 * Used by `Sink` to find shell-context interpolation sites whose
 * enclosing string isn't directly the binding's RHS — e.g.
 * `buildPhase = let ver = version; in '' ${ver} ''`.
 */
private predicate stringInBinding(Binding b, AstNode str) {
  str = b.getExpression()
  or
  exists(LetExpression letExpr |
    stringInBinding(b, letExpr) and
    str = letExpr.getBody()
  )
  or
  exists(ParenthesizedExpression p |
    stringInBinding(b, p) and
    str = p.getExpression()
  )
}

/**
 * An `${…}` interpolation expression appearing inside a string that
 * is bound to a shell-context attribute, OR a non-string expression
 * bound directly to a shell-context attribute (e.g. the result of
 * `"prefix" + tainted`).
 *
 * The `Sink` instance is the inner expression that carries the
 * potentially-unsafe value.
 */
class Sink extends Expr {
  Sink() {
    // Interpolation inside a string bound (possibly via let / parens) to a phase attr
    exists(Interpolation interp, AstNode str, Binding b, Attrpath ap |
      this = interp.getExpression() and
      (
        interp = str.(StringExpression).getChild(_) or
        interp = str.(IndentedStringExpression).getChild(_)
      ) and
      stringInBinding(b, str) and
      ap = b.getAttrpath() and
      isShellContextAttribute(ap.getAttr(0).(Identifier).getValue()) and
      not exists(ap.getAttr(1))
    )
    or
    // A non-string expression directly bound to a shell-context attribute —
    // catches `buildPhase = "prefix" + tainted` where the binding RHS is
    // a BinaryExpression rather than a string literal.
    exists(Binding b, Attrpath ap |
      this = b.getExpression() and
      ap = b.getAttrpath() and
      isShellContextAttribute(ap.getAttr(0).(Identifier).getValue()) and
      not exists(ap.getAttr(1)) and
      not this instanceof StringExpression and
      not this instanceof IndentedStringExpression and
      not this instanceof LetExpression and
      not this instanceof ParenthesizedExpression
    )
  }
}

/**
 * A call to `lib.escapeShellArg`, `lib.escapeShellArgs`, or a bare
 * `escapeShellArg(s)` invocation (the latter is best-effort and may
 * over-match in the unlikely case of a same-named local binding).
 */
class Sanitizer extends ApplyExpression {
  Sanitizer() {
    exists(string name |
      name = ["escapeShellArg", "escapeShellArgs", "escapeShellArgs'"]
    |
      // Bare: `escapeShellArg arg`
      name = this.getFunction().(VariableExpression).getName().getValue()
      or
      // Dotted: `lib.escapeShellArg arg`, `pkgs.lib.escapeShellArg arg`, etc.
      exists(SelectExpression sel, Attrpath ap, int last |
        sel = this.getFunction() and
        ap = sel.getAttrpath() and
        name = ap.getAttr(last).(Identifier).getValue() and
        not exists(ap.getAttr(last + 1))
      )
    )
  }
}

/**
 * Holds if a value at `predecessor` flows to `successor` in a single
 * step.
 *
 * Modelled steps:
 *   - Parenthesisation: `(e)` carries the value of `e`.
 *   - String concatenation with `+`: both operands flow to the result.
 *   - Let-binding def-use: a binding's RHS flows to every reference
 *     of that name within the let's body or other bindings.
 */
private predicate flowStep(Expr predecessor, Expr successor) {
  predecessor = successor.(ParenthesizedExpression).getExpression()
  or
  exists(BinaryExpression e |
    e.getOperator() = "+" and
    successor = e and
    (predecessor = e.getLeft() or predecessor = e.getRight())
  )
  or
  exists(LetExpression letExpr, Binding b, VariableExpression ref, Attrpath ap |
    b = letExpr.getChild().getBinding(_) and
    ap = b.getAttrpath() and
    not exists(ap.getAttr(1)) and
    ref.getName().getValue() = ap.getAttr(0).(Identifier).getValue() and
    resolvesTo(ref, letExpr) and
    predecessor = b.getExpression() and
    successor = ref
  )
}

/**
 * Holds if a value originating at `src` reaches `sink` via zero or
 * more flow steps that do not pass through a `Sanitizer`.
 *
 * Propagation through a `Sanitizer` is interrupted: once a value is
 * the argument of a sanitizer call, the call's RESULT is considered
 * untainted for downstream analysis.
 */
predicate flowsTo(Source src, Expr sink) {
  src = sink
  or
  exists(Expr mid |
    flowsTo(src, mid) and
    flowStep(mid, sink) and
    not mid instanceof Sanitizer
  )
}

/**
 * Holds if `sink` has a `Sanitizer` somewhere in its backward flow
 * graph, indicating the value was deliberately sanitized before
 * reaching the interpolation point.
 *
 * Used by `MissingShellEscape.ql` to suppress alerts when the user
 * has already applied a defensive escape.
 */
predicate isReachableFromSanitizer(Expr sink) {
  sink instanceof Sanitizer
  or
  exists(Expr predecessor |
    flowStep(predecessor, sink) and
    isReachableFromSanitizer(predecessor)
  )
}
