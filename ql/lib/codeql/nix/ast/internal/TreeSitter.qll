/**
 * CodeQL library for NIX
 * Automatically generated from the tree-sitter grammar; do not edit
 */

import codeql.Locations as L

module NIX {
  /** The base class for all AST nodes */
  class AstNode extends @nix_ast_node {
    /** Gets a string representation of this element. */
    string toString() { result = this.getAPrimaryQlClass() }

    /** Gets the location of this element. */
    final L::Location getLocation() { nix_ast_node_location(this, result) }

    /** Gets the parent of this element. */
    final AstNode getParent() { nix_ast_node_parent(this, result, _) }

    /** Gets the index of this node among the children of its parent. */
    final int getParentIndex() { nix_ast_node_parent(this, _, result) }

    /** Gets a field or child node of this node. */
    AstNode getAFieldOrChild() { none() }

    /** Gets the name of the primary QL class for this element. */
    string getAPrimaryQlClass() { result = "???" }

    /** Gets a comma-separated list of the names of the primary CodeQL classes to which this element belongs. */
    string getPrimaryQlClasses() { result = concat(this.getAPrimaryQlClass(), ",") }
  }

  /** A token. */
  class Token extends @nix_token, AstNode {
    /** Gets the value of this token. */
    final string getValue() { nix_tokeninfo(this, _, result) }

    /** Gets a string representation of this element. */
    final override string toString() { result = this.getValue() }

    /** Gets the name of the primary QL class for this element. */
    override string getAPrimaryQlClass() { result = "Token" }
  }

  /** A reserved word. */
  class ReservedWord extends @nix_reserved_word, Token {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "ReservedWord" }
  }

  class UnderscoreExpression extends @nix_underscore_expression, AstNode { }

  /** A class representing `apply_expression` nodes. */
  class ApplyExpression extends @nix_apply_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "ApplyExpression" }

    /** Gets the node corresponding to the field `argument`. */
    final AstNode getArgument() { nix_apply_expression_def(this, result, _) }

    /** Gets the node corresponding to the field `function`. */
    final AstNode getFunction() { nix_apply_expression_def(this, _, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      nix_apply_expression_def(this, result, _) or nix_apply_expression_def(this, _, result)
    }
  }

  /** A class representing `assert_expression` nodes. */
  class AssertExpression extends @nix_assert_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "AssertExpression" }

    /** Gets the node corresponding to the field `body`. */
    final AstNode getBody() { nix_assert_expression_def(this, result, _) }

    /** Gets the node corresponding to the field `condition`. */
    final UnderscoreExpression getCondition() { nix_assert_expression_def(this, _, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      nix_assert_expression_def(this, result, _) or nix_assert_expression_def(this, _, result)
    }
  }

  /** A class representing `attrpath` nodes. */
  class Attrpath extends @nix_attrpath, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "Attrpath" }

    /** Gets the node corresponding to the field `attr`. */
    final AstNode getAttr(int i) { nix_attrpath_attr(this, i, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { nix_attrpath_attr(this, _, result) }
  }

  /** A class representing `attrset_expression` nodes. */
  class AttrsetExpression extends @nix_attrset_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "AttrsetExpression" }

    /** Gets the child of this node. */
    final BindingSet getChild() { nix_attrset_expression_child(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { nix_attrset_expression_child(this, result) }
  }

  /** A class representing `binary_expression` nodes. */
  class BinaryExpression extends @nix_binary_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "BinaryExpression" }

    /** Gets the node corresponding to the field `left`. */
    final AstNode getLeft() { nix_binary_expression_def(this, result, _, _) }

    /** Gets the node corresponding to the field `operator`. */
    final string getOperator() {
      exists(int value | nix_binary_expression_def(this, _, value, _) |
        result = "!=" and value = 0
        or
        result = "&&" and value = 1
        or
        result = "*" and value = 2
        or
        result = "+" and value = 3
        or
        result = "++" and value = 4
        or
        result = "-" and value = 5
        or
        result = "->" and value = 6
        or
        result = "/" and value = 7
        or
        result = "//" and value = 8
        or
        result = "<" and value = 9
        or
        result = "<=" and value = 10
        or
        result = "==" and value = 11
        or
        result = ">" and value = 12
        or
        result = ">=" and value = 13
        or
        result = "||" and value = 14
      )
    }

    /** Gets the node corresponding to the field `right`. */
    final AstNode getRight() { nix_binary_expression_def(this, _, _, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      nix_binary_expression_def(this, result, _, _) or nix_binary_expression_def(this, _, _, result)
    }
  }

  /** A class representing `binding` nodes. */
  class Binding extends @nix_binding, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "Binding" }

    /** Gets the node corresponding to the field `attrpath`. */
    final Attrpath getAttrpath() { nix_binding_def(this, result, _) }

    /** Gets the node corresponding to the field `expression`. */
    final UnderscoreExpression getExpression() { nix_binding_def(this, _, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      nix_binding_def(this, result, _) or nix_binding_def(this, _, result)
    }
  }

  /** A class representing `binding_set` nodes. */
  class BindingSet extends @nix_binding_set, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "BindingSet" }

    /** Gets the node corresponding to the field `binding`. */
    final AstNode getBinding(int i) { nix_binding_set_binding(this, i, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { nix_binding_set_binding(this, _, result) }
  }

  /** A class representing `comment` tokens. */
  class Comment extends @nix_token_comment, Token {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "Comment" }
  }

  /** A class representing `dollar_escape` tokens. */
  class DollarEscape extends @nix_token_dollar_escape, Token {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "DollarEscape" }
  }

  /** A class representing `ellipses` tokens. */
  class Ellipses extends @nix_token_ellipses, Token {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "Ellipses" }
  }

  /** A class representing `escape_sequence` tokens. */
  class EscapeSequence extends @nix_token_escape_sequence, Token {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "EscapeSequence" }
  }

  /** A class representing `float_expression` tokens. */
  class FloatExpression extends @nix_token_float_expression, Token {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "FloatExpression" }
  }

  /** A class representing `formal` nodes. */
  class Formal extends @nix_formal, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "Formal" }

    /** Gets the node corresponding to the field `default`. */
    final UnderscoreExpression getDefault() { nix_formal_default(this, result) }

    /** Gets the node corresponding to the field `name`. */
    final Identifier getName() { nix_formal_def(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      nix_formal_default(this, result) or nix_formal_def(this, result)
    }
  }

  /** A class representing `formals` nodes. */
  class Formals extends @nix_formals, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "Formals" }

    /** Gets the node corresponding to the field `ellipses`. */
    final Ellipses getEllipses() { nix_formals_ellipses(this, result) }

    /** Gets the node corresponding to the field `formal`. */
    final Formal getFormal(int i) { nix_formals_formal(this, i, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      nix_formals_ellipses(this, result) or nix_formals_formal(this, _, result)
    }
  }

  /** A class representing `function_expression` nodes. */
  class FunctionExpression extends @nix_function_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "FunctionExpression" }

    /** Gets the node corresponding to the field `body`. */
    final AstNode getBody() { nix_function_expression_def(this, result) }

    /** Gets the node corresponding to the field `formals`. */
    final Formals getFormals() { nix_function_expression_formals(this, result) }

    /** Gets the node corresponding to the field `universal`. */
    final Identifier getUniversal() { nix_function_expression_universal(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      nix_function_expression_def(this, result) or
      nix_function_expression_formals(this, result) or
      nix_function_expression_universal(this, result)
    }
  }

  /** A class representing `has_attr_expression` nodes. */
  class HasAttrExpression extends @nix_has_attr_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "HasAttrExpression" }

    /** Gets the node corresponding to the field `attrpath`. */
    final Attrpath getAttrpath() { nix_has_attr_expression_def(this, result, _, _) }

    /** Gets the node corresponding to the field `expression`. */
    final AstNode getExpression() { nix_has_attr_expression_def(this, _, result, _) }

    /** Gets the node corresponding to the field `operator`. */
    final string getOperator() {
      exists(int value | nix_has_attr_expression_def(this, _, _, value) |
        (result = "?" and value = 0)
      )
    }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      nix_has_attr_expression_def(this, result, _, _) or
      nix_has_attr_expression_def(this, _, result, _)
    }
  }

  /** A class representing `hpath_expression` nodes. */
  class HpathExpression extends @nix_hpath_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "HpathExpression" }

    /** Gets the `i`th child of this node. */
    final AstNode getChild(int i) { nix_hpath_expression_child(this, i, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { nix_hpath_expression_child(this, _, result) }
  }

  /** A class representing `identifier` tokens. */
  class Identifier extends @nix_token_identifier, Token {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "Identifier" }
  }

  /** A class representing `if_expression` nodes. */
  class IfExpression extends @nix_if_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "IfExpression" }

    /** Gets the node corresponding to the field `alternative`. */
    final UnderscoreExpression getAlternative() { nix_if_expression_def(this, result, _, _) }

    /** Gets the node corresponding to the field `condition`. */
    final UnderscoreExpression getCondition() { nix_if_expression_def(this, _, result, _) }

    /** Gets the node corresponding to the field `consequence`. */
    final UnderscoreExpression getConsequence() { nix_if_expression_def(this, _, _, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      nix_if_expression_def(this, result, _, _) or
      nix_if_expression_def(this, _, result, _) or
      nix_if_expression_def(this, _, _, result)
    }
  }

  /** A class representing `indented_string_expression` nodes. */
  class IndentedStringExpression extends @nix_indented_string_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "IndentedStringExpression" }

    /** Gets the `i`th child of this node. */
    final AstNode getChild(int i) { nix_indented_string_expression_child(this, i, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      nix_indented_string_expression_child(this, _, result)
    }
  }

  /** A class representing `inherit` nodes. */
  class Inherit extends @nix_inherit, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "Inherit" }

    /** Gets the node corresponding to the field `attrs`. */
    final InheritedAttrs getAttrs() { nix_inherit_def(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { nix_inherit_def(this, result) }
  }

  /** A class representing `inherit_from` nodes. */
  class InheritFrom extends @nix_inherit_from, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "InheritFrom" }

    /** Gets the node corresponding to the field `attrs`. */
    final InheritedAttrs getAttrs() { nix_inherit_from_def(this, result, _) }

    /** Gets the node corresponding to the field `expression`. */
    final UnderscoreExpression getExpression() { nix_inherit_from_def(this, _, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      nix_inherit_from_def(this, result, _) or nix_inherit_from_def(this, _, result)
    }
  }

  /** A class representing `inherited_attrs` nodes. */
  class InheritedAttrs extends @nix_inherited_attrs, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "InheritedAttrs" }

    /** Gets the node corresponding to the field `attr`. */
    final AstNode getAttr(int i) { nix_inherited_attrs_attr(this, i, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { nix_inherited_attrs_attr(this, _, result) }
  }

  /** A class representing `integer_expression` tokens. */
  class IntegerExpression extends @nix_token_integer_expression, Token {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "IntegerExpression" }
  }

  /** A class representing `interpolation` nodes. */
  class Interpolation extends @nix_interpolation, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "Interpolation" }

    /** Gets the node corresponding to the field `expression`. */
    final UnderscoreExpression getExpression() { nix_interpolation_def(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { nix_interpolation_def(this, result) }
  }

  /** A class representing `let_attrset_expression` nodes. */
  class LetAttrsetExpression extends @nix_let_attrset_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "LetAttrsetExpression" }

    /** Gets the child of this node. */
    final BindingSet getChild() { nix_let_attrset_expression_child(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { nix_let_attrset_expression_child(this, result) }
  }

  /** A class representing `let_expression` nodes. */
  class LetExpression extends @nix_let_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "LetExpression" }

    /** Gets the node corresponding to the field `body`. */
    final AstNode getBody() { nix_let_expression_def(this, result) }

    /** Gets the child of this node. */
    final BindingSet getChild() { nix_let_expression_child(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      nix_let_expression_def(this, result) or nix_let_expression_child(this, result)
    }
  }

  /** A class representing `list_expression` nodes. */
  class ListExpression extends @nix_list_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "ListExpression" }

    /** Gets the node corresponding to the field `element`. */
    final AstNode getElement(int i) { nix_list_expression_element(this, i, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { nix_list_expression_element(this, _, result) }
  }

  /** A class representing `parenthesized_expression` nodes. */
  class ParenthesizedExpression extends @nix_parenthesized_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "ParenthesizedExpression" }

    /** Gets the node corresponding to the field `expression`. */
    final UnderscoreExpression getExpression() { nix_parenthesized_expression_def(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { nix_parenthesized_expression_def(this, result) }
  }

  /** A class representing `path_expression` nodes. */
  class PathExpression extends @nix_path_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "PathExpression" }

    /** Gets the `i`th child of this node. */
    final AstNode getChild(int i) { nix_path_expression_child(this, i, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { nix_path_expression_child(this, _, result) }
  }

  /** A class representing `path_fragment` tokens. */
  class PathFragment extends @nix_token_path_fragment, Token {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "PathFragment" }
  }

  /** A class representing `rec_attrset_expression` nodes. */
  class RecAttrsetExpression extends @nix_rec_attrset_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "RecAttrsetExpression" }

    /** Gets the child of this node. */
    final BindingSet getChild() { nix_rec_attrset_expression_child(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { nix_rec_attrset_expression_child(this, result) }
  }

  /** A class representing `select_expression` nodes. */
  class SelectExpression extends @nix_select_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "SelectExpression" }

    /** Gets the node corresponding to the field `attrpath`. */
    final Attrpath getAttrpath() { nix_select_expression_def(this, result, _) }

    /** Gets the node corresponding to the field `default`. */
    final AstNode getDefault() { nix_select_expression_default(this, result) }

    /** Gets the node corresponding to the field `expression`. */
    final AstNode getExpression() { nix_select_expression_def(this, _, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      nix_select_expression_def(this, result, _) or
      nix_select_expression_default(this, result) or
      nix_select_expression_def(this, _, result)
    }
  }

  /** A class representing `source_code` nodes. */
  class SourceCode extends @nix_source_code, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "SourceCode" }

    /** Gets the node corresponding to the field `expression`. */
    final UnderscoreExpression getExpression() { nix_source_code_expression(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { nix_source_code_expression(this, result) }
  }

  /** A class representing `spath_expression` tokens. */
  class SpathExpression extends @nix_token_spath_expression, Token {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "SpathExpression" }
  }

  /** A class representing `string_expression` nodes. */
  class StringExpression extends @nix_string_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "StringExpression" }

    /** Gets the `i`th child of this node. */
    final AstNode getChild(int i) { nix_string_expression_child(this, i, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { nix_string_expression_child(this, _, result) }
  }

  /** A class representing `string_fragment` tokens. */
  class StringFragment extends @nix_token_string_fragment, Token {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "StringFragment" }
  }

  /** A class representing `unary_expression` nodes. */
  class UnaryExpression extends @nix_unary_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "UnaryExpression" }

    /** Gets the node corresponding to the field `argument`. */
    final AstNode getArgument() { nix_unary_expression_def(this, result, _) }

    /** Gets the node corresponding to the field `operator`. */
    final string getOperator() {
      exists(int value | nix_unary_expression_def(this, _, value) |
        result = "!" and value = 0
        or
        result = "-" and value = 1
      )
    }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { nix_unary_expression_def(this, result, _) }
  }

  /** A class representing `uri_expression` tokens. */
  class UriExpression extends @nix_token_uri_expression, Token {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "UriExpression" }
  }

  /** A class representing `variable_expression` nodes. */
  class VariableExpression extends @nix_variable_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "VariableExpression" }

    /** Gets the node corresponding to the field `name`. */
    final Identifier getName() { nix_variable_expression_def(this, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() { nix_variable_expression_def(this, result) }
  }

  /** A class representing `with_expression` nodes. */
  class WithExpression extends @nix_with_expression, AstNode {
    /** Gets the name of the primary QL class for this element. */
    final override string getAPrimaryQlClass() { result = "WithExpression" }

    /** Gets the node corresponding to the field `body`. */
    final AstNode getBody() { nix_with_expression_def(this, result, _) }

    /** Gets the node corresponding to the field `environment`. */
    final UnderscoreExpression getEnvironment() { nix_with_expression_def(this, _, result) }

    /** Gets a field or child node of this node. */
    final override AstNode getAFieldOrChild() {
      nix_with_expression_def(this, result, _) or nix_with_expression_def(this, _, result)
    }
  }
}
