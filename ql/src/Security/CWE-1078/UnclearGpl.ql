/**
 * @name Ambiguous GPL/LGPL alias in meta.license
 * @description Unqualified GNU license aliases such as `lib.licenses.gpl2`
 *              and `with lib.licenses; [ gpl3 ]` are deprecated because they
 *              do not make it clear whether the package is licensed under an
 *              exact version (`Only`) or an “or later” (`Plus`) variant.
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id nix/unclear-gpl
 * @tags quality
 *       maintainability
 */

import codeql.nix.Nix
import codeql.nix.Derivation

predicate isAmbiguousGplName(string name) {
  name = "gpl2"
  or
  name = "gpl3"
  or
  name = "lgpl2"
  or
  name = "lgpl21"
  or
  name = "lgpl3"
}

private predicate isMetaLicenseAttrpath(Attrpath ap) {
  ap.getAttr(0).(Identifier).getValue() = "meta" and
  ap.getAttr(1).(Identifier).getValue() = "license" and
  not exists(ap.getAttr(2))
}

private predicate isLicenseAttrpath(Attrpath ap) {
  ap.getAttr(0).(Identifier).getValue() = "license" and
  not exists(ap.getAttr(1))
}

cached
private predicate isDerivationBindingSet(BindingSet bs) {
  exists(DerivationCall d | bs = d.getBindingSet())
}

cached
private predicate isTopLevelDerivationMetaLicenseBinding(Binding b) {
  isMetaLicenseAttrpath(b.getAttrpath()) and
  exists(BindingSet bs |
    bs = b.getParent() and
    isDerivationBindingSet(bs)
  )
}

cached
private predicate isNestedDerivationMetaLicenseBinding(Binding b) {
  isLicenseAttrpath(b.getAttrpath()) and
  exists(AstNode metaExpr, Binding metaBinding, BindingSet derivationBindings |
    metaExpr = b.getParent().getParent() and
    metaBinding = metaExpr.getParent() and
    derivationBindings = metaBinding.getParent() and
    isDerivationBindingSet(derivationBindings) and
    metaBinding.getAttrpath().getAttr(0).(Identifier).getValue() = "meta" and
    not exists(metaBinding.getAttrpath().getAttr(1)) and
    (
      metaExpr = metaBinding.getExpression().(AttrsetExpression)
      or
      metaExpr = metaBinding.getExpression().(RecAttrsetExpression)
    )
  )
}

cached
private predicate isLibLicensesEnvironment(WithExpression withExpr) {
  exists(SelectExpression sel, Attrpath ap |
    sel = withExpr.getEnvironment() and
    ap = sel.getAttrpath() and
    sel.getExpression().(VariableExpression).getName().getValue() = "lib" and
    ap.getAttr(0).(Identifier).getValue() = "licenses" and
    not exists(ap.getAttr(1))
  )
}

cached
private predicate isAmbiguousLibLicenseSelect(SelectExpression sel, string name) {
  exists(Attrpath ap |
    ap = sel.getAttrpath() and
    sel.getExpression().(VariableExpression).getName().getValue() = "lib" and
    ap.getAttr(0).(Identifier).getValue() = "licenses" and
    name = ap.getAttr(1).(Identifier).getValue() and
    isAmbiguousGplName(name) and
    not exists(ap.getAttr(2))
  )
}

from AstNode node, string name
where
  exists(SelectExpression sel, Binding b |
    node = sel and
    isAmbiguousLibLicenseSelect(sel, name) and
    b = sel.getParent() and
    (
      isTopLevelDerivationMetaLicenseBinding(b)
      or
      isNestedDerivationMetaLicenseBinding(b)
    )
  )
  or
  exists(VariableExpression v, Binding b, WithExpression withExpr |
    node = v and
    name = v.getName().getValue() and
    isAmbiguousGplName(name) and
    isLibLicensesEnvironment(withExpr) and
    (
      withExpr = v.getParent() and
      b = withExpr.getParent()
      or
      exists(ListExpression list |
        list = v.getParent() and
        withExpr = list.getParent() and
        b = withExpr.getParent()
      )
    ) and
    (
      isTopLevelDerivationMetaLicenseBinding(b)
      or
      isNestedDerivationMetaLicenseBinding(b)
    )
  )
select node,
  "`" + name + "` is a deprecated ambiguous GNU license alias. Use `" + name + "Only` or `" + name +
    "Plus` as appropriate."
