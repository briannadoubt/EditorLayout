#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")"
xcodegen generate

ruby <<'RUBY'
pbxproj_path = File.expand_path("EditorLayoutDemo.xcodeproj/project.pbxproj", __dir__)
contents = File.read(pbxproj_path)

package_ref = contents.match(
  /(?<id>[A-F0-9]{24}) \/\* (?<comment>XCLocalSwiftPackageReference "\.\.") \*\/ = \{\n\s*isa = XCLocalSwiftPackageReference;\n\s*relativePath = \.\.;\n\s*\};/m
)

raise "Could not find local package reference for ../" unless package_ref

package_line = "\t\t\tpackage = #{package_ref[:id]} /* #{package_ref[:comment]} */;\n"

dependency_signature = "\t\t\tisa = XCSwiftPackageProductDependency;\n\t\t\tproductName = EditorLayout;"
patched_signature = "\t\t\tisa = XCSwiftPackageProductDependency;\n#{package_line}\t\t\tproductName = EditorLayout;"

patched =
  if contents.include?(patched_signature)
    contents
  else
    contents.sub(dependency_signature, patched_signature)
  end

raise "Could not patch EditorLayout package dependency" if patched == contents && !contents.include?(patched_signature)

File.write(pbxproj_path, patched)
RUBY
