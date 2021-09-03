import SwiftFormatRules
import SwiftFormatConfiguration

final class ForbidsImplicitReturnOutsideResultBuilderTests: LintOrFormatRuleTestCase {
  
  // MARK: Test Cases With Result Builder
  
  func testNotDiagnosed_function_withResultBuilder_eliminateReturn() {
    let input =
    """
    @resultBuilder
    struct Builder {
        staitc func buildBlock() -> Int {
            return 0
        }
    }
    
    @Builder
    func someFunc() -> Int {
      0
    }
    """
    performLint(ForbidsImplicitReturnOutsideResultBuilder.self, input: input)
    XCTAssertNotDiagnosed(.forbidsImplicitReturnOutsideResultBuilder)
  }
  
  func testNotDiagnosed_standaloneVariable_withResultBuilder_eliminateReturn() {
    let input =
    """
    @resultBuilder
    struct Builder {
        staitc func buildBlock() -> Int {
            return 0
        }
    }
    
    @Builder
    var someVar: Int {
      0
    }
    """
    performLint(ForbidsImplicitReturnOutsideResultBuilder.self, input: input)
    XCTAssertNotDiagnosed(.forbidsImplicitReturnOutsideResultBuilder)
  }
  
  // MARK: Test Cases With Custom Attribute
  
  func testDiagnosed_function_withCustomAttribute_elminateReturn() {
    let input =
    """
    @Builder
    func someFunc() -> Int {
      0
    }
    """
    performLint(ForbidsImplicitReturnOutsideResultBuilder.self, input: input)
    XCTAssertDiagnosed(.forbidsImplicitReturnOutsideResultBuilder)
  }
  
  func testNotDiagnosed_function_withCustomAttribute_elminateReturn_configuredResultBuilder() {
    let input =
    """
    @Builder
    func someFunc() -> Int {
      0
    }
    """
    var configuration = Configuration()
    configuration.functionBuilders = ["Builder"]
    performLint(ForbidsImplicitReturnOutsideResultBuilder.self,
                configuration: configuration,
                input: input)
    XCTAssertNotDiagnosed(.forbidsImplicitReturnOutsideResultBuilder)
  }
  
  func testDiagnosed_standaloneVariable_withCustomAttribute_elminateReturn() {
    let input =
    """
    @Builder
    var someFunc: Int {
      0
    }
    """
    performLint(ForbidsImplicitReturnOutsideResultBuilder.self, input: input)
    XCTAssertDiagnosed(.forbidsImplicitReturnOutsideResultBuilder)
  }
  
  func testNotDiagnosed_standaloneVariable_withCustomAttribute_elminateReturn_configuredResultBuilder() {
    let input =
    """
    @Builder
    var someFunc: Int {
      0
    }
    """
    var configuration = Configuration()
    configuration.functionBuilders = ["Builder"]
    performLint(ForbidsImplicitReturnOutsideResultBuilder.self,
                configuration: configuration,
                input: input)
    XCTAssertNotDiagnosed(.forbidsImplicitReturnOutsideResultBuilder)
  }
  
  func testDiagnosed_instanceReadonlyVariableMemberOfStruct_withCustomAttribute_eliminateReturn() {
    let input =
    """
    struct Foo {
        @Builder
        var someVar: Int {
          0
        }
    }
    """
    performLint(ForbidsImplicitReturnOutsideResultBuilder.self, input: input)
    XCTAssertDiagnosed(.forbidsImplicitReturnOutsideResultBuilder)
  }
  
  func testNotDiagnosed_instanceReadonlyVariableMemberOfStruct_withCustomAttribute_eliminateReturn_configuredResultBuilder() {
    let input =
    """
    struct Foo {
        @Builder
        var someVar: Int {
          0
        }
    }
    """
    var configuration = Configuration()
    configuration.functionBuilders = ["Builder"]
    performLint(ForbidsImplicitReturnOutsideResultBuilder.self,
                configuration: configuration,
                input: input)
    XCTAssertNotDiagnosed(.forbidsImplicitReturnOutsideResultBuilder)
  }
  
  func testDiagnosed_instanceReadWriterVariableMemberOfStruct_withCustomAttribute_eliminateReturn() {
    let input =
    """
    struct Foo {
        @Builder
        var someVar: Int {
          get { 0 }
          set { }
        }
    }
    """
    performLint(ForbidsImplicitReturnOutsideResultBuilder.self, input: input)
    XCTAssertDiagnosed(.forbidsImplicitReturnOutsideResultBuilder)
  }
  
  func testNotDiagnosed_instanceReadWriterVariableMemberOfStruct_withCustomAttribute_eliminateReturn_configuredResultBuilder() {
    let input =
    """
    struct Foo {
        @Builder
        var someVar: Int {
          get { 0 }
          set { }
        }
    }
    """
    var configuration = Configuration()
    configuration.functionBuilders = ["Builder"]
    performLint(ForbidsImplicitReturnOutsideResultBuilder.self,
                configuration: configuration,
                input: input)
    XCTAssertNotDiagnosed(.forbidsImplicitReturnOutsideResultBuilder)
  }
  
  func testDiagnosed_staticVariableMemberOfStruct_withCustomAttribute_eliminateReturn() {
    let input =
    """
    struct Foo {
        @Builder
        static var someVar: Int {
          0
        }
    }
    """
    performLint(ForbidsImplicitReturnOutsideResultBuilder.self, input: input)
    XCTAssertDiagnosed(.forbidsImplicitReturnOutsideResultBuilder)
  }
  
  func testNotDiagnosed_staticVariableMemberOfStruct_withCustomAttribute_eliminateReturn_configuredResultBuilder() {
    let input =
    """
    struct Foo {
        @Builder
        static var someVar: Int {
          0
        }
    }
    """
    var configuration = Configuration()
    configuration.functionBuilders = ["Builder"]
    performLint(ForbidsImplicitReturnOutsideResultBuilder.self,
                configuration: configuration,
                input: input)
    XCTAssertNotDiagnosed(.forbidsImplicitReturnOutsideResultBuilder)
  }
  
  // MARK: Test Cases Without Result Builder
  
  func testNotDiagnosed_function_withoutResultBuilder_notElminateReturn() {
    let input =
    """
    func someFunc() -> Int {
      return 0
    }
    """
    performLint(ForbidsImplicitReturnOutsideResultBuilder.self, input: input)
    XCTAssertNotDiagnosed(.forbidsImplicitReturnOutsideResultBuilder)
  }
  
  func testNotDiagnosed_functionOfVoidReturnClause_withoutResultBuilder_notEliminateReturn() {
    let input =
    """
    func someFunc() -> Void {
      return ()
    }
    """
    performLint(ForbidsImplicitReturnOutsideResultBuilder.self, input: input)
    XCTAssertNotDiagnosed(.forbidsImplicitReturnOutsideResultBuilder)
  }
  
  func testDiagnosed_standaloneVariable_withoutResultBuilder_eliminateReturn() {
    let input =
    """
    var someVar: Int {
      0
    }
    """
    performLint(ForbidsImplicitReturnOutsideResultBuilder.self, input: input)
    XCTAssertDiagnosed(.forbidsImplicitReturnOutsideResultBuilder)
  }
  
  func testDiagnosed_instanceReadonlyVariableMemberOfStruct_withoutResultBuilder_eliminateReturn() {
    let input =
    """
    struct Foo {
        var someVar: Int {
          0
        }
    }
    """
    performLint(ForbidsImplicitReturnOutsideResultBuilder.self, input: input)
    XCTAssertDiagnosed(.forbidsImplicitReturnOutsideResultBuilder)
  }
  
  func testDiagnosed_instanceReadWriterVariableMemberOfStruct_withoutResultBuilder_eliminateReturn() {
    let input =
    """
    struct Foo {
        var someVar: Int {
          get { 0 }
          set { }
        }
    }
    """
    performLint(ForbidsImplicitReturnOutsideResultBuilder.self, input: input)
    XCTAssertDiagnosed(.forbidsImplicitReturnOutsideResultBuilder)
  }
  
  func testDiagnosed_staticVariableMemberOfStruct_withoutResultBuilder_eliminateReturn() {
    let input =
    """
    struct Foo {
        static var someVar: Int {
          0
        }
    }
    """
    performLint(ForbidsImplicitReturnOutsideResultBuilder.self, input: input)
    XCTAssertDiagnosed(.forbidsImplicitReturnOutsideResultBuilder)
  }
  
}
