//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftFormatCore
import SwiftSyntax

public final class ForbidsImplicitReturnOutsideResultBuilder: SyntaxLintRule {
  
  /*
   Style:
   - readonly variable getter
   - readwrite variable getter
   - function body
   */
  
  private var codeBlockInfos: CodeBlockInfoStack
  
  private var typeDeclLevel: Int
  
  private var definesResultBuilder: Bool
  
  private var resultBuilders: Set<String>
  
  public required init(context: Context) {
    codeBlockInfos = CodeBlockInfoStack()
    typeDeclLevel = 0
    definesResultBuilder = false
    resultBuilders = Set(context.configuration.functionBuilders)
    super.init(context: context)
  }
  
  public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    codeBlockInfos.push(.makeFunction())
    return .visitChildren
  }
  
  public override func visitPost(_ node: FunctionDeclSyntax) {
    guard !codeBlockInfos.isEmpty else {
      return
    }
    
    let info = codeBlockInfos.pop()
    
    if info.isIllformed {
      diagnose(.forbidsImplicitReturnOutsideResultBuilder, on: node)
    }
    
  }
  
  public override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
    codeBlockInfos.withMutableTop { top in
      guard !top.isVariable else {
        return
      }
      
      top = .makeReadwriteVariable()
    }
    
    return .visitChildren
  }
  
  public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    codeBlockInfos.push(.makeVariable())
    return .visitChildren
  }
  
  public override func visitPost(_ node: VariableDeclSyntax) {
    guard !codeBlockInfos.isEmpty else {
      return
    }
    
    let info = codeBlockInfos.pop()
    
    if info.isIllformed {
      diagnose(.forbidsImplicitReturnOutsideResultBuilder, on: node)
    }
    
  }
  
  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    typeDeclLevel += 1
    return .visitChildren
  }
  
  public override func visitPost(_ node: StructDeclSyntax) {
    if definesResultBuilder {
          resultBuilders.insert(node.identifier.text)
    }
    
    typeDeclLevel -= 1
    definesResultBuilder = false
  }
  
  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    typeDeclLevel += 1
    return .visitChildren
  }
  
  public override func visitPost(_ node: ClassDeclSyntax) {
    if definesResultBuilder {
          resultBuilders.insert(node.identifier.text)
    }
    
    typeDeclLevel -= 1
    definesResultBuilder = false
  }
  
  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    typeDeclLevel += 1
    return .visitChildren
  }
  
  public override func visitPost(_ node: EnumDeclSyntax) {
    if definesResultBuilder {
          resultBuilders.insert(node.identifier.text)
    }
    
    typeDeclLevel -= 1
    definesResultBuilder = false
  }
  
  public override func visit(_ node: AttributeListSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }
  
  public override func visitPost(_ node: AttributeListSyntax) {
    if typeDeclLevel > 0 {
      
      var hasResultBuilder = false
      
      for each in node {
        guard let attrSyntax = each.as(CustomAttributeSyntax.self) else {
          continue
        }
        
        let attrName = attrSyntax.attributeName.as(SimpleTypeIdentifierSyntax.self)?.name
        if attrName?.text == "resultBuilder" || attrName?.text == "_functionBuilder" {
          hasResultBuilder = true
          break
        }
      }
      
      definesResultBuilder = hasResultBuilder
      
    }
    
    if !codeBlockInfos.isEmpty {
      if isResultBuilder(node) {
        codeBlockInfos.top.hasResultBuilderAttribute = true
      }
    }
  }
  
  public override func visitPost(_ node: ReturnStmtSyntax) {
    guard !codeBlockInfos.isEmpty else {
      return
    }
    
    codeBlockInfos.top.hasExplicitReturnStatement = true
  }
  
  public override func visitPost(_ node: ReturnClauseSyntax) {
    guard !codeBlockInfos.isEmpty else {
      return
    }
    
    codeBlockInfos.top.hasReturnClause = true
  }
  
  private func isResultBuilder(_ node: AttributeListSyntax) -> Bool {
    for each in node {
      guard let customAttributeSyntax = each.as(CustomAttributeSyntax.self),
        let attributeName = customAttributeSyntax.attributeName.as(SimpleTypeIdentifierSyntax.self)?.name else {
        continue
      }
      
      if resultBuilders.contains(attributeName.text) {
        return true
      }
    }
    
    return false
  }
  
  private func diagnose<SyntaxType: SyntaxProtocol>(node: SyntaxType, info: VariantCodeBlockInfo) {
    guard info.isIllformed else {
      return
    }
    
    diagnose(.forbidsImplicitReturnOutsideResultBuilder, on: node)
  }
  
}

extension Diagnostic.Message {
  public static let forbidsImplicitReturnOutsideResultBuilder = Diagnostic.Message(
    .error,
    "Implicit return can only used inside result builder."
  )
}

private struct CodeBlockInfoStack {
  
  private var storage: [VariantCodeBlockInfo]
  
  @inlinable
  init() {
    storage = Array()
  }
  
  @inlinable
  mutating func push(_ info: VariantCodeBlockInfo) {
    storage.append(info)
  }
  
  @inlinable
  mutating func pop() -> VariantCodeBlockInfo {
    return storage.removeLast()
  }
  
  @inlinable
  var top: VariantCodeBlockInfo {
    get {
      return storage[storage.count-1]
    }
    _modify {
      yield &storage[storage.count-1]
    }
  }
  
  @inlinable
  mutating func withMutableTop<Result>(_ body: (inout VariantCodeBlockInfo) -> Result) -> Result {
    return body(&storage[storage.count-1])
  }
  
  @inlinable
  var isEmpty: Bool {
    return storage.isEmpty
  }
  
}

private enum VariantCodeBlockInfo {
  
  case function(FunctionInfo)
  
  case variable(VariableInfo)
  
  case readwriteVariable(ReadwriteVariableInfo)
  
  @inlinable
  static func makeFunction() -> VariantCodeBlockInfo {
    return .function(FunctionInfo())
  }
  
  @inlinable
  static func makeVariable() -> VariantCodeBlockInfo {
    return .variable(VariableInfo())
  }
  
  @inlinable
  static func makeReadwriteVariable() -> VariantCodeBlockInfo {
    return .readwriteVariable((ReadwriteVariableInfo)())
  }
  
  var isVariable: Bool {
    if case .variable = self {
      return true
    }
    return false
  }
  
  @inlinable
  var hasReturnClause: Bool {
    get {
      switch self {
      case let .function(info):
        return info.hasReturnClause
      case .variable,
           .readwriteVariable:
        preconditionFailure()
      }
    }
    set {
      switch self {
      case var .function(info):
        info.hasReturnClause = newValue
        self = .function(info)
      default:
        preconditionFailure()
      }
    }
  }
  
  @inlinable
  var hasExplicitReturnStatement: Bool {
    get {
      switch self {
      case let .function(info):
        return info.hasExplicitReturnStatement
      case let .variable(info):
        return info.hasExplicitReturnStatement
      case let .readwriteVariable(info):
        return info.hasExplicitReturnStatement
      }
    }
    set {
      switch self {
      case var .function(info):
        info.hasExplicitReturnStatement = newValue
        self = .function(info)
      case var .variable(info):
        info.hasExplicitReturnStatement = newValue
        self = .variable(info)
      case var .readwriteVariable(info):
        info.hasExplicitReturnStatement = newValue
        self = .readwriteVariable(info)
      }
    }
  }
  
  @inlinable
  var hasResultBuilderAttribute: Bool {
    get {
      switch self {
      case let .function(info):
        return info.hasResultBuilderAttribute
      case let .variable(info):
        return info.hasResultBuilderAttribute
      case let .readwriteVariable(info):
        return info.hasResultBuilderAttribute
      }
    }
    set {
      switch self {
      case var .function(info):
        info.hasResultBuilderAttribute = newValue
        self = .function(info)
      case var .variable(info):
        info.hasResultBuilderAttribute = newValue
        self = .variable(info)
      case var .readwriteVariable(info):
        info.hasResultBuilderAttribute = newValue
        self = .readwriteVariable(info)
      }
    }
  }
  
  @inlinable
  var isIllformed: Bool {
    switch self {
    case let .function(info):
      return info.isIllformed
    case let .variable(info):
      return info.isIllformed
    case let .readwriteVariable(info):
      return info.isIllformed
    }
  }
  
}

private struct FunctionInfo {
  
  var hasReturnClause: Bool
  
  var hasExplicitReturnStatement: Bool
  
  var hasResultBuilderAttribute: Bool
  
  @inlinable
  init() {
    self.hasReturnClause = false
    self.hasExplicitReturnStatement = false
    self.hasResultBuilderAttribute = false
  }
  
  @inlinable
  var isIllformed: Bool {
    return !hasResultBuilderAttribute
      && hasReturnClause
      && !hasExplicitReturnStatement
  }
  
}

private struct VariableInfo {
  
  var hasExplicitReturnStatement: Bool
  
  var hasResultBuilderAttribute: Bool
  
  @inlinable
  init() {
    self.hasExplicitReturnStatement = false
    self.hasResultBuilderAttribute = false
  }
  
  @inlinable
  var isIllformed: Bool {
    return !hasResultBuilderAttribute && !hasExplicitReturnStatement
  }
  
}

struct ReadwriteVariableInfo {
  
  var hasExplicitReturnStatement: Bool
  
  var hasResultBuilderAttribute: Bool
  
  @inlinable
  init() {
    self.hasExplicitReturnStatement = false
    self.hasResultBuilderAttribute = false
  }
  
  @inlinable
  var isIllformed: Bool {
    return !hasResultBuilderAttribute && !hasExplicitReturnStatement
  }
  
}
