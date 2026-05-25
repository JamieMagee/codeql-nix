/**
 * Library tests for `Derivation.qll`: enumerate every derivation
 * recognised in `derivations.nix`. Three sub-tests cover the three
 * key API surfaces: wrapper recognition, `hasAttr`, and attribute
 * ordering.
 */

import codeql.nix.Nix
import codeql.nix.Derivation

query predicate testKinds(DerivationCall d, string kind) { kind = d.getKind() }

query predicate testHasAttr(DerivationCall d, string attr) {
  d.hasAttr(attr) and attr = ["pname", "version", "src", "buildInputs", "format", "meta"]
}

query predicate testOrder(DerivationCall d, int i, string name) {
  name = d.getNthAttrName(i) and i in [0 .. 2]
}
