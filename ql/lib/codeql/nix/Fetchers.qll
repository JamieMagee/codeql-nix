/**
 * Recognition of fetcher function calls in Nix: builtins like
 * `builtins.fetchTarball`, plus the conventional nixpkgs `fetchurl`,
 * `fetchgit`, and `fetchFrom*` families.
 */

import codeql.nix.Nix

/**
 * Holds if `name` is the name of a function that fetches content from
 * a remote URL or repository — i.e. a function call whose result is
 * influenced by network state and which therefore should be pinned to
 * a known hash for reproducibility and supply-chain integrity.
 */
predicate isFetcherName(string name) {
  name =
    [
      // Nix builtins
      "fetchTarball", "fetchGit", "fetchurl", "fetchTree", "fetchClosure",
      // nixpkgs convenience fetchers
      "fetchgit", "fetchzip", "fetchpatch", "fetchpatch2", "fetchsvn", "fetchhg",
      "fetchCargoVendor", "fetchYarnDeps", "fetchPypi",
      // host-specific GitHub-style helpers
      "fetchFromGitHub", "fetchFromGitLab", "fetchFromBitbucket",
      "fetchFromSourcehut", "fetchFromGitea", "fetchFromGitiles", "fetchFromRepoOrCz"
    ]
}

/**
 * Holds if `name` is the name of an attribute that pins a fetcher's
 * output to a content hash — making the fetch reproducible and safe
 * from upstream tampering.
 */
predicate isIntegrityAttribute(string name) {
  name = ["hash", "narHash", "sha256", "sha512", "sha1", "md5", "outputHash"]
}

/**
 * Holds if `name` is the name of an attribute that pins a fetcher's
 * source to a specific revision. For git-based fetchers (`fetchgit`,
 * `fetchFromGitHub`, `builtins.fetchGit`, etc.) a pinned `rev` plus a
 * hash is considered safe. For non-git fetchers (`fetchurl`,
 * `fetchTarball`) a `rev` alone is meaningless.
 */
predicate isRevisionAttribute(string name) { name = ["rev", "ref", "tag"] }

/**
 * Holds if `name` is a fetcher that is git-based — i.e. one for which
 * a pinned `rev` is meaningful as an integrity anchor when paired with
 * a hash. Tarball/HTTP fetchers are not in this set.
 */
predicate isGitFetcher(string name) {
  name =
    [
      "fetchGit", "fetchgit", "fetchFromGitHub", "fetchFromGitLab",
      "fetchFromBitbucket", "fetchFromSourcehut", "fetchFromGitea",
      "fetchFromGitiles", "fetchFromRepoOrCz", "fetchhg", "fetchsvn"
    ]
}

/**
 * A call to a fetcher function. Recognises both bare (`fetchTarball …`,
 * typical after `with builtins;` or `with pkgs;`) and dotted
 * (`builtins.fetchTarball …`, `pkgs.fetchurl …`) invocations.
 */
class FetcherCall extends ApplyExpression {
  string name;

  FetcherCall() {
    isFetcherName(name) and
    (
      // Bare identifier: `fetchTarball arg`
      name = this.getFunction().(VariableExpression).getName().getValue()
      or
      // Dotted: `builtins.fetchTarball arg`, `pkgs.fetchurl arg`,
      // `inputs.nixpkgs.legacyPackages.x86_64-linux.fetchFromGitHub arg`.
      // The fetcher name is the LAST component of the attrpath.
      exists(SelectExpression sel, Attrpath ap, int last |
        sel = this.getFunction() and
        ap = sel.getAttrpath() and
        name = ap.getAttr(last).(Identifier).getValue() and
        not exists(ap.getAttr(last + 1))
      )
    )
  }

  /** Gets the function name of this fetcher (e.g. `"fetchTarball"`). */
  string getName() { result = name }
}

/**
 * Holds if `call` is a fetcher invoked with an attribute set argument
 * that lacks any content-integrity binding (`hash`, `sha256`, etc.).
 *
 * For git fetchers, an integrity attribute is required even if a `rev`
 * is set — `rev` alone provides reproducibility but not authenticity
 * (rewritten history can swap content under the same rev).
 *
 * Conservatively suppresses results for attrsets that contain a
 * dynamically-named binding (e.g. `${if cond then "hash" else "sha256"}
 * = …;`), since the static analysis cannot prove the dynamic name does
 * not resolve to an integrity attribute.
 */
predicate isUnpinnedAttrsetFetch(FetcherCall call, Expr attrset) {
  attrset = call.getArgument() and
  (attrset instanceof AttrsetExpression or attrset instanceof RecAttrsetExpression) and
  not exists(string attr | hasTopLevelBinding(attrset, attr) and isIntegrityAttribute(attr)) and
  not hasDynamicTopLevelBinding(attrset)
}

/**
 * Holds if `call` is a fetcher invoked with a bare string argument
 * (e.g. `builtins.fetchTarball "https://example.com/x.tar.gz"`).
 * Bare-string form has no way to specify a hash and is therefore
 * always unpinned. The matched `urlArg` is the offending expression.
 */
predicate isBareStringFetch(FetcherCall call, Expr urlArg) {
  urlArg = call.getArgument() and
  (urlArg instanceof StringExpression or urlArg instanceof IndentedStringExpression)
}
